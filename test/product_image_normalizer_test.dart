import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:wasabi_mobile/services/product_image_normalizer.dart';

void main() {
  test('leaves opaque uniform canvas unchanged for safer food photos', () {
    final source = img.Image(width: 300, height: 200, numChannels: 3);
    img.fill(source, color: img.ColorRgb8(180, 174, 166));
    img.fillRect(
      source,
      x1: 60,
      y1: 75,
      x2: 240,
      y2: 125,
      color: img.ColorRgb8(230, 90, 30),
    );

    final normalized = normalizeProductImageBytes(
      Uint8List.fromList(img.encodeJpg(source, quality: 95)),
    );

    expect(normalized, isNull);
  });

  test('leaves images with inconsistent corners unchanged', () {
    final source = img.Image(width: 120, height: 120, numChannels: 3);
    img.fill(source, color: img.ColorRgb8(40, 80, 120));
    img.fillRect(
      source,
      x1: 0,
      y1: 0,
      x2: 19,
      y2: 19,
      color: img.ColorRgb8(220, 30, 30),
    );
    img.fillRect(
      source,
      x1: 100,
      y1: 0,
      x2: 119,
      y2: 19,
      color: img.ColorRgb8(20, 220, 30),
    );
    img.fillRect(
      source,
      x1: 0,
      y1: 100,
      x2: 19,
      y2: 119,
      color: img.ColorRgb8(20, 30, 220),
    );
    img.fillRect(
      source,
      x1: 100,
      y1: 100,
      x2: 119,
      y2: 119,
      color: img.ColorRgb8(220, 220, 30),
    );

    final normalized = normalizeProductImageBytes(
      Uint8List.fromList(img.encodePng(source)),
    );

    expect(normalized, isNull);
  });

  test('leaves opaque neutral gradient unchanged for safer food photos', () {
    final source = img.Image(width: 300, height: 200, numChannels: 3);
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final shade = 150 + ((x + y) * 85 ~/ 498);
        source.setPixelRgb(x, y, shade + 5, shade, shade - 5);
      }
    }
    img.fillRect(
      source,
      x1: 55,
      y1: 72,
      x2: 245,
      y2: 128,
      color: img.ColorRgb8(235, 95, 20),
    );

    final normalized = normalizeProductImageBytes(
      Uint8List.fromList(img.encodeJpg(source, quality: 95)),
    );

    expect(normalized, isNull);
  });
}
