import 'dart:async';
import 'package:cacao_apps/core/services/notification_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cacao_apps/core/db/user_repository.dart';
import 'package:cacao_apps/core/db/scan_repository.dart';
import 'package:cacao_apps/core/sync/sync_trigger.dart';
import 'package:cacao_apps/core/db/cacao_guide_repository.dart';
import 'package:cacao_apps/core/db/guide_sync_service.dart';
import 'package:cacao_apps/core/network/client.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cacao_apps/core/db/database_helper.dart';
import 'package:cacao_apps/modules/home/models/disease_counts_model.dart';
import 'package:cacao_apps/modules/home/services/statistics_service.dart';

class HomeController {
  bool _isResourcesLoaded = false;
  String? userName;
  late final SyncTrigger _syncTrigger;

  final CacaoGuideRepository _guideRepo = CacaoGuideRepository();
  final ScanRepository _scanRepository = ScanRepository();

  late final LocalNotificationService _notificationService =
      LocalNotificationService(_scanRepository);
  late final GuideSyncService _guideSyncService;
  late final StatisticsService _statisticsService;

  DiseaseCountsModel? _diseaseCounts;
  int? _selectedYear;
  bool _isLoadingStats = false;
  StatisticsLoadState _statsLoadState = StatisticsLoadState.initial;
  String? _statsError;

  // Getters for statistics state
  DiseaseCountsModel? get diseaseCounts => _diseaseCounts;
  int? get selectedYear => _selectedYear;
  bool get isLoadingStats => _isLoadingStats;
  StatisticsLoadState get statsLoadState => _statsLoadState;
  String? get statsError => _statsError;

  HomeController() {
    _guideSyncService = GuideSyncService(
      dio: DioClient.dio,
      guideRepository: _guideRepo,
    );
    _statisticsService = StatisticsService(dio: DioClient.dio);
    
    _syncTrigger = SyncTrigger(
      onSyncComplete: () {
        refreshStatisticsAfterSync();
      },
    );
  }

