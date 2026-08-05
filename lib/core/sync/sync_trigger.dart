import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/network/client.dart';
import 'package:cacao_apps/core/db/scan_repository.dart';
import 'package:cacao_apps/modules/scan/services/scan_sync_service.dart';

import 'dart:developer' as developer;
import 'package:rxdart/rxdart.dart';

class SyncTrigger {
  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _retryTimer;
  bool _running = false;
  late final ScanSyncService _scanSync;
  
  // 2. Initialize the Scan Repository
  final ScanRepository _scanRepository = ScanRepository();

  SyncTrigger() {
    // 3. Pass the repository into the sync service instead of the raw D
    _scanSync = ScanSyncService(dio: DioClient.dio, scanRepository: _scanRepository);
  }

  void start() {
    developer.log('🔌 SyncTrigger started', name: 'SyncTrigger');

    _trySync();

    // Listen to changes with a small debounce to avoid flicker
    _sub = Connectivity().onConnectivityChanged
        .where((results) => results.any((r) => r != ConnectivityResult.none))
        .debounceTime(const Duration(seconds: 2)) 
        .listen((_) {
          developer.log(
            '📡 Signal detected, attempting sync...',
            name: 'SyncTrigger',
          );
          _trySync();
        });
    _retryTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => _trySync(),
    );
  }

  Future<void> _trySync() async {
    if (_running) return;
    _running = true;

    try {
      // 4. Ask the repository if there are pending scans
      final hasData = await _scanRepository.hasPendingScans();
      if (!hasData) return;

      // Real-world reachability check
      final ok = await _isServerReachable();
      if (!ok) {
        developer.log(
          '🌐 Server unreachable (True offline)',
          name: 'SyncTrigger',
        );
        return;
      }

      await _scanSync.syncPendingScans();
    } catch (e) {
      developer.log('❌ Sync trigger error', name: 'SyncTrigger', error: e);
    } finally {
      _running = false;
    }
  }

  Future<bool> _isServerReachable() async {
    try {
      // Use a fast HEAD request to check availability
      final res = await DioClient.dio.head('/api/theobrotect/test');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void stop() {
    _retryTimer?.cancel();
    _sub?.cancel();
  }

  // Inside your SyncTrigger class...

  // Change this from private `_trySync()` to public `forceSync()`
  Future<bool> forceSync() async {
    if (_running) return false; // Already running
    _running = true;

    try {
      final hasData = await _scanRepository.hasPendingScans();
      if (!hasData) return false; // Nothing to sync

      final ok = await _isServerReachable();
      if (!ok) {
        developer.log('🌐 Server unreachable', name: 'SyncTrigger');
        return false; // No internet
      }

      await _scanSync.syncPendingScans();
      return true; // Sync successful
    } catch (e) {
      developer.log('❌ Sync trigger error', name: 'SyncTrigger', error: e);
      return false; // Sync failed
    } finally {
      _running = false;
    }
  }
}