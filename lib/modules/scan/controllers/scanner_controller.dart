import 'package:cacao_apps/core/ml/cacao_model_service.dart';
import 'package:cacao_apps/modules/scan/model/scan_result_model.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

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

  // UPDATED: Added optional {Rect? cropRect} parameter
  Future<List<ScanResultModel>?> captureAndAnalyze({Rect? cropRect}) async {
    if (!isReady) {
      debugPrint("===== Scanner Not Ready =====");
      debugPrint("Permission : $_isPermissionGranted");
      debugPrint("Camera     : ${_camera != null}");
      debugPrint("Initialized: ${_camera?.value.isInitialized}");
      debugPrint("Model      : ${CacaoModelService().isLoaded}");
      debugPrint("=============================");
      return null;
    }
    if (_isAnalyzing) return null;

    HapticFeedback.heavyImpact();

    _isAnalyzing = true;
    notifyListeners();

    try {
      final XFile photo = await _camera!.takePicture();

      await turnOffFlash();

      final imagePath = photo.path;

      debugPrint("\n📸 [SCANNER] Picture taken at: $imagePath");
      debugPrint("🧠 [SCANNER] Sending to multi-task ML model...");

      // UPDATED: Forward cropRect to the prediction service
      final predictions = await CacaoModelService().predict(
        imagePath,
        cropRect: cropRect,
      );

      if (predictions.isEmpty) {
        debugPrint("⚠️ [SCANNER] No predictions returned from the model.");
        return null;
      }

      // Convert ALL predictions into UI models AND log them
      final results = predictions.map((pred) {
        String finalSeverity =
            (pred.diseaseLabel == 'healthy' || pred.diseaseLabel == 'non_cacao')
                ? 'N/A'
                : _capitalize(pred.severityLabel);

        debugPrint("================= SCAN RESULT =================");
        debugPrint(
            "🧪 RAW DISEASE  : ${pred.diseaseLabel} (${(pred.diseaseConfidence * 100).toStringAsFixed(2)}%)");
        debugPrint(
            "🧪 RAW SEVERITY : ${pred.severityLabel} (${(pred.severityConfidence * 100).toStringAsFixed(2)}%)");
        debugPrint("📱 UI DISEASE   : ${_toDisplayName(pred.diseaseLabel)}");
        debugPrint("📱 UI SEVERITY  : $finalSeverity");
        debugPrint("===============================================\n");

        return ScanResultModel(
          imagePath: imagePath,
          diseaseName: _toDisplayName(pred.diseaseLabel),
          confidence: pred.diseaseConfidence,
          severity: finalSeverity,
        );
      }).toList();

      return results;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("❌ [SCANNER] Error during capture and analyze: $e");
      }
      return null;
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
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

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  @override
  void dispose() {
    if (_camera != null && _isFlashOn) {
      _camera!.setFlashMode(FlashMode.off);
    }

    _camera?.dispose();
    super.dispose();
  }
}