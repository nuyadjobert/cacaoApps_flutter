import 'package:cacao_apps/modules/scan/controllers/scan_result_controller.dart';
import 'package:cacao_apps/modules/scan/controllers/save_scan_controller.dart';
import 'package:cacao_apps/modules/scan/model/scan_result_model.dart';
import 'package:cacao_apps/modules/scan/views/location_picker_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/scan_result_header.dart';
import '../widgets/diagnosis_section.dart';
import '../widgets/location_status_banner.dart';
import '../widgets/treatment_plan_section.dart';
import '../widgets/scan_result_bottom_bar.dart';
import 'scan_unsuccessful_screen.dart';

class ScanResultScreen extends StatefulWidget {
  final List<ScanResultModel> results;

  const ScanResultScreen({
    super.key,
    required this.results,
  });

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  late final ScanResultController controller;
  late final SaveScanController saveController;
  String _selectedLang = 'en';

  @override
  void initState() {
    super.initState();
    final primary = widget.results[0];
    controller = ScanResultController(
      imagePath: primary.imagePath,
      diseaseName: primary.diseaseName,
      confidence: primary.confidence,
      severity: primary.severity,
    );

    saveController = SaveScanController();

    controller.init().then((_) {
      if (!mounted) return;

      if (controller.error == "NON_CACAO" ||
          controller.isNonCacao ||
          "LOW_CONFIDENCE" == controller.error ||
          controller.diseaseName == "unsupported_disease" ||
          controller.hasInvalidSeverityMismatch) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation1, animation2) =>
                const ScanUnsuccessfulScreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        return;
      }

      if (!controller.isNonCacao) {
        saveController.detectLocation().then((_) {
          if (!mounted) return;
          if (saveController.needsManualLocation) {
            _showLocationPicker();
          }
        });
      }
    });

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    saveController.dispose();
    super.dispose();
  }

  Future<void> _showLocationPicker() async {
    await LocationPickerSheet.show(
      context,
      controller: saveController.locationPicker,
      initialPosition: saveController.locationPicker.pickedLatLng,
    );
  }

  Future<void> _onSave() async {
    HapticFeedback.lightImpact();

    if (saveController.needsManualLocation) {
      final picked = await LocationPickerSheet.show(
        context,
        controller: saveController.locationPicker,
        initialPosition: saveController.locationPicker.pickedLatLng,
      );
      if (!picked || !mounted) return;
    }

    final ok = await saveController.saveScanRecord(
      diseaseKey: controller.diseaseKey,
      severityKey: controller.severityKey,
      confidence: controller.confidence,
      imagePath: controller.imagePath,
      rescanAfterDays: controller.rescanAfterDays,
      smsEnabled: false,
      isLoading: controller.isLoading,
    );
    debugPrint('Controller diseaseKey: ${controller.diseaseKey}');
    debugPrint('Controller severityKey: ${controller.severityKey}');
    debugPrint('Controller rescanAfterDays: ${controller.rescanAfterDays}');

    if (!mounted) return;
    _showSaveSnackBar(ok);
  }

  void _showSaveSnackBar(bool ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ok ? const Color(0xFF2D6A4F) : Colors.red.shade700,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(
              ok ? Icons.check_circle_outline : Icons.error_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                ok
                    ? "Scan saved successfully!"
                    : (saveController.saveError ?? "Save failed"),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Scan Result",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          _buildLanguageToggle(),
          const SizedBox(width: 8),
        ],
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => _buildBody(context, _selectedLang),
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          if (controller.isLoading || controller.error != null) {
            return const SizedBox.shrink();
          }
          return ScanResultBottomBar(
            saveController: saveController,
            isNonCacao: controller.isNonCacao,
            onSave: _onSave,
            onScanAgain: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, String lang) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2D6A4F)),
      );
    }

    final primaryTitle = controller.displayName[lang] ?? controller.diseaseName;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScanResultHeader(
            imagePath: controller.imagePath,
          ),
          const SizedBox(height: 16),
          _buildSectionHeader(
            label: lang == "tl" ? "PAGSUSURI" : "DIAGNOSIS",
            icon: Icons.gpp_maybe_rounded,
            color: const Color(0xFF2D6A4F),
          ),
          const SizedBox(height: 8),
          DiagnosisSection(
            diseaseName: primaryTitle,
            description: controller.description[lang] ?? "",
            severity: controller.severity,
            confidence: controller.confidence,
          ),
          const SizedBox(height: 32),
          LocationStatusBanner(
            locationPicker: saveController.locationPicker,
            onTap: _showLocationPicker,
            isDisabled: controller.isNonCacao,
          ),
          const SizedBox(height: 24),
          TreatmentPlanSection(
              recommendations: controller.recommendations, lang: lang),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      {required String label, required IconData icon, required Color color}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            letterSpacing: 1.2,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageToggle() {
    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC8E6C9), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleBtn("EN", _selectedLang == 'en'),
          _buildToggleBtn("TL", _selectedLang == 'tl'),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          HapticFeedback.mediumImpact();
          setState(() => _selectedLang = label.toLowerCase());
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: 40,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2D6A4F) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2D6A4F).withAlpha(77),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF2D6A4F),
          ),
        ),
      ),
    );
  }
}
