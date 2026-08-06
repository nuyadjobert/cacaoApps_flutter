class ImageQualityConfig {
  static const double minBrightness = 45.0;

  static const double maxBrightness = 220.0;

  static const double minSharpness = 8.0;

  static const String messageToDark =
      'Image is too dark. Move to a brighter area or use the flash.';

  static const String messageTooBright =
      'Image is too bright. Avoid direct sunlight and scan again.';

  static const String messageBlurry =
      'Image is blurry. Hold the phone steady and scan again.';

  static const String messageUnreadable = 'Unable to analyze image quality';

  static const String messageInvalidImage = 'Unable to read image';
}
