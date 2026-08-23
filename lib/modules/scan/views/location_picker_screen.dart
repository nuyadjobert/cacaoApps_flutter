import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/services/connectivity_service.dart';
import '../config/supported_area.dart';
import '../controllers/location_picker_controller.dart';

class LocationPickerSheet extends StatefulWidget {
  final LocationPickerController controller;
  final LatLng? initialPosition;

  const LocationPickerSheet({
    super.key,
    required this.controller,
    this.initialPosition,
  });

  static Future<bool> show(
    BuildContext context, {
    required LocationPickerController controller,
    LatLng? initialPosition,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LocationPickerSheet(
        controller: controller,
        initialPosition: initialPosition,
      ),
    );
    return result ?? false;
  }

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  final ConnectivityService _connectivityService = ConnectivityService();
  final StreamController<void> _onlineTileReset = StreamController<void>();

  late final MapController _mapController;
  late final NetworkTileProvider _networkTileProvider;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  late LatLng _currentCenter;
  late bool _isInsideSupportedArea;
  bool _isOffline = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _networkTileProvider = NetworkTileProvider(silenceExceptions: true);

    final candidate = widget.initialPosition ??
        widget.controller.pickedLatLng ??
        SupportedArea.defaultCenter;
    _currentCenter = SupportedArea.contains(candidate)
        ? candidate
        : SupportedArea.defaultCenter;
    _isInsideSupportedArea = SupportedArea.contains(_currentCenter);

    _connectivitySubscription =
        _connectivityService.onConnectivityChanged.listen(_setConnectivity);
    _loadConnectivity();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _onlineTileReset.close();
    _mapController.dispose();
    super.dispose();
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    _currentCenter = camera.center;
    final isInside = SupportedArea.contains(_currentCenter);
    if (isInside != _isInsideSupportedArea) {
      setState(() => _isInsideSupportedArea = isInside);
    }
  }

  void _onConfirm() {
    final confirmed = widget.controller.confirmManualLocation(
      _currentCenter,
      label: 'Manually pinned',
    );
    if (confirmed) Navigator.pop(context, true);
  }

  Future<void> _loadConnectivity() async {
    final hasConnection = await _connectivityService.hasConnection;
    if (!mounted) return;
    _setOffline(!hasConnection);
  }

  void _setConnectivity(List<ConnectivityResult> results) {
    _setOffline(_connectivityService.isOffline(results));
  }

  void _setOffline(bool isOffline) {
    if (!mounted || isOffline == _isOffline) return;
    setState(() => _isOffline = isOffline);
    if (!isOffline) _onlineTileReset.add(null);
  }

  void _zoomBy(double delta) {
    final zoom = (_mapController.camera.zoom + delta)
        .clamp(SupportedArea.minZoom, SupportedArea.maxZoom)
        .toDouble();
    _mapController.move(_currentCenter, zoom);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: screenHeight * 0.85,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.location_on, color: colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pin Your Exact Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Drag the map to move the pin inside the boundary',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.close),
                  color: colorScheme.onSurfaceVariant,
                  tooltip: 'Close location picker',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentCenter,
                    initialZoom: SupportedArea.initialZoom,
                    minZoom: SupportedArea.minZoom,
                    maxZoom: SupportedArea.maxZoom,
                    cameraConstraint: CameraConstraint.containCenter(
                      bounds: SupportedArea.bounds,
                    ),
                    onPositionChanged: _onPositionChanged,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'assets/maps/offline/{z}_{x}_{y}.webp',
                      fallbackUrl: 'assets/maps/offline/transparent.png',
                      tileProvider: AssetTileProvider(),
                      minNativeZoom: SupportedArea.minZoom.toInt(),
                      maxNativeZoom: SupportedArea.maxZoom.toInt(),
                      panBuffer: 1,
                    ),
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.theobrotect.app',
                      tileProvider: _networkTileProvider,
                      reset: _onlineTileReset.stream,
                      minZoom: SupportedArea.minZoom,
                      maxZoom: 19,
                    ),
                    PolygonLayer(
                      polygons: [
                        Polygon(
                          points: SupportedArea.boundary,
                          color: colorScheme.primary.withAlpha(28),
                          borderColor: colorScheme.primary,
                          borderStrokeWidth: 3,
                        ),
                      ],
                    ),
                    if (widget.controller.detectedLatLng case final detected?)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: detected,
                            width: 30,
                            height: 30,
                            child: _GpsLocationMarker(
                              color: colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    SimpleAttributionWidget(
                      source: const Text(
                        'OpenStreetMap contributors • ODbL',
                        style: TextStyle(fontSize: 9),
                      ),
                      backgroundColor: colorScheme.surface.withAlpha(220),
                    ),
                  ],
                ),
                IgnorePointer(
                  child: Transform.translate(
                    offset: const Offset(0, -18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: _isInsideSupportedArea
                                ? colorScheme.primary
                                : colorScheme.error,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.shadow.withAlpha(80),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            Icons.agriculture,
                            color: colorScheme.onPrimary,
                            size: 22,
                          ),
                        ),
                        Container(
                          width: 3,
                          height: 16,
                          color: _isInsideSupportedArea
                              ? colorScheme.primary
                              : colorScheme.error,
                        ),
                        Container(
                          width: 10,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colorScheme.shadow.withAlpha(40),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: _AccuracyBanner(
                    accuracy: widget.controller.accuracy,
                    isOffline: _isOffline,
                    isInsideSupportedArea: _isInsideSupportedArea,
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 30,
                  child: Column(
                    children: [
                      _ZoomButton(
                        icon: Icons.add,
                        onTap: () => _zoomBy(1),
                      ),
                      const SizedBox(height: 4),
                      _ZoomButton(
                        icon: Icons.remove,
                        onTap: () => _zoomBy(-1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withAlpha(15),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isInsideSupportedArea ? _onConfirm : null,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  _isInsideSupportedArea
                      ? 'Confirm This Location'
                      : 'Move Pin Inside Boundary',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccuracyBanner extends StatelessWidget {
  final double? accuracy;
  final bool isOffline;
  final bool isInsideSupportedArea;

  const _AccuracyBanner({
    this.accuracy,
    required this.isOffline,
    required this.isInsideSupportedArea,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasNoGps = accuracy == null;
    final isLow = !hasNoGps && accuracy! > 50;
    final color = !isInsideSupportedArea
        ? colorScheme.error
        : (hasNoGps || isLow)
            ? colorScheme.tertiary
            : colorScheme.primary;
    final icon = !isInsideSupportedArea
        ? Icons.wrong_location
        : hasNoGps
            ? Icons.gps_off
            : isLow
                ? Icons.gps_not_fixed
                : Icons.gps_fixed;
    final networkSuffix = isOffline ? ' • Offline map' : '';
    final message = !isInsideSupportedArea
        ? 'Move the pin inside the supported boundary'
        : hasNoGps
            ? 'No GPS signal — drag the pin to your location$networkSuffix'
            : isLow
                ? 'Low accuracy ±${accuracy!.toStringAsFixed(0)}m — refine the pin$networkSuffix'
                : 'GPS detected ±${accuracy!.toStringAsFixed(0)}m$networkSuffix';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withAlpha(25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GpsLocationMarker extends StatelessWidget {
  final Color color;

  const _GpsLocationMarker({required this.color});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withAlpha(45),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.surface,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ZoomButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton.filledTonal(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      color: colorScheme.onSurface,
      style: IconButton.styleFrom(
        fixedSize: const Size(36, 36),
        minimumSize: const Size(36, 36),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