  Future<void> showDatabaseDebugToast() async {
    try {
      final db = await DatabaseHelper().db;
      final rawData = await db.query('guide_diseases');

      if (rawData.isEmpty) {
        Fluttertoast.showToast(msg: "Database is empty!");
        return;
      }

      final diseaseList = rawData.map((row) => row['disease_key']).join(', ');

      Fluttertoast.showToast(
        msg: "✅ DB has ${rawData.length} diseases: $diseaseList",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      Fluttertoast.showToast(msg: "Error reading DB: $e");
    }
  }

  final List<Map<String, dynamic>> diseaseData = [
    {
      "image": "assets/images/pb_bg.png",
      "images": [
        "assets/images/pb1.png",
        "assets/images/pb2.png",
        "assets/images/pb3.png",
      ],
      "title": "Cacao Pod Borer",
      "origin": "Southeast Asia",
      "description":
          "A small moth whose larvae tunnel into cocoa pods, disrupting bean development.",
      "symptoms": [
        "Premature ripening",
        "Uneven pod coloring",
        "Small exit holes",
        "Clumped, damaged beans",
      ],
      "tagalog": {
        "description":
            "Isang maliit na gamu-gamo kung saan ang mga uod nito ay bumubutas sa loob ng bunga ng kakaw, na sumisira sa paglaki ng mga buto.",
        "symptoms": [
          "Maagang pagkahinog ng bunga",
          "Hindi pantay na kulay ng balat",
          "Maliit na mga butas sa labas ng bunga",
          "Magkakadikit at sirang mga buto sa loob",
        ],
      },
    },
    {
      "image": "assets/images/bp_bg.png",
      "images": [
        "assets/images/bp1.png",
        "assets/images/bp2.png",
        "assets/images/bp3.png",
      ],
      "title": "Black Pod Rot",
      "origin": "Worldwide (Tropical)",
      "description":
          "Caused by Phytophthora fungi, it spreads rapidly in wet conditions.",
      "symptoms": [
        "Expanding dark brown spots",
        "White fungal growth",
        "Firm rot on pod surface",
        "Rotted internal beans",
      ],
      "tagalog": {
        "description":
            "Sanhi ng halamang-singaw na Phytophthora, mabilis itong kumakalat lalo na sa panahon ng tag-ulan o basang kapaligiran.",
        "symptoms": [
          "Lumalawak na maitim o kulay-kape na mga batik",
          "Puting amag sa ibabaw ng bunga",
          "Matigas na pagkabulok ng balat",
          "Mabahong pagkabulok ng mga buto sa loob",
        ],
      },
    },
    {
      "image": "assets/images/mb_bg.png",
      "images": [
        "assets/images/mb1.png",
        "assets/images/mb2.png",
        "assets/images/mb3.png",
      ],
      "title": "Mealybugs",
      "origin": "Global Tropics",
      "description":
          "Soft-bodied insects that suck sap and secrete honeydew, often spreading viruses.",
      "symptoms": [
        "White cottony clusters",
        "Sticky honeydew on leaves",
        "Sooty mold growth",
        "Yellowing of foliage",
      ],
      "tagalog": {
        "description":
            "Malambot na insekto na sumisipsip ng dagta ng puno at naglalabas ng malagkit na likido na nagiging sanhi ng virus.",
        "symptoms": [
          "Mapuputi at parang bulak na kumpol sa sanga o bunga",
          "Malagkit na likido sa mga dahon",
          "Pangungitim o pagkakaroon ng maitim na amag (sooty mold)",
          "Pagkapanilaw ng mga dahon",
        ],
      },
    },
  ];

  Future<void> startBackgroundServices() async {
    if (_isResourcesLoaded) return;

    try {
      await loadUserData();
      await _initializeAI();

      _isResourcesLoaded = true;
      debugPrint("TheobroTect: Background services initialized.");
    } catch (e) {
      debugPrint("TheobroTect Error: Failed to initialize services: $e");
    }
  }

  // Moved repository logic from View to Controller
  Future<void> checkPendingScans() async {
    final UserRepository userRepository = UserRepository();
    final ScanRepository scanRepository = ScanRepository();
    final user = await userRepository.getCurrentUser();

    if (user != null) {
      await _notificationService.scheduleUserNotifications(user.userId);
    }

    if (user == null) {
      debugPrint("❌ [HOME] No user found");
      return;
    }

    final pending = await scanRepository.getPendingScans(userId: user.userId);
    debugPrint(" [HOME] Pending scans count: ${pending.length}");

    for (var scan in pending) {
      debugPrint(" [HOME] Pending local_id: ${scan['local_id']}");
    }
  }

  void startSync() => _syncTrigger.start();
  void stopSync() => _syncTrigger.stop();

  // UPDATED: Sync and then verify
  Future<void> syncGuideData() async {
    try {
      debugPrint('Starting guide data sync...');
      final syncSuccess = await _guideSyncService.fetchUpdatesFromServer();

      debugPrint('Guide sync result: $syncSuccess');

      // If sync was successful, run our test to read from SQLite
      if (syncSuccess) {
        await _verifyLocalDatabase();

        await showDatabaseDebugToast();
      }
    } catch (e) {
      debugPrint('Guide sync failed: $e');
    }
  }

  Future<void> _verifyLocalDatabase() async {
    debugPrint('\n--- 🧪 TESTING LOCAL DATABASE SAVE ---');

    // 1. Check total count
    final count = await _guideRepo.getDiseaseCount();
    debugPrint('Total diseases in SQLite: $count');

    // 2. Fetch all raw rows directly to get the keys
    final db = await DatabaseHelper().db;
    final rawDiseases = await db.query('guide_diseases');

    if (rawDiseases.isEmpty) {
      debugPrint('❌ FAILED: No diseases found in SQLite.');
      debugPrint('--------------------------------------\n');
      return;
    }

    // 3. Loop through every disease found in the database
    for (var row in rawDiseases) {
      final String diseaseKey = row['disease_key'] as String;

      // Use your repository to get the properly formatted (JSON decoded) data
      final diseaseData = await _guideRepo.getDisease(diseaseKey);

      if (diseaseData != null) {
        debugPrint('\n✅ Successfully found: $diseaseKey');
        debugPrint(
            '   Display Name (EN): ${diseaseData['display_name']['en']}');
        debugPrint(
            '   Display Name (TL): ${diseaseData['display_name']['tl']}');

        // Optional: Test fetching recommendations for this specific disease
        final mildRecs =
            await _guideRepo.getRecommendations(diseaseKey, 'mild');
        debugPrint(
            '   Found ${mildRecs.length} "mild" recommendation categories.');
      } else {
        debugPrint('\n❌ FAILED: Could not decode data for $diseaseKey.');
      }
    }

    debugPrint('\n--------------------------------------\n');
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    userName = prefs.getString('user_full_name') ?? "Farmer";
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return "Good Morning,";
    if (hour >= 12 && hour < 17) return "Good Afternoon,";
    return "Good Evening,";
  }

  Future<void> fetchData(int index) async {
    debugPrint("TheobroTect: Fetching data for screen index $index...");
    switch (index) {
      case 0:
        await startBackgroundServices();
        break;
      case 1:
        await _fetchScanHistory();
        break;
      case 2:
        await _fetchEducationalContent();
        break;
      case 3:
        await loadUserData();
        await Future.delayed(const Duration(milliseconds: 300));
        break;
    }
  }

  Future<void> _initializeAI() async =>
      await Future.delayed(const Duration(milliseconds: 1500));
  Future<void> _fetchScanHistory() async =>
      await Future.delayed(const Duration(milliseconds: 1200));
  Future<void> _fetchEducationalContent() async =>
      await Future.delayed(const Duration(milliseconds: 1000));

  // ========== SCAN STATISTICS METHODS ==========

  /// Load scan statistics for the authenticated user
  /// [year] - Optional year filter. If null, loads all-time statistics
  /// [forceRefresh] - If true, bypasses cache and fetches fresh data
  Future<void> loadStatistics({int? year, bool forceRefresh = false}) async {
    // Don't reload if already loading
    if (_isLoadingStats && !forceRefresh) return;

    _isLoadingStats = true;
    _selectedYear = year;
    _statsLoadState = StatisticsLoadState.loading;
    _statsError = null;

    try {
      debugPrint('📊 [HOME] Loading statistics${year != null ? ' for year $year' : ' (all-time)'}');

      // Check connectivity first
      final connectivity = await Connectivity().checkConnectivity();
      final hasConnection = connectivity.any((r) => r != ConnectivityResult.none);

      if (!hasConnection) {
        _statsLoadState = StatisticsLoadState.offline;
        _statsError = 'No internet connection';
        debugPrint('🌐 [HOME] Device is offline');
        return;
      }

      // Check if server is reachable
      final serverReachable = await _statisticsService.isServerReachable();
      if (!serverReachable) {
        _statsLoadState = StatisticsLoadState.serverUnreachable;
        _statsError = 'Server is currently unavailable';
        debugPrint('🌐 [HOME] Server unreachable');
        return;
      }

      // Fetch statistics from API
      _diseaseCounts = await _statisticsService.getUserDiseaseCounts(year: year);

      if (_diseaseCounts!.isEmpty) {
        _statsLoadState = StatisticsLoadState.empty;
        debugPrint('📊 [HOME] No scans found');
      } else {
        _statsLoadState = StatisticsLoadState.success;
        debugPrint('✅ [HOME] Statistics loaded: ${_diseaseCounts!.totalScans} total scans');
      }
    } on DioException catch (e) {
      debugPrint('❌ [HOME] API error: ${e.type} - ${e.message}');

      if (e.response?.statusCode == 401) {
        _statsLoadState = StatisticsLoadState.authError;
        _statsError = 'Authentication failed';
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        _statsLoadState = StatisticsLoadState.serverUnreachable;
        _statsError = 'Request timed out';
      } else {
        _statsLoadState = StatisticsLoadState.error;
        _statsError = e.message ?? 'Failed to load statistics';
      }
    } catch (e) {
      debugPrint('❌ [HOME] Unexpected error: $e');
      _statsLoadState = StatisticsLoadState.error;
      _statsError = 'An unexpected error occurred';
    } finally {
      _isLoadingStats = false;
    }
  }

  /// Refresh statistics after sync completes
  Future<void> refreshStatisticsAfterSync() async {
    debugPrint('🔄 [HOME] Refreshing statistics after sync');
    await loadStatistics(year: _selectedYear, forceRefresh: true);
  }

  /// Change the selected year and reload statistics
  Future<void> changeYear(int? year) async {
    if (_selectedYear == year) return; // Already selected
    await loadStatistics(year: year);
  }

  /// Retry loading statistics after error or offline state
  Future<void> retryLoadStatistics() async {
    await loadStatistics(year: _selectedYear, forceRefresh: true);
  }
}

/// Statistics load state enum
enum StatisticsLoadState {
  initial,
  loading,
  success,
  empty,
  offline,
  serverUnreachable,
  authError,
  error,
}
