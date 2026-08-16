import 'package:flutter/material.dart';

class ScanUnsuccessfulScreen extends StatelessWidget {
  final String title;
  final String message;

  const ScanUnsuccessfulScreen({
    super.key,
    this.title = "RESULT UNCLEAR",
    this.message =
      "We couldn't clearly identify the condition of this cacao pod. "
      "Please check the tips below and scan the pod again.",
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1910),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              // Icon Container
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withAlpha(26), //0.1* 255 = 25.5 ~ 26
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        Colors.redAccent.withAlpha(76), // 0.3 * 255 = 76.5 ~ 77
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 72,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),

              // Subtitle
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withAlpha(178), // 0.7 * 255 = 178.5 ~ 178
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Instruction Checklist Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(26), // 0.1 * 255 = 25.5 ~ 26
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color:
                          Colors.white.withAlpha(77)), // 0.3 * 255 = 76.5 ~ 77
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Before scanning:",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTipRow(
                        Icons.check_circle_outline, "Scan only one cacao pod"),
                    const SizedBox(height: 12),
                    _buildTipRow(Icons.check_circle_outline,
                        "Keep the entire pod visible and centered"),
                    const SizedBox(height: 12),
                    _buildTipRow(
                        Icons.check_circle_outline, "Make sure the camera is clear and in focus"),
                    const SizedBox(height: 12),
                    _buildTipRow(
                        Icons.check_circle_outline, "Use good lighting and Avoid shadows and Glare"),
                  ],
                ),
              ),
              const Spacer(),

              // Try Again Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D6A4F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context), // Returns to camera
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  label: const Text(
                    "Try Again",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2EFA8A), size: 20),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }
}
