class DbSchemas {
  static const String createUsersTable = '''
    CREATE TABLE IF NOT EXISTS users (
      user_id TEXT PRIMARY KEY,
      email TEXT NOT NULL,
      name TEXT,
      address TEXT,
      contact_number TEXT,
      created_at TEXT NOT NULL
    );
  ''';

  static const String createScanHistoryTable = '''
    CREATE TABLE IF NOT EXISTS scan_history (
      local_id TEXT PRIMARY KEY,                 
      backend_id TEXT,                           
      user_id TEXT NOT NULL,
      scanned_at TEXT NOT NULL,
      image_path TEXT,
      disease_key TEXT NOT NULL,
      severity_key TEXT NOT NULL,
      confidence REAL NOT NULL,
      location_lat REAL,
      location_lng REAL,
      location_accuracy REAL,
      location_label TEXT,
      next_scan_at TEXT,
      notif_local_id INTEGER,
      sms_enabled INTEGER DEFAULT 0,
      sync_state TEXT NOT NULL DEFAULT 'pending',
      sync_attempts INTEGER NOT NULL DEFAULT 0,
      last_sync_at TEXT,
      last_error TEXT,
      next_retry_at TEXT,
      idempotency_key TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT,
      FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
    );
  ''';

  static const List<String> createScanIndexes = [
    'CREATE INDEX IF NOT EXISTS idx_scan_user ON scan_history(user_id);',
    'CREATE INDEX IF NOT EXISTS idx_scan_sync ON scan_history(sync_state, next_retry_at);',
    'CREATE INDEX IF NOT EXISTS idx_scan_scanned_at ON scan_history(scanned_at);',
    'CREATE INDEX IF NOT EXISTS idx_scan_backend ON scan_history(backend_id);',
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_scan_idempotency_key ON scan_history(idempotency_key);',
  ];

  static const String createGuideDiseasesTable = '''
    CREATE TABLE IF NOT EXISTS guide_diseases (
      id INTEGER PRIMARY KEY,
      disease_key TEXT UNIQUE NOT NULL,
      display_name TEXT NOT NULL,
      description TEXT NOT NULL,
      updated_at TEXT
    );
  ''';

  static const String createGuideSeveritiesTable = '''
    CREATE TABLE IF NOT EXISTS guide_disease_severities (
      id INTEGER PRIMARY KEY,
      disease_id INTEGER NOT NULL,
      severity_level TEXT NOT NULL,
      updated_at TEXT,
      FOREIGN KEY(disease_id) REFERENCES guide_diseases(id) ON DELETE CASCADE,
      UNIQUE(disease_id, severity_level)
    );
  ''';

  static const String createGuideMonitoringPlansTable = '''
    CREATE TABLE IF NOT EXISTS guide_monitoring_plans (
      id INTEGER PRIMARY KEY,
      disease_severity_id INTEGER UNIQUE NOT NULL,
      rescan_after_days INTEGER NOT NULL,
      preferred_time_hour INTEGER,
      message TEXT NOT NULL,
      checklist TEXT NOT NULL,
      FOREIGN KEY(disease_severity_id) REFERENCES guide_disease_severities(id) ON DELETE CASCADE
    );
  ''';

  static const String createGuideRecommendationsTable = '''
    CREATE TABLE IF NOT EXISTS guide_recommendations (
      id INTEGER PRIMARY KEY,
      disease_severity_id INTEGER NOT NULL,
      category_key TEXT NOT NULL,
      content TEXT NOT NULL,
      sort_order INTEGER DEFAULT 0,
      FOREIGN KEY(disease_severity_id) REFERENCES guide_disease_severities(id) ON DELETE CASCADE
    );
  ''';

  static const List<String> createGuideIndexes = [
    'CREATE INDEX IF NOT EXISTS idx_guide_disease_key ON guide_diseases(disease_key);',
    'CREATE INDEX IF NOT EXISTS idx_guide_severity_disease ON guide_disease_severities(disease_id);',
    'CREATE INDEX IF NOT EXISTS idx_guide_rec_severity ON guide_recommendations(disease_severity_id);',
  ];

  static const String createSyncTable = '''
    CREATE TABLE sync_queue (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      table_name TEXT NOT NULL,
      record_id TEXT NOT NULL,
      action TEXT NOT NULL,
      payload TEXT NOT NULL,
      status INTEGER DEFAULT 0,
      retry_count INTEGER DEFAULT 0,
      created_at TEXT NOT NULL
      );''';
}
