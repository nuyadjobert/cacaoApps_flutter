import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'db_schemas.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'cacao_app.db');
    return openDatabase(
      path,
      version: 1,
      onConfigure: (Database db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Core Tables
    await db.execute(DbSchemas.createUsersTable);
    await db.execute(DbSchemas.createScanHistoryTable);
    for (String query in DbSchemas.createScanIndexes) {
      await db.execute(query);
    }

    // 2. Guide Tables
    await db.execute(DbSchemas.createGuideDiseasesTable);
    await db.execute(DbSchemas.createGuideSeveritiesTable);
    await db.execute(DbSchemas.createGuideMonitoringPlansTable);
    await db.execute(DbSchemas.createGuideRecommendationsTable);
    await db.execute(DbSchemas.createSyncTable);
    for (String query in DbSchemas.createGuideIndexes) {
      await db.execute(query);
    }
  }
}