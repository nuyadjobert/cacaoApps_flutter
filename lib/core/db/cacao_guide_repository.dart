import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import './database_helper.dart';

class CacaoGuideRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> syncCacaoGuide(List<dynamic> backendJsonPayload) async {
    final database = await _dbHelper.db;
    final batch = database.batch();

    try {
      for (var diseaseMap in backendJsonPayload) {
        final diseaseId = diseaseMap['disease_id'];

        batch.insert(
          'guide_diseases',
          {
            'id': diseaseId,
            'disease_key': diseaseMap['disease_key'],
            'display_name': json.encode(diseaseMap['display_name']),
            'description': json.encode(diseaseMap['description']),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        final severities = diseaseMap['severities'] as List<dynamic>? ?? [];
        for (var severityMap in severities) {
          final severityId = severityMap['severity_id'];

          batch.insert(
            'guide_disease_severities',
            {
              'id': severityId,
              'disease_id': diseaseId,
              'severity_level': severityMap['level'],
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          final monitoringPlan = severityMap['monitoring_plan'];
          if (monitoringPlan != null) {
            batch.insert(
              'guide_monitoring_plans',
              {
                'disease_severity_id': severityId,
                'rescan_after_days': monitoringPlan['rescan_after_days'],
                'preferred_time_hour': monitoringPlan['preferred_time_hour'],
                'message': json.encode(monitoringPlan['message']),
                'checklist': json.encode(monitoringPlan['checklist']),
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }

          final recommendations =
              severityMap['recommendations'] as List<dynamic>? ?? [];
          for (var recMap in recommendations) {
            batch.insert(
              'guide_recommendations',
              {
                'disease_severity_id': severityId,
                'category_key': recMap['category'],
                'content': json.encode(recMap['content']),
                'sort_order': recMap['sort_order'],
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      }
      await batch.commit(noResult: true);
    } catch (e) {
      rethrow;
    }
  }

  Future<int> getDiseaseCount() async {
    final database = await _dbHelper.db;
    final count = Sqflite.firstIntValue(
      await database.rawQuery('SELECT COUNT(*) FROM guide_diseases'),
    );
    return count ?? 0;
  }

  Future<bool> isDatabaseEmpty() async {
    final database = await _dbHelper.db;
    final count = Sqflite.firstIntValue(
        await database.rawQuery('SELECT COUNT(*) FROM guide_diseases'));
    return (count ?? 0) == 0;
  }

  Future<Map<String, dynamic>?> getDisease(String diseaseKey) async {
    final database = await _dbHelper.db;
    final rows = await database.query(
      'guide_diseases',
      where: 'disease_key = ?',
      whereArgs: [diseaseKey],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    final row = rows.first;
    return {
      'id': row['id'],
      'disease_key': row['disease_key'],
      'display_name': json.decode(row['display_name'] as String),
      'description': json.decode(row['description'] as String),
    };
  }

  Future<Map<String, dynamic>?> getMonitoringPlan(
      String diseaseKey, String severityLevel) async {
    final database = await _dbHelper.db;

    final rows = await database.rawQuery('''
      SELECT m.rescan_after_days, m.preferred_time_hour, m.message, m.checklist 
      FROM guide_monitoring_plans m
      INNER JOIN guide_disease_severities s ON m.disease_severity_id = s.id
      INNER JOIN guide_diseases d ON s.disease_id = d.id
      WHERE d.disease_key = ? AND s.severity_level = ?
      LIMIT 1
    ''', [diseaseKey, severityLevel]);

    if (rows.isEmpty) return null;

    final row = rows.first;
    return {
      'rescan_after_days': row['rescan_after_days'],
      'preferred_time_hour': row['preferred_time_hour'],
      'message': json.decode(row['message'] as String),
      'checklist': json.decode(row['checklist'] as String),
    };
  }

  Future<List<Map<String, dynamic>>> getRecommendations(
      String diseaseKey, String severityLevel) async {
    final database = await _dbHelper.db;

    final rows = await database.rawQuery('''
    SELECT r.category_key, r.content, r.sort_order
    FROM guide_recommendations r
    INNER JOIN guide_disease_severities s ON r.disease_severity_id = s.id
    INNER JOIN guide_diseases d ON s.disease_id = d.id
    WHERE d.disease_key = ? AND s.severity_level = ?
    ORDER BY r.sort_order ASC
  ''', [diseaseKey, severityLevel]);

    return rows.map((row) {
      final decoded = json.decode(row['content'] as String);
      return {
        'category_key': row['category_key'],
        'content': decoded,
        'sort_order': row['sort_order'],
      };
    }).toList();
  }

  Future<Map<String, dynamic>?> getGuideForPrediction(
      String mlPrediction) async {
    if (mlPrediction == 'healthy' || mlPrediction == 'non_cacao') {
      return {
        'status': mlPrediction,
        'is_disease': false,
      };
    }

    String diseaseKey = '';
    String severityLevel = '';

    if (mlPrediction.endsWith('_mild')) {
      severityLevel = 'mild';
      diseaseKey = mlPrediction.replaceAll('_mild', '');
    } else if (mlPrediction.endsWith('_moderate')) {
      severityLevel = 'moderate';
      diseaseKey = mlPrediction.replaceAll('_moderate', '');
    } else if (mlPrediction.endsWith('_severe')) {
      severityLevel = 'severe';
      diseaseKey = mlPrediction.replaceAll('_severe', '');
    } else {
      diseaseKey = mlPrediction;
      severityLevel = 'unknown';
    }

    final diseaseInfo = await getDisease(diseaseKey);

    final monitoringPlan = await getMonitoringPlan(diseaseKey, severityLevel);
    final recommendations = await getRecommendations(diseaseKey, severityLevel);

    // 4. Return a bundled map ready for the UI
    return {
      'is_disease': true,
      'ml_prediction': mlPrediction,
      'parsed_disease_key': diseaseKey,
      'parsed_severity': severityLevel,
      'disease_info': diseaseInfo,
      'monitoring_plan': monitoringPlan,
      'recommendations': recommendations,
    };
  }
}
