import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../db/sync_queue_reporitory.dart';
import '../model/sync_queue.model.dart';

class QueueSyncService {
  final Dio dio;
  final SyncQueueRepository queueRepository;

  QueueSyncService({
    required this.dio,
    required this.queueRepository,
  });

  Future<bool> syncPendingQueue() async {
    try {
      final jobs = await queueRepository.getPendingJobs();
      debugPrint('[QueueSync] Pending jobs=${jobs.length}');

      if (jobs.isEmpty) {
        return true;
      }

      for (final job in jobs) {
        final success = await _processJob(job);

        if (success) {
          await queueRepository.delete(job.id);
          debugPrint(
            '[QueueSync] Synced and removed job=${job.id} '
            'table=${job.tableName} record=${job.recordId}',
          );
        } else {
          await queueRepository.incrementRetry(job.id);
          debugPrint(
            '[QueueSync] Sync failed; retained job=${job.id} '
            'table=${job.tableName} record=${job.recordId}',
          );
        }
      }

      return true;
    } catch (e) {
      debugPrint('[QueueSync] Queue processing error=$e');
      return false;
    }
  }

  Future<bool> _processJob(SyncQueue job) async {
    switch (job.tableName) {
      case "users":
        return _syncUser(job);
      default:
        return false;
    }
  }

  Future<bool> _syncUser(SyncQueue job) async {
    final endpoint = '/api/theobrotect/users/${job.recordId}';
    debugPrint(
      '[QueueSync] PATCH $endpoint job=${job.id} payload=${job.payload}',
    );
    try {
      final response = await dio.patch(
        endpoint,
        data: job.payload,
      );

      final statusCode = response.statusCode;
      final hasAuthHeader =
          response.requestOptions.headers.containsKey('Authorization');
      debugPrint(
        '[QueueSync] Response job=${job.id} status=$statusCode '
        'authenticated=$hasAuthHeader data=${response.data}',
      );
      return statusCode != null && statusCode >= 200 && statusCode < 300;
    } on DioException catch (error) {
      final hasAuthHeader =
          error.requestOptions.headers.containsKey('Authorization');
      debugPrint(
        '[QueueSync] Request failed job=${job.id} '
        'status=${error.response?.statusCode} authenticated=$hasAuthHeader '
        'data=${error.response?.data} error=${error.message}',
      );
      return false;
    }
  }
}
