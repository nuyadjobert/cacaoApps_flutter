import 'dart:io';

import 'package:cacao_apps/core/ml/cacao_model_service.dart';
import 'package:cacao_apps/modules/scan/model/scan_result_model.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import '../config/image_quality_config.dart';
import '../model/image_quality_result.dart';
class ScannerController extends ChangeNotifier {
  CameraController? _camera;
  List<CameraDescription>? _cameras;

  bool _isPermissionGranted = false;
  bool _isFlashOn = false;
  bool _isAnalyzing = false;

  CameraController? get camera => _camera;
  CameraController? get cameraController => _camera;

  bool get isPermissionGranted => _isPermissionGranted;
  bool get isFlashOn => _isFlashOn;
  bool get isAnalyzing => _isAnalyzing;

  bool get isReady =>
      _isPermissionGranted &&
      _camera != null &&
      _camera!.value.isInitialized &&
      CacaoModelService().isLoaded;

  Future<void> init() async {
    await Future.wait([
      CacaoModelService().loadModel(),
      _setupCamera(),
    ]);
  }

  Future<void> _setupCamera() async {
    final status = await Permission.camera.request();

    if (!status.isGranted) {
      _isPermissionGranted = false;
      notifyListeners();
      return;
    }

    _isPermissionGranted = true;
    notifyListeners();

    _cameras = await availableCameras();

    if (_cameras == null || _cameras!.isEmpty) {
      _isPermissionGranted = false;
      notifyListeners();
      return;
    }

    _camera = CameraController(
      _cameras![0],
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _camera!.initialize();

    notifyListeners();
  }

  Future<void> toggleFlash() async {
    if (_camera == null) return;

    if (_isFlashOn) {
      await _camera!.setFlashMode(FlashMode.off);
    } else {
      await _camera!.setFlashMode(FlashMode.torch);
    }

    _isFlashOn = !_isFlashOn;

    notifyListeners();
  }

  Future<void> turnOffFlash() async {
    if (_camera == null || !_isFlashOn) return;

    await _camera!.setFlashMode(FlashMode.off);

    _isFlashOn = false;

    notifyListeners();
  }

  Future<List<ScanResultModel>?> captureAndAnalyze({
    Rect? cropRect,
  }) async {
    if (!isReady) {
      return null;
    }

    if (_isAnalyzing) {
      return null;
    }

    HapticFeedback.heavyImpact();

    _isAnalyzing = true;
    notifyListeners();

    try {

      final XFile photo = await _camera!.takePicture();

      await turnOffFlash();
      final imagePath = photo.path;
      final quality = await checkImageQuality(imagePath);
    
      if (!quality.isValid) {
        return [
          ScanResultModel(
            imagePath: imagePath,
            diseaseName: 'Rescan Required',
            confidence: 0,
            severity: quality.reason ?? 'Poor image quality',
          ),
        ];
      }

      final predictions = await CacaoModelService().predict(
        imagePath,
        cropRect: cropRect,
      );

      if (predictions.isEmpty) {
        return null;
      }

      final results = predictions.map((pred) {
        final String finalSeverity =
            pred.diseaseLabel == 'healthy' ||
                    pred.diseaseLabel == 'non_cacao'
                ? 'N/A'
                : _capitalize(pred.severityLabel);

        debugPrint('');
        debugPrint('================ SCAN RESULT ================');

        debugPrint(
          '🧪 RAW DISEASE  : '
          '${pred.diseaseLabel} '
          '(${(pred.diseaseConfidence * 100).toStringAsFixed(2)}%)',
        );

        debugPrint(
          '🧪 RAW SEVERITY : '
          '${pred.severityLabel} '
          '(${(pred.severityConfidence * 100).toStringAsFixed(2)}%)',
        );

        debugPrint(
          '📱 UI DISEASE   : ${_toDisplayName(pred.diseaseLabel)}',
        );

        debugPrint(
          '📱 UI SEVERITY  : $finalSeverity',
        );

        debugPrint('=============================================');

        return ScanResultModel(
          imagePath: imagePath,
          diseaseName: _toDisplayName(
            pred.diseaseLabel,
          ),
          confidence: pred.diseaseConfidence,
          severity: finalSeverity,
        );
      }).toList();

      return results;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrintStack(
          stackTrace: stackTrace,
        );
      }

      return null;
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  Future<ImageQualityResult> checkImageQuality(
    String imagePath,
  ) async {
    try {
      final bytes = await File(
        imagePath,
      ).readAsBytes();

      final image = img.decodeImage(
        bytes,
      );

      if (image == null) {
        return const ImageQualityResult(
          isValid: false,
          reason: ImageQualityConfig.messageInvalidImage,
          brightness: 0,
          sharpness: 0,
        );
      }

      final resized = img.copyResize(
        image,
        width: 320,
      );

      double brightnessSum = 0;
      int brightnessPixelCount = 0;

      for (int y = 0; y < resized.height; y++) {
        for (int x = 0; x < resized.width; x++) {
          final pixel = resized.getPixel(
            x,
            y,
          );

          final double luminance = _gray(
            pixel,
          );

          brightnessSum += luminance;
          brightnessPixelCount++;
        }
      }

      final double averageBrightness =
          brightnessPixelCount > 0
              ? brightnessSum / brightnessPixelCount
              : 0;

      double sharpnessSum = 0;
      int edgeCount = 0;

      for (int y = 1; y < resized.height - 1; y++) {
        for (int x = 1; x < resized.width - 1; x++) {
          final double current = _gray(
            resized.getPixel(
              x,
              y,
            ),
          );

          final double right = _gray(
            resized.getPixel(
              x + 1,
              y,
            ),
          );

          final double bottom = _gray(
            resized.getPixel(
              x,
              y + 1,
            ),
          );

          final double horizontalDifference =
              (current - right).abs();

          final double verticalDifference =
              (current - bottom).abs();

          sharpnessSum +=
              horizontalDifference +
              verticalDifference;

          edgeCount++;
        }
      }

      final double sharpness =
          edgeCount > 0
              ? sharpnessSum / edgeCount
              : 0;

      if (averageBrightness < ImageQualityConfig.minBrightness) {
        return ImageQualityResult(
          isValid: false,
          reason: ImageQualityConfig.messageToDark,
          brightness: averageBrightness,
          sharpness: sharpness,
        );
      }

      if (averageBrightness > ImageQualityConfig.maxBrightness) {
        return ImageQualityResult(
          isValid: false,
          reason: ImageQualityConfig.messageTooBright,
          brightness: averageBrightness,
          sharpness: sharpness,
        );
      }

      if (sharpness < ImageQualityConfig.minSharpness) {
        return ImageQualityResult(
          isValid: false,
          reason: ImageQualityConfig.messageBlurry,
          brightness: averageBrightness,
          sharpness: sharpness,
        );
      }

      return ImageQualityResult(
        isValid: true,
        brightness: averageBrightness,
        sharpness: sharpness,
      );
    } catch (e) {
      return const ImageQualityResult(
        isValid: false,
        reason: ImageQualityConfig.messageUnreadable,
        brightness: 0,
        sharpness: 0,
      );
    }
  }

  double _gray(img.Pixel pixel) {
    return (0.299 * pixel.r.toDouble()) +
        (0.587 * pixel.g.toDouble()) +
        (0.114 * pixel.b.toDouble());
  }

  String _toDisplayName(String diseaseKey) {
    switch (diseaseKey) {
      case 'black_pod_disease':
        return 'Black Pod Disease';
      case 'cacao_pod_borer':
        return 'Cacao Pod Borer';
      case 'mealybug':
        return 'Mealybug';
      case 'healthy':
        return 'Healthy';
      case 'non_cacao':
        return 'Non Cacao';
      default:
        return diseaseKey;
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) {
      return s;
    }

    return '${s[0].toUpperCase()}${s.substring(1)}';
  }

  @override
  void dispose() {
    if (_camera != null && _isFlashOn) {
      _camera!.setFlashMode(
        FlashMode.off,
      );
    }
    _camera?.dispose();
    super.dispose();
  }
}