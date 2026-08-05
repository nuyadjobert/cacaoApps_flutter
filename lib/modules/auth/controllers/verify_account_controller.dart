import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cacao_apps/core/db/user_repository.dart';
import 'package:cacao_apps/core/model/user.model.dart';
import 'package:cacao_apps/core/storage/token_storage.dart';
import '../services/auth_services.dart';
import '../models/verify_otp_result.dart';

enum VerificationStatus { idle, verifying, success, failed }

class VerifyAccountController extends ChangeNotifier {
  final AuthService _auth;
  final String email;
  final _secureStore = TokenStorage();

  final UserRepository _userRepository = UserRepository();

  VerifyAccountController({required AuthService auth, required this.email})
      : _auth = auth;

  final List<TextEditingController> otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  VerificationStatus _verificationStatus = VerificationStatus.idle;
  String _verificationMessage = '';
  VerifyOtpResult? _lastResult;

  VerificationStatus get verificationStatus => _verificationStatus;
  String get verificationMessage => _verificationMessage;

  void resetVerification() {
    _verificationStatus = VerificationStatus.idle;
    _verificationMessage = '';
    _lastResult = null;
    for (final controller in otpControllers) {
      controller.clear();
    }
    notifyListeners();
  }

  Timer? _timer;
  int _secondsLeft = 0;

  int get secondsLeft => _secondsLeft;

  String get timerText {
    int minutes = _secondsLeft ~/ 60;
    int seconds = _secondsLeft % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void startTimer(int seconds) {
    _timer?.cancel();
    _secondsLeft = seconds;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 0) {
        timer.cancel();
        notifyListeners();
      } else {
        _secondsLeft--;
        notifyListeners();
      }
    });
  }

  void disposeTimer() {
    _timer?.cancel();
  }

  String get otp => otpControllers.map((c) => c.text).join().trim();
  bool get isOtpValid => otp.length == 6;
  bool get isNewUserRequired => _lastResult?.status == 'NEW_USER_REQUIRED';

  Future<VerifyOtpResult?> verify() async {
    _verificationMessage = '';
    _lastResult = null;
    _verificationStatus = VerificationStatus.verifying;
    notifyListeners();
    await Future<void>.delayed(Duration.zero);

    if (!isOtpValid) {
      _verificationMessage = 'Please enter the 6-digit code.';
      _verificationStatus = VerificationStatus.failed;
      notifyListeners();
      return null;
    }

    try {
      final result = await _auth.verifyOtp(email: email, otp: otp);

      if (result.status != 'OK') {
        _lastResult = result;
        _verificationMessage = _mapStatusToMessage(result.status);
        _verificationStatus = VerificationStatus.failed;
        notifyListeners();
        return result;
      }

      final token = result.token;
      final userId = result.userId;

      if (token == null || token.isEmpty) {
        _verificationMessage = 'Missing token from server.';
        _verificationStatus = VerificationStatus.failed;
        notifyListeners();
        return result;
      }

      if (userId == null || userId.isEmpty) {
        _verificationMessage = 'Missing userId from server.';
        _verificationStatus = VerificationStatus.failed;
        notifyListeners();
        return result;
      }

      await _secureStore.save(token);
      try {
        await _saveUserLocally(
          userId: userId,
          name: result.name ?? '',
          email: result.email ?? email,
          address: result.address ?? '',
          contactNumber: result.contactNumber ?? '',
        );
      } catch (e) {
        _verificationMessage = 'Failed to save user locally: $e';
        _verificationStatus = VerificationStatus.failed;
        notifyListeners();
        return null;
      }
      _lastResult = result;
      _verificationStatus = VerificationStatus.success;
      _verificationMessage = '';

      notifyListeners();
      return result;
    } catch (e) {
      final status = e.toString().replaceFirst('Exception: ', '');
      _verificationMessage = _mapStatusToMessage(status);
      _verificationStatus = VerificationStatus.failed;
      notifyListeners();
      return null;
    }
  }

  Future<void> requestOtp() async {
    try {
      final result = await _auth.requestOtp(email);

      startTimer(result.expiresInSeconds ?? 200);
    } catch (e) {
      _verificationMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> _saveUserLocally({
    required String userId,
    required String name, // Add this
    required String email,
    required String address,
    required String contactNumber,
  }) async {
    final now = DateTime.now().toIso8601String();

    final localUser = LocalUser(
      userId: userId,
      email: email,
      name: name, // Use the variable, not null!
      address: address,
      contactNumber: contactNumber,
      createdAt: now,
    );

    await _userRepository.upsertUser(localUser);
  }

  String _mapStatusToMessage(String status) {
    switch (status) {
      case 'INVALID_OTP':
        return 'Invalid code. Please try again.';
      case 'OTP_EXPIRED':
        return 'Code expired. Please request a new one.';
      case 'NO_ACTIVE_OTP':
        return 'No active code. Request a new OTP.';
      case 'ACCOUNT_DELETED':
        return 'This account was deleted.';
      case 'NEW_USER_REQUIRED':
        return 'No account found. Please register.';
      default:
        return 'Verification failed: $status';
    }
  }

  @override
  void dispose() {
    for (final c in otpControllers) {
      c.dispose();
    }
    super.dispose();
  }
}
