import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/widgets/toast.dart';

class VerifyUnsuccessScreen extends StatefulWidget {
  final String message;
  final VoidCallback onTryAgain;

  const VerifyUnsuccessScreen({
    super.key,
    required this.message,
    required this.onTryAgain,
  });

  @override
  State<VerifyUnsuccessScreen> createState() => _VerifyUnsuccessScreenState();
}

class _VerifyUnsuccessScreenState extends State<VerifyUnsuccessScreen>
    with TickerProviderStateMixin {
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

    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _sparkleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _fadeController.forward();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        TopToast.show(context, widget.message, type: ToastType.error);
      }
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final errorColor = colorScheme.error;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onTryAgain,
                    icon: Icon(
                      Icons.arrow_back,
                      color: colorScheme.onSurface,
                      size: 22,
                    ),
                  ),
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
                      Text(
                        'TheobroTect',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: colorScheme.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const Spacer(flex: 2),
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ..._buildSparkles(errorColor),
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: errorColor,
                        boxShadow: [
                          BoxShadow(
                            color: errorColor.withValues(alpha: 0.35),
                            blurRadius: 30,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: colorScheme.onError,
                        size: 72,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    Text(
                      'Verification Failed',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(flex: 2),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      elevation: 4,
                      shadowColor: colorScheme.primary.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: widget.onTryAgain,
                    child: const Text(
                      'Try Again',
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
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    color: colorScheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Your data is 100% secure',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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

  List<Widget> _buildSparkles(Color color) {
    const positions = [
      Offset(-80, -60),
      Offset(80, -60),
      Offset(-90, 10),
      Offset(90, 10),
      Offset(-60, 70),
      Offset(60, 70),
      Offset(-20, -88),
      Offset(20, -88),
    ];
    const sizes = [12.0, 10.0, 8.0, 12.0, 10.0, 8.0, 10.0, 8.0];

    return List.generate(positions.length, (index) {
      return AnimatedBuilder(
        animation: _sparkleController,
        builder: (context, child) {
          final progress = _sparkleController.value;
          final delay = (index * 0.1).clamp(0.0, 1.0);
          final localProgress =
              ((progress - delay) / (1.0 - delay)).clamp(0.0, 1.0);

          return Positioned(
            left: 110 + positions[index].dx - sizes[index] / 2,
            top: 110 + positions[index].dy - sizes[index] / 2,
            child: Opacity(
              opacity: localProgress,
              child: Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                  width: sizes[index],
                  height: sizes[index],
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.7),
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
