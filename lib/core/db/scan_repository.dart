import 'package:sqflite/sqflite.dart';
import './database_helper.dart';

class ScanRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<Map<String, Object?>>> getPendingScans({
    required String userId,
    int limit = 20,
  }) async {
    final database = await _dbHelper.db;
    return database.query(
      'scan_history',
      where: "user_id = ? AND sync_state IN ('pending','error')",
      whereArgs: [userId],
      orderBy: 'scanned_at ASC',
      limit: limit,
    );
  }

  Future<void> markScanSynced({
    required String localId,
    required String backendId,
  }) async {
    final database = await _dbHelper.db;
    final now = DateTime.now().toIso8601String();

    await database.update(
      'scan_history',
      {
        'sync_state': 'synced',
        'backend_id': backendId,
        'last_sync_at': now,
        'updated_at': now,
        'sync_attempts': 0,
        'last_error': null,
      },
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  Future<void> markScanSyncFailed({
    required String localId,
    required String errorMessage,
  }) async {
    final database = await _dbHelper.db;
    final now = DateTime.now().toIso8601String();

    await database.rawUpdate(
      '''
        UPDATE scan_history
        SET sync_state = 'error',
            sync_attempts = COALESCE(sync_attempts, 0) + 1,
            last_sync_at = ?,
            updated_at = ?
        WHERE local_id = ?
      ''',
      [now, now, localId],
    );
  }

  Future<bool> hasPendingScans() async {
    final database = await _dbHelper.db;
    final count = Sqflite.firstIntValue(
      await database.rawQuery('''
        SELECT COUNT(*) FROM scan_history 
        WHERE sync_state IN ('pending', 'error')
      '''),
    );
    return (count ?? 0) > 0;
  }

  Future<List<Map<String, dynamic>>> getHistoryByUserId(String userId) async {
    final database = await _dbHelper.db;
    return database.query(
      'scan_history',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  Future<void> deleteHistoryItem({
    required String localId,
    required String userId,
  }) async {
    final database = await _dbHelper.db;
    await database.delete(
      'scan_history',
      where: 'local_id = ? AND user_id = ?',
      whereArgs: [localId, userId],
    );
  }

  Future<List<Map<String, dynamic>>> getPendingNotifications(
    String userId,
  ) async {
    final database = await _dbHelper.db;

    return await database.query(
      'scan_history',
      columns: [
        'local_id',
        'next_scan_at',
        'notif_local_id',
        'disease_key',
        'severity_key',
        'scanned_at',
        'image_path',
        'confidence',
      ],
      where: '''
      user_id = ?
      AND next_scan_at IS NOT NULL
      AND date(next_scan_at) <= date('now', 'localtime')
      AND notif_local_id IS NULL
    ''',
      whereArgs: [userId],
      orderBy: 'next_scan_at ASC',
    );
  }

  Future<void> markNotificationShown(String localId) async {
    final database = await _dbHelper.db;

    await database.update(
      'scan_history',
      {
        'notif_local_id': 1, 
      },
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }
}
