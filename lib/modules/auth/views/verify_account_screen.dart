import 'package:cacao_apps/modules/home/views/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/verify_account_controller.dart';
import '../services/auth_services.dart';
import '../../../core/network/client.dart';
import '../controllers/registration_controller.dart';
import '../models/registration_model.dart';
import 'registration_screen.dart';
import 'verifying_overlay.dart';
import 'verify_unsuccess_screen.dart';
import 'verify_success_screen.dart'; // ← new import

class VerifyAccountScreen extends StatefulWidget {
  final String email;

  const VerifyAccountScreen({super.key, required this.email});

  @override
  State<VerifyAccountScreen> createState() => _VerifyAccountScreenState();
}

class _VerifyAccountScreenState extends State<VerifyAccountScreen> {
  static const Color forestGreen = Color(0xFF1B5E20);
  static const Color lightForest = Color(0xFFE8F5E9);

  late final VerifyAccountController controller;

  @override
  void initState() {
    super.initState();
    controller = VerifyAccountController(
      auth: AuthService(DioClient.dio),
      email: widget.email,
    );
    controller.requestOtp();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = screenHeight < 700 ? 180.0 : 220.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        resizeToAvoidBottomInset: true,
        body: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            // ── Full-screen verifying overlay while loading ──
            if (controller.verificationStatus == VerificationStatus.verifying) {
              return const VerifyingOverlay();
            }

            // ── Success screen after verified ──
            if (controller.verificationStatus == VerificationStatus.success) {
              return VerifySuccessScreen(
                onContinue: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
              );
            }

            // ── New user: go to registration (no success screen needed) ──
            if (controller.isNewUserRequired) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => RegistrationScreen(
                      controller: RegistrationController(
                        AuthService(DioClient.dio),
                      ),
                      model: RegistrationRequest(
                        email: controller.email,
                        name: '',
                        address: '',
                        contactNumber: '',
                      ),
                    ),
                  ),
                );
              });
            }

            if (controller.verificationStatus == VerificationStatus.failed) {
              return VerifyUnsuccessScreen(
                message: controller.verificationMessage,
                onTryAgain: controller.resetVerification,
              );
            }

            return SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),

                              // ── Logo + name ──
                              Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Transform.translate(
                                      offset: const Offset(10, 0),
                                      child: Image.asset(
                                        'assets/images/theobrotect.png',
                                        width: 32,
                                        height: 32,
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
                              ),

                              const Spacer(),

                              // ── Illustration image ──
                              Center(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.asset(
                                    'assets/images/verify_illustration.png',
                                    width: double.infinity,
                                    height: imageHeight,
                                    fit: BoxFit.fitHeight,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            SizedBox(
                                      height: imageHeight,
                                      child: const Icon(
                                        Icons.verified_user_outlined,
                                        size: 80,
                                        color: forestGreen,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const Spacer(),

                              // ── Title ──
                              Center(
                                child: Text(
                                  "Verify Identity",
                                  textAlign: TextAlign.center,
                                  style:
                                      theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: forestGreen,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "We've sent a 6-digit code to your email. Enter it below to proceed.",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.4,
                                ),
                              ),

                              const SizedBox(height: 24),

                              // ── OTP fields ──
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: List.generate(
                                  6,
                                  (i) =>
                                      _buildOtpField(context, i, colorScheme),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // ── Timer + resend ──
                              Center(
                                child: Column(
                                  children: [
                                    AnimatedBuilder(
                                      animation: controller,
                                      builder: (context, index) {
                                        return Text(
                                          "RESEND CODE IN ${controller.timerText}",
                                          style: theme.textTheme.labelMedium
                                              ?.copyWith(
                                            color: controller.secondsLeft > 0
                                                ? colorScheme.outline
                                                : forestGreen,
                                            letterSpacing: 1.2,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      },
                                    ),
                                    AnimatedBuilder(
                                      animation: controller,
                                      builder: (context, index) {
                                        return TextButton(
                                          onPressed: controller.secondsLeft == 0
                                              ? () => controller.startTimer(200)
                                              : null,
                                          style: TextButton.styleFrom(
                                            foregroundColor: forestGreen,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4),
                                          ),
                                          child: Text(
                                            controller.secondsLeft == 0
                                                ? "Resend New Code"
                                                : "Didn't get a code?",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              const Spacer(),

                              // ── Verify button ──
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: forestGreen,
                                    foregroundColor: Colors.white,
                                    elevation: 4,
                                    shadowColor: forestGreen.withAlpha(102),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: () async {
                                    await controller.verify();
                                  },
                                  child: const Text(
                                    "VERIFY",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // ── Back to sign in ──
                              Center(
                                child: TextButton.icon(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.arrow_back_rounded,
                                      size: 14),
                                  label: const Text(
                                    "BACK TO SIGN IN",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: colorScheme.outline,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOtpField(
    BuildContext context,
    int index,
    ColorScheme colorScheme,
  ) {
    return Container(
      width: 44,
      height: 56,
      decoration: BoxDecoration(
        color: lightForest.withAlpha(77),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: forestGreen.withAlpha(25), width: 1),
      ),
      child: TextField(
        controller: controller.otpControllers[index],
        autofocus: index == 0,
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            FocusScope.of(context).nextFocus();
          }
          if (value.isEmpty && index > 0) {
            FocusScope.of(context).previousFocus();
          }
        },
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: forestGreen,
        ),
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: "",
        ),
      ),
    );
  }
}
