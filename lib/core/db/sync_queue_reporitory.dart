import 'dart:convert';
import '../model/sync_queue.model.dart';
import 'database_helper.dart';

class SyncQueueRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> add({
    required String tableName,
    required String recordId,
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    final db = await _dbHelper.db;

    final existing = await db.query(
      'sync_queue',
      where: 'table_name = ? AND record_id = ? AND action = ? AND status = ?',
      whereArgs: [tableName, recordId, action, 0],
      limit: 1,
    );

    final data = {
      'table_name': tableName,
      'record_id': recordId,
      'action': action,
      'payload': jsonEncode(payload),
      'status': 0,
      'retry_count': 0,
      'created_at': DateTime.now().toIso8601String(),
    };

    if (existing.isNotEmpty) {
      await db.update(
        'sync_queue',
        data,
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      await db.insert('sync_queue', data);
    }
  }

  Future<List<SyncQueue>> getPendingJobs() async {
    final db = await _dbHelper.db;

    final rows = await db.query(
      'sync_queue',
      where: 'status = ?',
      whereArgs: [0],
      orderBy: 'created_at ASC',
    );

    return rows.map((e) => SyncQueue.fromMap(e)).toList();
  }

  Future<void> delete(int id) async {
    final db = await _dbHelper.db;

    await db.delete(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> incrementRetry(int id) async {
    final db = await _dbHelper.db;

    await db.rawUpdate(
      '''
      UPDATE sync_queue
      SET retry_count = retry_count + 1
      WHERE id = ?
      ''',
      [id],
    );
  }
}
