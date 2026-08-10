class ImageQualityResult {
  final bool isValid;
  final String? reason;
  final double brightness;
  final double sharpness;

  const ImageQualityResult({
    required this.isValid,
    required this.brightness,
    required this.sharpness,
    this.reason,
  });
}