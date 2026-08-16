import 'package:flutter/material.dart';
import '../models/login_model.dart';
import '../services/auth_services.dart';
import '../views/verify_account_screen.dart';

class LoginController {
  final LoginModel model;
  final AuthService service;

  final TextEditingController emailController = TextEditingController();
  late final VoidCallback _emailListener;

  LoginController({
    required this.model,
    required this.service,
  }) {
    _emailListener = () {
      model.email = emailController.text;
      model.emailError = null;
    };
    emailController.addListener(_emailListener);
  }

  void dispose() {
    emailController.dispose(); 
  }

  bool validate() {
    final e = emailController.text.trim();
    model.email = e;

    if (e.isEmpty) {
      model.emailError = 'Email is required';
      return false;
    }

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(e)) {
      model.emailError = 'Enter a valid email';
      return false;
    }

    model.emailError = null;
    return true;
  }

  Future<void> onContinue(BuildContext context, VoidCallback refresh) async {
    if (!validate()) {
      refresh();
      return;
    }

    final email = model.email.trim().toLowerCase();

    try {
      model.isLoading = true;
      refresh();

      final result = await service.requestOtp(email);

      if (!context.mounted) return;
      
      if (result.status == 'OTP_SENT') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyAccountScreen(email: email),
          ),
        );
        return;
      }

      if (!context.mounted) return;
      
      if (result.status == 'COOLDOWN') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please wait ${result.retryAfterSeconds}s then try again.')),
        );
        return;
      }

      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request failed: ${result.status}')),
      );
    } catch (e) {
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      model.isLoading = false;
      refresh();
    }
  }
}