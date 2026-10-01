import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:yandex_maps_mapkit_lite/mapkit.dart' as ym;
import 'package:yandex_maps_mapkit_lite/mapkit_factory.dart' as ym_factory;
import 'package:yandex_maps_mapkit_lite/yandex_map.dart';

import '../../config/app_config.dart';
import '../../models/app_models.dart';
import '../../theme/app_theme.dart';
import '../../utils/address_display.dart';
import '../widgets/common.dart';

class _MapPoint {
  const _MapPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({
    super.key,
    this.initialAddress,
    this.returnSelection = false,
  });

  final AddressModel? initialAddress;
  final bool returnSelection;

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final _mapKey = GlobalKey<_MapPreviewState>();
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;
  AddressModel? _selected;
  List<GeocodeResult> _results = [];
  bool _searching = false;
  bool _locating = false;
  bool _resolving = false;
  int _searchRequestId = 0;
  int _pointRequestId = 0;
  String? _lastLocale;

  @override
  void initState() {
    super.initState();
    final state = AppScope.of(context, listen: false);
    _lastLocale = state.locale;
    _selected = widget.initialAddress ??
        state.primaryAddress ??
        _defaultTashkentAddress(state.locale);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshSelectedAddressLocale();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = AppScope.of(context).locale;
    if (_lastLocale == null || _lastLocale == locale) return;
    _lastLocale = locale;
    _refreshSelectedAddressLocale();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchFocus.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final isUz = state.locale == 'uz';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final estimate = state.estimateDelivery(_selected);
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor:
          isDark ? const Color(0xFF090909) : const Color(0xFFF7F8F4),
      body: Stack(
        children: [
          Positioned.fill(
            child: _MapPreview(
              key: _mapKey,
              selected: _selected,
              branch: estimate?.branch,
              onPointSelected: _selectPoint,
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: MediaQuery.paddingOf(context).top + 12,
            child: Column(
              children: [
                Row(
                  children: [
                    _MapCircleButton(
                      icon: Icons.arrow_back_ios_new,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SearchPanel(
                        controller: _search,
                        focusNode: _searchFocus,
                        searching: _searching,
                        locating: _locating,
                        onLocation: _useCurrentLocation,
                        onChanged: _queueSearch,
                        onSubmitted: (_) => _runSearch(),
                        hint: isUz
                            ? 'Ko‘cha yoki joy nomi'
                            : 'Улица или название места',
                      ),
                    ),
                  ],
                ),
                if (_results.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _SearchResults(
                      results: _results,
                      onSelect: _selectResult,
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            top: MediaQuery.paddingOf(context).top + 92,
            child: _ZoomControls(
              onZoomIn: () => _mapKey.currentState?.zoomIn(),
              onZoomOut: () => _mapKey.currentState?.zoomOut(),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.paddingOf(context).bottom + 16,
            child: _AddressActionPanel(
              address: _selected == null
                  ? (isUz ? 'Manzil tanlanmagan' : 'Адрес не выбран')
                  : displayAddressLabel(_selected!.address),
              subtitle: isUz ? 'Yetkazish manzili' : 'Адрес доставки',
              saveLabel: isUz ? 'Manzilni saqlash' : 'Сохранить адрес',
              onSave:
                  _selected == null || _resolving || _locating ? null : _save,
            ),
          ),
        ],
      ),
    );
  }

  void _queueSearch(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      _searchRequestId++;
      setState(() {
        _results = [];
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (query.length >= 2) _runSearch();
    });
  }

  Future<void> _runSearch() async {
    final state = AppScope.of(context, listen: false);
    final query = _search.text.trim();
    if (query.length < 2) return;
    final requestId = ++_searchRequestId;
    setState(() => _searching = true);
    try {
      final results = await state.geocodeAddress(_uzbekistanQuery(query));
      if (!mounted) return;
      if (requestId != _searchRequestId) return;
      setState(() {
        _results = results
            .where((item) => _isInUzbekistan(item.lat, item.lng))
            .fold<List<GeocodeResult>>([], (items, item) {
              final duplicate = items.any(
                (saved) =>
                    (saved.lat - item.lat).abs() < 0.0001 &&
                    (saved.lng - item.lng).abs() < 0.0001,
              );
              if (!duplicate) items.add(item);
              return items;
            })
            .take(6)
            .toList();
      });
    } catch (_) {
      if (!mounted) return;
      if (requestId != _searchRequestId) return;
      setState(() => _results = []);
    } finally {
      if (mounted && requestId == _searchRequestId) {
        setState(() => _searching = false);
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    final state = AppScope.of(context, listen: false);
    setState(() => _locating = true);
    try {
      final current =
          await state.addressFromCurrentLocation(existing: _selected);
      if (!mounted) return;
      if (current == null || !_isInUzbekistan(current.lat, current.lng)) {
        showWasabiMessage(
          context,
          state.locale == 'uz'
              ? 'Joylashuv O‘zbekiston ichida topilmadi'
              : 'Геолокация должна быть внутри Узбекистана',
          isError: true,
        );
        return;
      }
      setState(() {
        _searchRequestId++;
        _pointRequestId++;
        _resolving = false;
        _selected = current.copyWith(isPrimary: !widget.returnSelection);
        _results = [];
      });
    } catch (_) {
      if (!mounted) return;
      showWasabiMessage(
        context,
        state.locale == 'uz'
            ? 'Joylashuvni aniqlab bo‘lmadi. GPS va ruxsatlarni tekshiring.'
            : 'Не удалось определить местоположение. Проверьте GPS и разрешение.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _selectResult(GeocodeResult result) {
    final state = AppScope.of(context, listen: false);
    _searchFocus.unfocus();
    setState(() {
      _searchRequestId++;
      _pointRequestId++;
      _resolving = false;
      _selected = AddressModel(
        id: state.primaryAddress?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        address: result.address,
        lat: result.lat,
        lng: result.lng,
        isPrimary: !widget.returnSelection,
      );
      _search.clear();
      _results = [];
    });
  }

  Future<void> _selectPoint(_MapPoint point) async {
    if (_searchFocus.hasFocus || _results.isNotEmpty || _searching) return;
    if (!_isInUzbekistan(point.latitude, point.longitude)) return;
    final state = AppScope.of(context, listen: false);
    final previous = _selected;
    final requestId = ++_pointRequestId;
    setState(() {
      _resolving = true;
      _selected = AddressModel(
        id: previous?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        address:
            state.locale == 'uz' ? 'Manzil aniqlanmoqda' : 'Адрес определяется',
        lat: point.latitude,
        lng: point.longitude,
        isPrimary: !widget.returnSelection,
      );
      _results = [];
    });
    late final AddressModel resolved;
    try {
      resolved = await state.addressFromPoint(
        point.latitude,
        point.longitude,
        existing: previous,
      );
    } catch (_) {
      if (!mounted || requestId != _pointRequestId) return;
      setState(() {
        _resolving = false;
        _selected = previous;
      });
      showWasabiMessage(
          context,
          state.locale == 'uz'
              ? 'Manzilni aniqlab bo‘lmadi. Qayta urinib ko‘ring.'
              : 'Не удалось определить адрес. Попробуйте ещё раз.',
          isError: true);
      return;
    }
    if (!mounted) return;
    if (requestId != _pointRequestId) return;
    if (!_isInUzbekistan(resolved.lat, resolved.lng)) return;
    setState(() {
      _resolving = false;
      _selected = resolved.copyWith(isPrimary: !widget.returnSelection);
    });
  }

  Future<void> _save() async {
    if (_resolving || _locating) return;
    final selected = _selected;
    if (selected == null) return;
    if (widget.returnSelection) {
      Navigator.pop(context, selected.copyWith(isPrimary: false));
      return;
    }
    final state = AppScope.of(context, listen: false);
    await state.upsertAddress(selected.copyWith(isPrimary: true));
    if (mounted) Navigator.pop(context);
  }

  Future<void> _refreshSelectedAddressLocale() async {
    final selected = _selected;
    if (selected == null) return;
    final state = AppScope.of(context, listen: false);
    final requestId = ++_pointRequestId;
    try {
      final resolved = await state.addressFromPoint(
        selected.lat,
        selected.lng,
        existing: selected,
      );
      if (!mounted || requestId != _pointRequestId) return;
      setState(() {
        _selected = resolved.copyWith(isPrimary: selected.isPrimary);
      });
    } catch (_) {
      // Keep the saved address when a background locale lookup fails.
    }
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
    required this.controller,
    required this.focusNode,
    required this.searching,
    required this.locating,
    required this.onLocation,
    required this.onChanged,
    required this.onSubmitted,
    required this.hint,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool searching;
  final bool locating;
  final VoidCallback onLocation;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xF210140D) : Colors.white,
      elevation: 14,
      shadowColor: isDark ? Colors.black54 : const Color(0x26000000),
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: .55)
                        : WasabiColors.dark.withAlpha(120),
                  ),
                  prefixIconColor:
                      isDark ? Colors.white.withValues(alpha: .72) : null,
                  prefixIcon: searching
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const Icon(Icons.search),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : WasabiColors.dark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton.filled(
              onPressed: locating ? null : onLocation,
              style: IconButton.styleFrom(
                backgroundColor: WasabiColors.primary,
                foregroundColor: Colors.white,
                fixedSize: const Size(48, 48),
              ),
              icon: locating
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.my_location),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapCircleButton extends StatelessWidget {
  const _MapCircleButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xF210140D) : Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: isDark ? Colors.white : WasabiColors.dark,
        style: IconButton.styleFrom(fixedSize: const Size(52, 52)),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.results, required this.onSelect});

  final List<GeocodeResult> results;
  final ValueChanged<GeocodeResult> onSelect;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xF210140D) : Colors.white,
      elevation: 14,
      shadowColor: isDark ? Colors.black54 : const Color(0x22000000),
      borderRadius: BorderRadius.circular(22),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 260),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 6),
          shrinkWrap: true,
          itemCount: results.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: .10)
                : const Color(0x1F000000),
          ),
          itemBuilder: (context, index) {
            final result = results[index];
            return ListTile(
              leading: const Icon(
                Icons.place_outlined,
                color: WasabiColors.primary,
              ),
              title: Text(
                result.address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? Colors.white : WasabiColors.dark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () => onSelect(result),
            );
          },
        ),
      ),
    );
  }
}

