const Map<String, String> _diseaseDisplayNames = <String, String>{
  'black_pod_disease': 'Black Pod Disease',
  'cacao_pod_borer': 'Cacao Pod Borer',
  'healthy': 'Healthy',
  'mealybug': 'Mealybug',
};

String formatDiseaseName(String diseaseKey) {
  final String normalizedKey = diseaseKey.trim().toLowerCase();
  final String? mappedName = _diseaseDisplayNames[normalizedKey];
  if (mappedName != null) return mappedName;

  return normalizedKey
      .split(RegExp(r'[_\s]+'))
      .where((String word) => word.isNotEmpty)
      .map(
        (String word) =>
            '${word.substring(0, 1).toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}
