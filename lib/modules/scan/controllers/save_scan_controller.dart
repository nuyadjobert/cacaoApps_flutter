import 'package:cacao_apps/core/db/user_repository.dart';
import 'package:flutter/material.dart';
import '/core/services/notification_service.dart';

import '../../../core/db/scan_repository.dart';
import '../services/scan_repository.dart';
import 'location_picker_controller.dart';

class SaveScanController extends ChangeNotifier {
  final ScanRepositoryServices _scanRepoServices = ScanRepositoryServices();

  final ScanRepository _scanRepo = ScanRepository();

  late final LocalNotificationService _notificationService =
      LocalNotificationService(_scanRepo);

  final LocationPickerController locationPicker = LocationPickerController();
  final UserRepository userRepository = UserRepository();

  bool _isSaving = false;
  String? _saveError;
  bool _isSaved = false;

  bool get isSaving => _isSaving;
  String? get saveError => _saveError;
  bool get isSaved => _isSaved;

  /// True when GPS is low/offline — UI should show the map picker sheet
  bool get needsManualLocation => locationPicker.needsManualPick;

  Future<void> detectLocation() => locationPicker.detectLocation();

  Future<bool> saveScanRecord({
    required String diseaseKey,
    required String severityKey,
    required double confidence,
    required String? imagePath,
    required int? rescanAfterDays,
    bool smsEnabled = false,
    bool isLoading = false,
  }) async {
    if (_isSaving) return false;

    if (diseaseKey == 'non_cacao') {
      _saveError = "This is not a cacao plant. Saving is disabled.";
      notifyListeners();
      return false;
    }

    if (isLoading) {
      _saveError = "Still loading scan data. Please try again.";
      notifyListeners();
      return false;
    }

    if (locationPicker.needsManualPick) {
      _saveError = "Please pin your exact location on the map before saving.";
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _saveError = null;
    notifyListeners();

    try {
      final u = await userRepository.getCurrentUser();
      if (u == null) {
        _saveError = "No logged-in user found. Please login again.";
        _isSaving = false;
        notifyListeners();
        return false;
      }

      final userId = u.userId;
      final now = DateTime.now();
      final loc = locationPicker.toLocationMap();
      final effectiveRescanDays = rescanAfterDays ?? 1;

      final nextScanAt = now.add(
        Duration(days: effectiveRescanDays),
      );

      final localId = await _scanRepoServices.insertScan(
        userId: userId,
        diseaseKey: diseaseKey,
        severityKey: severityKey,
        confidence: confidence,
        imagePath: imagePath,
        scannedAt: now,
        createdAt: now,
        nextScanAt: nextScanAt,
        locationLat: (loc?['location_lat'] is num)
            ? (loc!['location_lat'] as num).toDouble()
            : null,
        locationLng: (loc?['location_lng'] is num)
            ? (loc!['location_lng'] as num).toDouble()
            : null,
        locationAccuracy: (loc?['location_accuracy'] is num)
            ? (loc!['location_accuracy'] as num).toDouble()
            : null,
        locationLabel: loc?['location_label']?.toString(),
        notifLocalId: null,
        smsEnabled: smsEnabled,
        syncState: 'pending',
        backendId: null,
        syncAttempts: 0,
        lastSyncAt: null,
        lastError: null,
        nextRetryAt: null,
        updatedAt: null,
      );

      await _notificationService.scheduleNotification(
        localId: localId,
        userId: userId,
        diseaseKey: diseaseKey,
        severityKey: severityKey,
        scannedAt: now,
        nextScanAt: nextScanAt,
      );

      _isSaved = true;
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _saveError = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _saveError = null;
    locationPicker.clearError();
    notifyListeners();
  }
}