class _ZoomControls extends StatelessWidget {
  const _ZoomControls({required this.onZoomIn, required this.onZoomOut});

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xF210140D) : Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onZoomIn,
            icon: Icon(Icons.add, color: isDark ? Colors.white : null),
            style: IconButton.styleFrom(fixedSize: const Size(50, 50)),
          ),
          SizedBox(
            width: 34,
            child: Divider(
              height: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: .14)
                  : const Color(0x1F000000),
            ),
          ),
          IconButton(
            onPressed: onZoomOut,
            icon: Icon(Icons.remove, color: isDark ? Colors.white : null),
            style: IconButton.styleFrom(fixedSize: const Size(50, 50)),
          ),
        ],
      ),
    );
  }
}

class _AddressActionPanel extends StatelessWidget {
  const _AddressActionPanel({
    required this.address,
    required this.subtitle,
    required this.saveLabel,
    required this.onSave,
  });

  final String address;
  final String subtitle;
  final String saveLabel;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xF210140D) : Colors.white,
      elevation: 18,
      shadowColor: isDark ? Colors.black87 : const Color(0x30000000),
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark
                        ? WasabiColors.primary.withValues(alpha: .18)
                        : const Color(0x116B8E23),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: WasabiColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withValues(alpha: .64)
                              : WasabiColors.dark.withAlpha(150),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? Colors.white : WasabiColors.dark,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onSave,
              style: FilledButton.styleFrom(
                backgroundColor: WasabiColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: WasabiColors.primary.withAlpha(100),
                minimumSize: const Size(double.infinity, 58),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                saveLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPreview extends StatefulWidget {
  const _MapPreview({
    super.key,
    required this.selected,
    required this.branch,
    required this.onPointSelected,
  });

  final AddressModel? selected;
  final BranchModel? branch;
  final ValueChanged<_MapPoint> onPointSelected;

  @override
  State<_MapPreview> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<_MapPreview> with WidgetsBindingObserver {
  final MapController _controller = MapController();
  Timer? _cameraDebounce;
  ym.MapWindow? _yandexMapWindow;
  late final _MapTapListener _mapTapListener;
  late final _MapCameraListener _mapCameraListener;
  double _zoom = 15;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _mapTapListener = _MapTapListener(_selectYandexPoint);
    _mapCameraListener = _MapCameraListener((position, reason, finished) {
      _zoom = position.zoom;
      if (!mounted || reason != ym.CameraUpdateReason.Gestures) return;
      _cameraDebounce?.cancel();
      if (!finished) return;
      widget.onPointSelected(_MapPoint(
        latitude: position.target.latitude,
        longitude: position.target.longitude,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final useYandexMap = AppConfig.yandexMapkitApiKey.isNotEmpty;
    final selected = widget.selected;
    final branch = widget.branch;
    final center = latlng.LatLng(
      selected?.lat ?? 41.311081,
      selected?.lng ?? 69.240562,
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        if (useYandexMap)
          YandexMap(onMapCreated: _onYandexMapCreated)
        else
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: center,
              initialZoom: selected == null ? 12 : 15,
              minZoom: 5,
              maxZoom: 18,
              backgroundColor: const Color(0xFFF7F6F2),
              onTap: (_, point) {
                _cameraDebounce?.cancel();
                _moveTo(point);
                widget.onPointSelected(_toMapPoint(point));
              },
              onPositionChanged: (camera, hasGesture) {
                _zoom = camera.zoom;
                if (!hasGesture) return;
                _cameraDebounce?.cancel();
                _cameraDebounce = Timer(const Duration(milliseconds: 350), () {
                  widget.onPointSelected(_toMapPoint(camera.center));
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                retinaMode: RetinaMode.isHighDensity(context),
                userAgentPackageName: 'uz.wasabi.wasabi_mobile',
              ),
              MarkerLayer(
                markers: [
                  if (branch?.lat != null && branch?.lng != null)
                    Marker(
                      point: latlng.LatLng(branch!.lat!, branch.lng!),
                      width: 120,
                      height: 54,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x22000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              branch.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: WasabiColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.storefront,
                            color: WasabiColors.primary,
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        if (!useYandexMap)
          const Positioned(
            right: 8,
            bottom: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(color: Color(0xCCFFFFFF)),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  'OpenStreetMap',
                  style: TextStyle(fontSize: 10, color: Color(0xFF444444)),
                ),
              ),
            ),
          ),
        Center(child: _SelectionMarker()),
      ],
    );
  }

  @override
  void didUpdateWidget(covariant _MapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selected = widget.selected;
    if (selected == null) return;
    if (selected.lat == oldWidget.selected?.lat &&
        selected.lng == oldWidget.selected?.lng) {
      return;
    }
    if (AppConfig.yandexMapkitApiKey.isNotEmpty) {
      _moveYandexMap(ym.Point(latitude: selected.lat, longitude: selected.lng));
    } else {
      _moveTo(latlng.LatLng(selected.lat, selected.lng));
    }
  }

  void _moveTo(latlng.LatLng point, {double? zoom}) {
    _controller.move(point, zoom ?? _zoom);
  }

  void _onYandexMapCreated(ym.MapWindow mapWindow) {
    _yandexMapWindow = mapWindow;
    mapWindow.map.addInputListener(_mapTapListener);
    mapWindow.map.addCameraListener(_mapCameraListener);
    ym_factory.mapkit.onStart();
    final selected = widget.selected;
    _moveYandexMap(
      ym.Point(
        latitude: selected?.lat ?? 41.311081,
        longitude: selected?.lng ?? 69.240562,
      ),
      zoom: selected == null ? 12 : 15,
      animated: false,
    );
  }

  void _moveYandexMap(
    ym.Point point, {
    double? zoom,
    bool animated = true,
  }) {
    final map = _yandexMapWindow?.map;
    if (map == null) return;
    _zoom = (zoom ?? _zoom).clamp(5, 18).toDouble();
    final current = map.cameraPosition;
    if (current.target == point && current.zoom == _zoom) return;
    map.move(
      ym.CameraPosition(
        point,
        zoom: _zoom,
        azimuth: current.azimuth,
        tilt: current.tilt,
      ),
      animation: ym.Animation(
        type: ym.AnimationType.Smooth,
        duration: animated ? 0.25 : 0,
      ),
    );
  }

  void _selectYandexPoint(ym.Point point) {
    _moveYandexMap(point);
    widget.onPointSelected(
      _MapPoint(latitude: point.latitude, longitude: point.longitude),
    );
  }

  Future<void> zoomIn() async {
    if (AppConfig.yandexMapkitApiKey.isNotEmpty && _yandexMapWindow == null) {
      return;
    }
    _zoom = (_zoom + 1).clamp(5, 18).toDouble();
    final yandexPosition = _yandexMapWindow?.map.cameraPosition;
    if (yandexPosition != null) {
      _moveYandexMap(yandexPosition.target, zoom: _zoom);
      return;
    }
    _controller.move(_controller.camera.center, _zoom);
  }

  Future<void> zoomOut() async {
    if (AppConfig.yandexMapkitApiKey.isNotEmpty && _yandexMapWindow == null) {
      return;
    }
    _zoom = (_zoom - 1).clamp(5, 18).toDouble();
    final yandexPosition = _yandexMapWindow?.map.cameraPosition;
    if (yandexPosition != null) {
      _moveYandexMap(yandexPosition.target, zoom: _zoom);
      return;
    }
    _controller.move(_controller.camera.center, _zoom);
  }

  _MapPoint _toMapPoint(latlng.LatLng point) {
    return _MapPoint(latitude: point.latitude, longitude: point.longitude);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_yandexMapWindow == null) return;
    if (state == AppLifecycleState.resumed) {
      ym_factory.mapkit.onStart();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      ym_factory.mapkit.onStop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraDebounce?.cancel();
    _yandexMapWindow?.map.removeInputListener(_mapTapListener);
    _yandexMapWindow?.map.removeCameraListener(_mapCameraListener);
    if (_yandexMapWindow != null) ym_factory.mapkit.onStop();
    _controller.dispose();
    super.dispose();
  }
}

class _MapCameraListener implements ym.MapCameraListener {
  const _MapCameraListener(this.onChanged);
  final void Function(ym.CameraPosition, ym.CameraUpdateReason, bool) onChanged;

  @override
  void onCameraPositionChanged(ym.Map map, ym.CameraPosition position,
          ym.CameraUpdateReason reason, bool finished) =>
      onChanged(position, reason, finished);
}

class _MapTapListener implements ym.MapInputListener {
  const _MapTapListener(this.onPointSelected);

  final ValueChanged<ym.Point> onPointSelected;

  @override
  void onMapLongTap(ym.Map map, ym.Point point) => onPointSelected(point);

  @override
  void onMapTap(ym.Map map, ym.Point point) => onPointSelected(point);
}

class _SelectionMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Transform.translate(
        offset: const Offset(0, -18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: WasabiColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -6),
              child: const Icon(
                Icons.arrow_drop_down,
                color: WasabiColors.primary,
                size: 38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

AddressModel _defaultTashkentAddress(String locale) {
  return AddressModel(
    id: 'preview-tashkent',
    address: locale == 'uz' ? 'Toshkent' : 'Ташкент',
    lat: 41.311081,
    lng: 69.240562,
    isPrimary: true,
  );
}

bool _isInUzbekistan(double lat, double lng) {
  return lat >= 37.0 && lat <= 46.0 && lng >= 55.0 && lng <= 74.5;
}

String _uzbekistanQuery(String raw) {
  final query = raw.trim();
  final lower = query.toLowerCase();
  final hasCountry = lower.contains('uzbek') ||
      lower.contains('o‘zbekiston') ||
      lower.contains('узбекистан');
  if (hasCountry) return query;
  final hasCity = lower.contains('toshkent') ||
      lower.contains('ташкент') ||
      lower.contains('samarkand') ||
      lower.contains('samarqand') ||
      lower.contains('самарканд') ||
      lower.contains('buxoro') ||
      lower.contains('бухара') ||
      lower.contains('andijon') ||
      lower.contains('андижан') ||
      lower.contains('namangan') ||
      lower.contains('наманган') ||
      lower.contains('farg') ||
      lower.contains('ферган') ||
      lower.contains('qarshi') ||
      lower.contains('карши') ||
      lower.contains('nukus') ||
      lower.contains('нукус');
  return hasCity ? '$query, Uzbekistan' : '$query, Toshkent, Uzbekistan';
}
