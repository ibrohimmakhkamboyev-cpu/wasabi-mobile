import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class ProductImageNormalizer {
  const ProductImageNormalizer._();

  static const _cacheLimit = 64;
  static final LinkedHashMap<String, Future<Uint8List?>> _cache =
      LinkedHashMap<String, Future<Uint8List?>>();

  static Future<Uint8List?> load(String url) {
    final cached = _cache.remove(url);
    if (cached != null) {
      _cache[url] = cached;
      return cached;
    }

    final future = _downloadAndNormalize(url);
    _cache[url] = future;
    while (_cache.length > _cacheLimit) {
      _cache.remove(_cache.keys.first);
    }
    return future;
  }

  static Future<Uint8List?> _downloadAndNormalize(String url) async {
    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          response.bodyBytes.isEmpty) {
        return null;
      }
      return compute(normalizeProductImageBytes, response.bodyBytes);
    } catch (_) {
      return null;
    }
  }
}

@visibleForTesting
Uint8List? normalizeProductImageBytes(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null || decoded.width < 8 || decoded.height < 8) {
    return null;
  }

  var source = img.bakeOrientation(decoded);
  const maxDimension = 640;
  if (math.max(source.width, source.height) > maxDimension) {
    if (source.width >= source.height) {
      source = img.copyResize(
        source,
        width: maxDimension,
        interpolation: img.Interpolation.linear,
      );
    } else {
      source = img.copyResize(
        source,
        height: maxDimension,
        interpolation: img.Interpolation.linear,
      );
    }
  }
  source = source.convert(
    format: img.Format.uint8,
    numChannels: 4,
    noAnimation: true,
  );
  source
    ..iccProfile = null
    ..textData = null;

  final background = _estimateBackground(source);
  if (background == null) return null;
  if (!background.transparent) return null;

  final mask = _backgroundMask(source, background);
  final backgroundCount = mask.fold<int>(0, (sum, value) => sum + value);
  final totalPixels = source.width * source.height;
  final foregroundCount = totalPixels - backgroundCount;
  if (backgroundCount < totalPixels * 0.08 ||
      foregroundCount < totalPixels * 0.002) {
    return null;
  }

  final columnCounts = Uint32List(source.width);
  final rowCounts = Uint32List(source.height);
  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      final index = y * source.width + x;
      if (mask[index] == 1) {
        source.setPixelRgba(x, y, 255, 255, 255, 255);
      } else {
        columnCounts[x]++;
        rowCounts[y]++;
      }
    }
  }

  final minColumnPixels = math.max(2, source.height ~/ 150);
  final minRowPixels = math.max(2, source.width ~/ 150);
  final minX = _firstOccupied(columnCounts, minColumnPixels);
  final maxX = _lastOccupied(columnCounts, minColumnPixels);
  final minY = _firstOccupied(rowCounts, minRowPixels);
  final maxY = _lastOccupied(rowCounts, minRowPixels);
  if (minX == null || maxX == null || minY == null || maxY == null) {
    return null;
  }

  final foregroundWidth = maxX - minX + 1;
  final foregroundHeight = maxY - minY + 1;
  final padding = math.max(
    6,
    (math.max(foregroundWidth, foregroundHeight) * 0.10).round(),
  );
  final cropX = math.max(0, minX - padding);
  final cropY = math.max(0, minY - padding);
  final cropRight = math.min(source.width - 1, maxX + padding);
  final cropBottom = math.min(source.height - 1, maxY + padding);
  final cropWidth = cropRight - cropX + 1;
  final cropHeight = cropBottom - cropY + 1;

  if (cropWidth >= source.width * 0.98 && cropHeight >= source.height * 0.98) {
    return img.encodePng(source, level: 6);
  }

  final cropped = img.copyCrop(
    source,
    x: cropX,
    y: cropY,
    width: cropWidth,
    height: cropHeight,
  );
  return img.encodePng(cropped, level: 6);
}

_BackgroundColor? _estimateBackground(img.Image image) {
  final patchSize = math.max(2, math.min(image.width, image.height) ~/ 20);
  final samples = <_CornerSample>[
    _sampleCorner(image, 0, 0, patchSize),
    _sampleCorner(image, image.width - patchSize, 0, patchSize),
    _sampleCorner(image, 0, image.height - patchSize, patchSize),
    _sampleCorner(
      image,
      image.width - patchSize,
      image.height - patchSize,
      patchSize,
    ),
  ];

  final transparentCorners =
      samples.where((sample) => sample.opacity < 0.25).length;
  if (transparentCorners >= 3) {
    return const _BackgroundColor(
      red: 255,
      green: 255,
      blue: 255,
      tolerance: 0,
      transparent: true,
    );
  }

  final opaqueSamples =
      samples.where((sample) => sample.opacity >= 0.25).toList();
  if (opaqueSamples.length < 3) return null;

  final red = _median(opaqueSamples.map((sample) => sample.red));
  final green = _median(opaqueSamples.map((sample) => sample.green));
  final blue = _median(opaqueSamples.map((sample) => sample.blue));
  final neutralSamples = opaqueSamples
      .where(
        (sample) => _chroma(sample.red, sample.green, sample.blue) <= 40,
      )
      .toList();
  if (neutralSamples.length >= 3) {
    final luminances = neutralSamples
        .map(
          (sample) => _luminance(sample.red, sample.green, sample.blue),
        )
        .toList();
    final minLuminance = luminances.reduce(math.min);
    final maxLuminance = luminances.reduce(math.max);
    final sampleChroma = neutralSamples
        .map(
          (sample) => _chroma(sample.red, sample.green, sample.blue),
        )
        .reduce(math.max);
    return _BackgroundColor(
      red: red,
      green: green,
      blue: blue,
      tolerance: 0,
      neutralGradient: true,
      minLuminance: math.max(0, minLuminance - 45),
      maxLuminance: math.min(255, maxLuminance + 45),
      maxChroma: math.max(40, sampleChroma + 18),
    );
  }

  final deltas = opaqueSamples
      .map(
        (sample) => math.max(
          (sample.red - red).abs(),
          math.max(
            (sample.green - green).abs(),
            (sample.blue - blue).abs(),
          ),
        ),
      )
      .toList();
  final matchingCorners = deltas.where((delta) => delta <= 45).length;
  if (matchingCorners < 3) return null;

  final matchingDeltas = deltas.where((delta) => delta <= 45);
  final spread = matchingDeltas.isEmpty ? 0 : matchingDeltas.reduce(math.max);
  return _BackgroundColor(
    red: red,
    green: green,
    blue: blue,
    tolerance: (42 + spread ~/ 2).clamp(42, 60),
  );
}

