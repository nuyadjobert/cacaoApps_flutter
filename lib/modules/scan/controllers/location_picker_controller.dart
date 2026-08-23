import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'package:cacao_apps/core/location/location_service.dart';

import '../config/supported_area.dart';

const double kLowAccuracyThreshold = 50.0;

class LocationPickerController extends ChangeNotifier {
  final LocationService _locationService = LocationService();

  bool _isLoading = true;
  String? _error;

  LatLng? _pickedLatLng;
  LatLng? _detectedLatLng;
  double? _accuracy;
  String? _locationLabel;
  bool _isManuallyPicked = false;
  bool _needsManualPick = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  LatLng? get pickedLatLng => _pickedLatLng;
  LatLng? get detectedLatLng => _detectedLatLng;
  double? get accuracy => _accuracy;
  String? get locationLabel => _locationLabel;
  bool get isManuallyPicked => _isManuallyPicked;
  bool get needsManualPick => _needsManualPick;

  Future<void> detectLocation() async {
    _isLoading = true;
    _error = null;
    _needsManualPick = false;
    notifyListeners();

    try {
      final loc = await _locationService.getLocationSnapshot();

      if (loc == null) {
        _needsManualPick = true;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final lat = (loc['location_lat'] is num)
          ? (loc['location_lat'] as num).toDouble()
          : null;
      final lng = (loc['location_lng'] is num)
          ? (loc['location_lng'] as num).toDouble()
          : null;
      final acc = (loc['location_accuracy'] is num)
          ? (loc['location_accuracy'] as num).toDouble()
          : null;

      if (lat == null || lng == null) {
        _needsManualPick = true;
        _isLoading = false;
        notifyListeners();
        return;
      }

      _pickedLatLng = LatLng(lat, lng);
      _detectedLatLng = _pickedLatLng;
      _accuracy = acc;
      _locationLabel = loc['location_label']?.toString();

      if (!SupportedArea.contains(_pickedLatLng!)) {
        _error = 'Your GPS location is outside the supported area.';
        _needsManualPick = true;
      } else if (acc != null && acc > kLowAccuracyThreshold) {
        _needsManualPick = true;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _needsManualPick = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  bool confirmManualLocation(LatLng latlng, {String? label}) {
    if (!SupportedArea.contains(latlng)) {
      _error = 'Select a location inside the supported boundary.';
      _needsManualPick = true;
      notifyListeners();
      return false;
    }

    _pickedLatLng = latlng;
    _locationLabel = label ?? 'Manually pinned';
    _isManuallyPicked = true;
    _needsManualPick = false;
    _accuracy = null;
    _error = null;
    notifyListeners();
    return true;
  }

  Map<String, dynamic>? toLocationMap() {
    if (_pickedLatLng == null) return null;
    return {
      'location_lat': _pickedLatLng!.latitude,
      'location_lng': _pickedLatLng!.longitude,
      'location_accuracy': _accuracy,
      'location_label': _locationLabel,
    };
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
