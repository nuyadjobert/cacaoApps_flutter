import 'package:sqflite/sqflite.dart';
import 'package:cacao_apps/core/model/user.model.dart';
import './database_helper.dart';

class UserRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> upsertUser(LocalUser user) async {
    final database = await _dbHelper.db;
    await database.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<LocalUser?> getCurrentUser() async {
    final database = await _dbHelper.db;
    final rows = await database.query('users', limit: 1);
    if (rows.isEmpty) return null;
    return LocalUser.fromMap(rows.first);
  }

  Future<void> clearUsers() async {
    final database = await _dbHelper.db;
    await database.delete('users');
  }

  Future<void> updateUser({
    required String userId,
    String? name,
    String? address,
    String? contactNumber,
  }) async {
    final database = await _dbHelper.db;

    final Map<String, Object?> updates = {};

    if (name != null) {
      updates['name'] = name;
    }

    if (address != null) {
      updates['address'] = address;
    }

    if (contactNumber != null) {
      updates['contact_number'] = contactNumber;
    }

    if (updates.isEmpty) return;

    await database.update(
      'users',
      updates,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}
