/// Disease counts response model from the backend API
/// Represents the authenticated user's scan statistics
class DiseaseCountsModel {
  final int healthy;
  final int blackPodDisease;
  final int cacaoPodBorer;
  final int mealybug;

  DiseaseCountsModel({
    required this.healthy,
    required this.blackPodDisease,
    required this.cacaoPodBorer,
    required this.mealybug,
  });

  /// Total number of scans across all categories
  int get totalScans => healthy + blackPodDisease + cacaoPodBorer + mealybug;

  /// Total disease/pest detections (excludes healthy)
  int get totalDiseased => blackPodDisease + cacaoPodBorer + mealybug;

  /// Create model from JSON response
  factory DiseaseCountsModel.fromJson(Map<String, dynamic> json) {
    return DiseaseCountsModel(
      healthy: (json['healthy'] ?? 0) as int,
      blackPodDisease: (json['black_pod_disease'] ?? 0) as int,
      cacaoPodBorer: (json['cacao_pod_borer'] ?? 0) as int,
      mealybug: (json['mealybug'] ?? 0) as int,
    );
  }

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'healthy': healthy,
      'black_pod_disease': blackPodDisease,
      'cacao_pod_borer': cacaoPodBorer,
      'mealybug': mealybug,
    };
  }

  /// Empty/zero state
  factory DiseaseCountsModel.empty() {
    return DiseaseCountsModel(
      healthy: 0,
      blackPodDisease: 0,
      cacaoPodBorer: 0,
      mealybug: 0,
    );
  }

  /// Check if all counts are zero
  bool get isEmpty => totalScans == 0;
}