_CornerSample _sampleCorner(
  img.Image image,
  int startX,
  int startY,
  int size,
) {
  var red = 0.0;
  var green = 0.0;
  var blue = 0.0;
  var alpha = 0.0;
  var opaquePixels = 0;
  final pixelCount = size * size;

  for (var y = startY; y < startY + size; y++) {
    for (var x = startX; x < startX + size; x++) {
      final pixel = image.getPixel(x, y);
      final pixelAlpha = pixel.a.toDouble();
      alpha += pixelAlpha;
      if (pixelAlpha >= 64) {
        red += pixel.r.toDouble();
        green += pixel.g.toDouble();
        blue += pixel.b.toDouble();
        opaquePixels++;
      }
    }
  }

  return _CornerSample(
    red: opaquePixels == 0 ? 255 : (red / opaquePixels).round(),
    green: opaquePixels == 0 ? 255 : (green / opaquePixels).round(),
    blue: opaquePixels == 0 ? 255 : (blue / opaquePixels).round(),
    opacity: alpha / (pixelCount * 255),
  );
}

Uint8List _backgroundMask(img.Image image, _BackgroundColor background) {
  final mask = Uint8List(image.width * image.height);
  final queue = Queue<int>();

  void enqueueIfBackground(int x, int y) {
    final index = y * image.width + x;
    if (mask[index] != 0) return;
    final pixel = image.getPixel(x, y);
    if (!_matchesBackground(pixel, background)) return;
    mask[index] = 1;
    queue.add(index);
  }

  for (var x = 0; x < image.width; x++) {
    enqueueIfBackground(x, 0);
    enqueueIfBackground(x, image.height - 1);
  }
  for (var y = 1; y < image.height - 1; y++) {
    enqueueIfBackground(0, y);
    enqueueIfBackground(image.width - 1, y);
  }

  while (queue.isNotEmpty) {
    final index = queue.removeFirst();
    final x = index % image.width;
    final y = index ~/ image.width;
    if (x > 0) enqueueIfBackground(x - 1, y);
    if (x + 1 < image.width) enqueueIfBackground(x + 1, y);
    if (y > 0) enqueueIfBackground(x, y - 1);
    if (y + 1 < image.height) enqueueIfBackground(x, y + 1);
  }
  return mask;
}

bool _matchesBackground(img.Pixel pixel, _BackgroundColor background) {
  if (pixel.a < 32) return true;
  if (background.transparent) return false;
  final red = pixel.r.toInt();
  final green = pixel.g.toInt();
  final blue = pixel.b.toInt();
  if (background.neutralGradient) {
    final luminance = _luminance(red, green, blue);
    return _chroma(red, green, blue) <= background.maxChroma &&
        luminance >= background.minLuminance &&
        luminance <= background.maxLuminance;
  }
  final redDelta = (red - background.red).abs();
  final greenDelta = (green - background.green).abs();
  final blueDelta = (blue - background.blue).abs();
  return math.max(redDelta, math.max(greenDelta, blueDelta)) <=
      background.tolerance;
}

int _luminance(int red, int green, int blue) =>
    (red * 299 + green * 587 + blue * 114) ~/ 1000;

int _chroma(int red, int green, int blue) {
  final maximum = math.max(red, math.max(green, blue));
  final minimum = math.min(red, math.min(green, blue));
  return maximum - minimum;
}

int _median(Iterable<int> values) {
  final sorted = values.toList()..sort();
  return sorted[sorted.length ~/ 2];
}

int? _firstOccupied(Uint32List counts, int minimum) {
  for (var index = 0; index < counts.length; index++) {
    if (counts[index] >= minimum) return index;
  }
  return null;
}

int? _lastOccupied(Uint32List counts, int minimum) {
  for (var index = counts.length - 1; index >= 0; index--) {
    if (counts[index] >= minimum) return index;
  }
  return null;
}

class _CornerSample {
  const _CornerSample({
    required this.red,
    required this.green,
    required this.blue,
    required this.opacity,
  });

  final int red;
  final int green;
  final int blue;
  final double opacity;
}

class _BackgroundColor {
  const _BackgroundColor({
    required this.red,
    required this.green,
    required this.blue,
    required this.tolerance,
    this.transparent = false,
    this.neutralGradient = false,
    this.minLuminance = 0,
    this.maxLuminance = 255,
    this.maxChroma = 0,
  });

  final int red;
  final int green;
  final int blue;
  final int tolerance;
  final bool transparent;
  final bool neutralGradient;
  final int minLuminance;
  final int maxLuminance;
  final int maxChroma;
}
