import 'package:flutter/material.dart';
import 'dart:math' as math;

class VerifySuccessScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const VerifySuccessScreen({super.key, required this.onContinue});

  @override
  State<VerifySuccessScreen> createState() => _VerifySuccessScreenState();
}

class _VerifySuccessScreenState extends State<VerifySuccessScreen>
    with TickerProviderStateMixin {
  static const Color forestGreen = Color(0xFF1B5E20);

  late final AnimationController _scaleController;
  late final AnimationController _fadeController;
  late final AnimationController _sparkleController;

  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Staggered entry
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _sparkleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.translate(
                        offset: const Offset(10, 0),
                        child: Image.asset(
                          'assets/images/theobrotect.png',
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const Text(
                        "TheobroTect",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: forestGreen,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const SizedBox(width: 22),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // ── Animated checkmark with sparkles ──
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Sparkle diamonds around the circle
                  ..._buildSparkles(),

                  // Scale-in green circle with checkmark
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: forestGreen,
                        boxShadow: [
                          BoxShadow(
                            color: forestGreen.withValues(alpha: 0.35),
                            blurRadius: 30,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 72,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // ── Title + subtitle ──
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  const Text(
                    "Email Verified!",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Your email address has been\nverified successfully.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // ── Continue button ──
            FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: forestGreen,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: forestGreen.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: widget.onContinue,
                    child: const Text(
                      "Continue",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Bottom secure label ──
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user_outlined,
                      color: forestGreen, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    "Your data is 100% secure",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds 8 sparkle diamonds positioned around the circle
  List<Widget> _buildSparkles() {
    final colors = [
      Colors.amber,
      const Color(0xFF4FC3F7), // light blue
      Colors.amber,
      const Color(0xFF4FC3F7),
      Colors.amber,
      const Color(0xFF4FC3F7),
      Colors.amber,
      const Color(0xFF4FC3F7),
    ];

    final positions = [
      const Offset(-80, -60),
      const Offset(80, -60),
      const Offset(-90, 10),
      const Offset(90, 10),
      const Offset(-60, 70),
      const Offset(60, 70),
      const Offset(-20, -88),
      const Offset(20, -88),
    ];

    final sizes = [12.0, 10.0, 8.0, 12.0, 10.0, 8.0, 10.0, 8.0];

    return List.generate(8, (i) {
      return AnimatedBuilder(
        animation: _sparkleController,
        builder: (context, child) {
          final progress = _sparkleController.value;
          final delay = (i * 0.1).clamp(0.0, 1.0);
          final localProgress =
              ((progress - delay) / (1.0 - delay)).clamp(0.0, 1.0);

          return Positioned(
            left: 110 + positions[i].dx - sizes[i] / 2,
            top: 110 + positions[i].dy - sizes[i] / 2,
            child: Opacity(
              opacity: localProgress,
              child: Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                  width: sizes[i],
                  height: sizes[i],
                  decoration: BoxDecoration(
                    color: colors[i],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }
}