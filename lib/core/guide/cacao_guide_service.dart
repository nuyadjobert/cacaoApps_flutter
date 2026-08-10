import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class CacaoGuideService {
  static final CacaoGuideService _instance = CacaoGuideService._internal();
  factory CacaoGuideService() => _instance;
  CacaoGuideService._internal();

  Map<String, dynamic>? _cache;

  Future<Map<String, dynamic>> loadGuide() async {
    if (_cache != null) return _cache!;
    final jsonStr = await rootBundle.loadString('assets/data/cacao_guide.json');
    _cache = jsonDecode(jsonStr) as Map<String, dynamic>;
    return _cache!;
  }

  Future<Map<String, dynamic>?> getDisease(String diseaseKey) async {
    final guide = await loadGuide();
    final diseases = guide['diseases'] as Map<String, dynamic>?;
    return diseases?[diseaseKey] as Map<String, dynamic>?;
  }

  Future<Map<String, dynamic>?> getRecommendation({
    required String diseaseKey,
    required String severityKey,
  }) async {
    final disease = await getDisease(diseaseKey);
    if (disease == null) return null;

    final recs = disease['recommendations'] as Map<String, dynamic>?;
    if (recs == null) return null;

    final usesDefault = diseaseKey == 'healthy' || diseaseKey == 'non_cacao';
    final key = usesDefault ? 'default' : severityKey;

    return recs[key] as Map<String, dynamic>?;
  }

  Map<String, String> parseModelLabel(String label) {
    const severities = {'mild', 'moderate', 'severe'};

    if (label == 'healthy' || label == 'non_cacao') {
      return {
        'diseaseKey': label,
        'severityKey': 'default',
      };
    }

    final parts = label.split('_');
    if (parts.isEmpty) {
      throw FormatException('Invalid label: $label');
    }

    final lastPart = parts.last;

    if (!severities.contains(lastPart)) {
      return {
        'diseaseKey': label,
        'severityKey': 'default',
      };
    }

    return {
      'diseaseKey': parts.sublist(0, parts.length - 1).join('_'),
      'severityKey': lastPart,
    };
  }

  Future<Map<String, dynamic>?> getMonitoringPlan({
    required String diseaseKey,
    required String severityKey,
  }) async {
    if (diseaseKey == 'healthy' || diseaseKey == 'non_cacao') {
      final disease = await getDisease(diseaseKey);
      final monitoringPlan = disease?['monitoring_plan'];
      if (monitoringPlan == null) return null;
      return Map<String, dynamic>.from(monitoringPlan as Map);
    }

    final recommendation = await getRecommendation(
      diseaseKey: diseaseKey,
      severityKey: severityKey,
    );

    final monitoringPlan = recommendation?['monitoring_plan'];
    if (monitoringPlan == null) return null;

    return Map<String, dynamic>.from(monitoringPlan as Map);
  }

  Future<int> getRescanAfterDays({
    required String diseaseKey,
    required String severityKey,
  }) async {
    final monitoringPlan = await getMonitoringPlan(
      diseaseKey: diseaseKey,
      severityKey: severityKey,
    );
    return (monitoringPlan?['rescan_after_days'] as num?)?.toInt() ?? 14;
  }

  Future<int> getPreferredTimeHour({
    required String diseaseKey,
    required String severityKey,
  }) async {
    final monitoringPlan = await getMonitoringPlan(
      diseaseKey: diseaseKey,
      severityKey: severityKey,
    );
    return (monitoringPlan?['preferred_time_hour'] as num?)?.toInt() ?? 9;
  }

  Future<String> getReminderMessage({
    required String diseaseKey,
    required String severityKey,
    String languageCode = 'en',
  }) async {
    final monitoringPlan = await getMonitoringPlan(
      diseaseKey: diseaseKey,
      severityKey: severityKey,
    );
    final message = monitoringPlan?['message'] as Map<String, dynamic>?;
    return message?[languageCode] as String? ??
        message?['en'] as String? ??
        'Time to scan again.';
  }

  Future<String> getDisplayName({
    required String diseaseKey,
    String languageCode = 'en',
  }) async {
    final disease = await getDisease(diseaseKey);
    final displayName = disease?['display_name'] as Map<String, dynamic>?;
    return displayName?[languageCode] as String? ??
        displayName?['en'] as String? ??
        diseaseKey;
  }
}