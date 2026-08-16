import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/network/client.dart';
import '../network/server_reachability_service.dart';
import 'package:cacao_apps/core/db/scan_repository.dart';
import 'package:cacao_apps/core/db/sync_queue_reporitory.dart';
import 'package:cacao_apps/core/services/queue_sync_services.dart';
import 'package:cacao_apps/modules/scan/services/scan_sync_service.dart';

import 'dart:developer' as developer;
import 'package:rxdart/rxdart.dart';

class SyncTrigger {
  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _retryTimer;
  bool _running = false;
  late final ScanSyncService _scanSync;
  late final QueueSyncService _queueSync;
  late final ServerReachabilityService _serverReachability;
  
  final ScanRepository _scanRepository = ScanRepository();
  final SyncQueueRepository _syncQueueRepository = SyncQueueRepository();

  Function()? onSyncComplete;

  SyncTrigger({this.onSyncComplete}) {
    _scanSync = ScanSyncService(dio: DioClient.dio, scanRepository: _scanRepository);
    _queueSync = QueueSyncService(dio: DioClient.dio, queueRepository: _syncQueueRepository);
    _serverReachability = ServerReachabilityService(dio: DioClient.dio);
  }

  void start() {
    developer.log('🔌 SyncTrigger started', name: 'SyncTrigger');

    _trySync();

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
      // Check if server is reachable
      final ok = await _isServerReachable();
      if (!ok) {
        developer.log(
          '🌐 Server unreachable (True offline)',
          name: 'SyncTrigger',
        );
        return;
      }

      // Sync pending scans
      final hasPendingScans = await _scanRepository.hasPendingScans();
      if (hasPendingScans) {
        developer.log('📤 Syncing pending scans...', name: 'SyncTrigger');
        await _scanSync.syncPendingScans();
      }

      // Sync pending queue items (profile updates, etc.)
      final pendingQueue = await _syncQueueRepository.getPendingJobs();
      if (pendingQueue.isNotEmpty) {
        developer.log('📤 Syncing ${pendingQueue.length} pending queue items...', name: 'SyncTrigger');
        await _queueSync.syncPendingQueue();
      }

      // Call the callback after successful sync
      if (onSyncComplete != null && (hasPendingScans || pendingQueue.isNotEmpty)) {
        developer.log('📊 Triggering post-sync callbacks', name: 'SyncTrigger');
        onSyncComplete!();
      }
    } catch (e) {
      developer.log('❌ Sync trigger error', name: 'SyncTrigger', error: e);
    } finally {
      _running = false;
    }
  }

  Future<bool> _isServerReachable() async {
    return _serverReachability.isReachable();
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
      final ok = await _isServerReachable();
      if (!ok) {
        developer.log('🌐 Server unreachable', name: 'SyncTrigger');
        return false; // No internet
      }

      // Sync pending scans
      final hasPendingScans = await _scanRepository.hasPendingScans();
      if (hasPendingScans) {
        await _scanSync.syncPendingScans();
      }

      // Sync pending queue items (profile updates, etc.)
      final pendingQueue = await _syncQueueRepository.getPendingJobs();
      if (pendingQueue.isNotEmpty) {
        await _queueSync.syncPendingQueue();
      }

      // Call the callback after successful sync
      if (onSyncComplete != null && (hasPendingScans || pendingQueue.isNotEmpty)) {
        developer.log('📊 Triggering post-sync callbacks', name: 'SyncTrigger');
        onSyncComplete!();
      }

      return true; // Sync successful
    } catch (e) {
      developer.log('❌ Sync trigger error', name: 'SyncTrigger', error: e);
      return false; // Sync failed
    } finally {
      _running = false;
    }
  }
}
