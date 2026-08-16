import 'package:dio/dio.dart';
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

      if (jobs.isEmpty) {
        return true;
      }

      for (final job in jobs) {
        final success = await _processJob(job);

        if (success) {
          await queueRepository.delete(job.id);
        } else {
          await queueRepository.incrementRetry(job.id);
        }
      }
      return true;
    } catch (e) {
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
    try {
      final response = await dio.patch(
        endpoint,
        data: job.payload,
      );

      final statusCode = response.statusCode;
          response.requestOptions.headers.containsKey('Authorization');
      return statusCode != null && statusCode >= 200 && statusCode < 300;
    } on DioException catch (error) {

          error.requestOptions.headers.containsKey('Authorization');

      return false;
    }
  }
}
