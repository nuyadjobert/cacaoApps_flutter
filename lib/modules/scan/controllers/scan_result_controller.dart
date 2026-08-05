import 'package:cacao_apps/core/guide/cacao_guide_service.dart';
import 'package:flutter/material.dart';
import 'save_scan_controller.dart';
import 'package:cacao_apps/core/db/cacao_guide_repository.dart';
import 'package:cacao_apps/modules/scan/model/recommendation_item.dart';
import 'package:cacao_apps/modules/scan/model/treatment_task.dart';

class ScanResultController extends ChangeNotifier {
  final String diseaseName;
  final double confidence;
  final String severity;
  final String? imagePath;
  final CacaoGuideRepository _repository = CacaoGuideRepository();
  final CacaoGuideService _guide = CacaoGuideService();
  final SaveScanController saveScan = SaveScanController();

  ScanResultController({
    required this.diseaseName,
    required this.confidence,
    required this.severity,
    this.imagePath,
  });

  Map<String, String> secondaryDisplayName = {
    "en": "",
    "tl": "",
  };

  Map<String, String> secondaryDescription = {
    "en": "",
    "tl": "",
  };

  bool _isLoading = true;
  String? _error;
  bool get isLoading => _isLoading;
  String? get error => _error;
  late final String diseaseKey;
  late final String severityKey;

  Map<String, String> displayName = const {
    "en": "Unknown",
    "tl": "Hindi Kilala",
  };
  Map<String, String> description = const {"en": "", "tl": ""};

  List<RecommendationItem> recommendations = [];
  int? rescanAfterDays;
  Map<String, String>? rescanMessage;

  List<TreatmentTask> getTreatmentPlan(String lang) {
    // Dynamically choose between Tagalog or English lists
    final items = recommendations
        .expand((e) => lang == 'tl' ? e.contentTl : e.contentEn)
        .toList();

    if (items.isEmpty) {
      return [
        TreatmentTask(
          icon: Icons.visibility_outlined,
          title: lang == 'tl' ? "Subaybayan" : "Monitor",
          desc: lang == 'tl'
              ? "Obserbahan ang bunga at i-scan muli pagkalipas ng ilang araw."
              : "Observe the pod and rescan after a few days.",
        ),
      ];
    }

    return items
        .map(
          (item) => TreatmentTask(
            icon: Icons.check_circle_outline,
            title: lang == 'tl' ? "Rekomendasyon" : "Recommendation",
            desc: item,
          ),
        )
        .toList();
  }

  bool get isBookmarked => saveScan.isSaved;
  bool get isNonCacao => diseaseKey == 'non_cacao';
  bool get isLowConfidence => confidence < 0.70;

  void toggleBookmark() {
    // saveScan.toggleSaveRecord();
    notifyListeners();
  }

  Future<void> init() async {
    _isLoading = true;
    _error = null;

    diseaseKey = _diseaseKeyFromName(diseaseName);

    if (hasHighNonCacaoConfidence) {
      _error = "NON_CACAO";
      _isLoading = false;
      notifyListeners();
      return;
    }
    if (confidence < 0.70) {
      _error = "LOW_CONFIDENCE";
      _isLoading = false;
      notifyListeners();
      return; // Stop execution
    }
    notifyListeners();

    try {
      severityKey = _severityKeyFromText(severity);
      final disease = await _guide.getDisease(diseaseKey);
      if (disease == null) {
        throw Exception(
          'Disease not found in guide: $diseaseKey',
        );
      }
      final monitoringPlan = await _repository.getMonitoringPlan(
        diseaseKey,
        severityKey,
      );

      if (monitoringPlan != null) {
        rescanAfterDays = monitoringPlan['rescan_after_days'] as int?;

        rescanMessage = Map<String, String>.from(
          monitoringPlan['message'] as Map,
        );

        debugPrint('========== Monitoring Plan ==========');
        debugPrint('Disease: $diseaseKey');
        debugPrint('Severity: $severityKey');
        debugPrint('Rescan After: $rescanAfterDays');
        debugPrint('Preferred Hour: ${monitoringPlan['preferred_time_hour']}');
        debugPrint('=====================================');
      } else {
        debugPrint('No monitoring plan found for $diseaseKey / $severityKey');
      }

      displayName = _mapLang(
        disease['display_name'],
      );

      description = _mapLang(
        disease['description'],
      );

      final recommendationRows =
          await _repository.getRecommendations(diseaseKey, severityKey);

      recommendations.clear();

      for (final row in recommendationRows) {
        final category = row['category_key']?.toString() ?? 'general';
        final content = row['content'];

        final itemsEn = _listLang(content, 'en');
        final itemsTl = _listLang(content, 'tl');

        recommendations.add(
          RecommendationItem(
            category: category,
            contentEn: itemsEn,
            contentTl: itemsTl,
          ),
        );
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  bool get hasHighNonCacaoConfidence {
    if (diseaseKey == 'non_cacao' && confidence >= 0.50) {
      return true;
    }
    return false;
  }

  Future<bool> saveScanRecord({bool smsEnabled = false}) {
    return saveScan.saveScanRecord(
      diseaseKey: diseaseKey,
      severityKey: severityKey,
      confidence: confidence,
      imagePath: imagePath,
      rescanAfterDays: rescanAfterDays,
      smsEnabled: smsEnabled,
      isLoading: _isLoading,
    );
  }

  String _diseaseKeyFromName(String name) {
    final n = name.trim().toLowerCase();
    if (n.contains('black pod')) return 'black_pod_disease';
    if (n.contains('pod borer')) return 'cacao_pod_borer';
    if (n.contains('mealybug')) return 'mealybug';
    if (n.contains('healthy')) return 'healthy';
    if (n.contains('non_cacao') || n.contains('non cacao')) return 'non_cacao';
    return 'healthy';
  }

  String _severityKeyFromText(String severity) {
    final s = severity.trim().toLowerCase();
    if (s.contains('mild')) return 'mild';
    if (s.contains('moderate')) return 'moderate';
    if (s.contains('severe')) return 'severe';
    return 'default';
  }

  Map<String, String> _mapLang(dynamic node) {
    if (node is Map<String, dynamic>) {
      return {
        'en': node['en']?.toString() ?? '',
        'tl': node['tl']?.toString() ?? '',
      };
    }
    return {'en': '', 'tl': ''};
  }

  List<String> _listLang(dynamic node, String lang) {
    debugPrint("==== _listLang ====");
    debugPrint("LANG: $lang");
    debugPrint("NODE TYPE: ${node.runtimeType}");
    debugPrint("NODE VALUE: $node");

    final List<String> results = [];

    if (node is List) {
      for (final item in node) {
        if (item is Map) {
          final value = item[lang];
          if (value is List) {
            results.addAll(value.map((e) => e.toString()));
          } else if (value != null) {
            results.add(value.toString());
          }
        } else if (item is String) {
          results.add(item);
        }
      }
      debugPrint("LIST RESULT: $results");
      return results;
    }

    if (node is Map) {
      final value = node[lang];
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      if (value is String) {
        return [value];
      }

      for (final entry in node.entries) {
        if (entry.value is Map) {
          final inner = _listLang(entry.value, lang);
          if (inner.isNotEmpty) {
            results.addAll(inner);
          }
        }
      }
    }

    debugPrint("FINAL RESULT: $results");
    return results;
  }

  bool get hasInvalidSeverityMismatch {
    bool isDisease = diseaseName != 'healthy' && diseaseName != 'non_cacao' && diseaseName != 'unsupported_disease';
    bool isSeverityNone = severity.toLowerCase() == 'none';
    
    return isDisease && isSeverityNone;
  }
}
