import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cacao_apps/modules/auth/login_factory.dart';
import '../controllers/settings_controller.dart';
import '../../history/controllers/history_controller.dart';
import '../../../theme/app_theme.dart';
import '../../../core/model/user.model.dart';
import '../widgets/profile_hero_card.dart';
import '../widgets/settings_section_label.dart';
import '../widgets/account_settings.dart';
import '../widgets/support_settings.dart';
import '../widgets/logout_button.dart';
import '../widgets/profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsController _controller = SettingsController();
  final HistoryController _historyController = HistoryController();
  LocalUser? currentUser;

  File? _profileImage;

  int _overallScans = 0;
  String _farmStatus = "Loading...";
  int _diseasesScanned = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadFarmStats();
  }

  Future<void> _loadUser() async {
    currentUser = await _controller.getCurrentUser();
    setState(() {});
  }

  Future<void> _loadFarmStats() async {
    final stats = await _historyController.getFarmStats();
    if (!mounted) return;
    setState(() {
      _overallScans = stats['overallScans'];
      _farmStatus = stats['farmStatus'];
      _diseasesScanned = stats['diseasesScanned'];
    });
  }

  Future<void> _navigateToProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserProfileScreen()),
    );
    if (!mounted) return;
    _loadUser();
  }

  Future<void> _handleLogoutConfirmed() async {
    await _controller.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => buildLoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bg = isDark ? AppColors.nightBg : AppColors.creamBg;
    final Color appBarBg = isDark ? AppColors.nightBg : Colors.white;
    final Color cardBg = isDark ? AppColors.nightCard : AppColors.creamCard;
    final Color textPrimary = isDark ? Colors.white : AppColors.forestDark;
    final Color textSecondary = isDark ? Colors.white60 : Colors.grey;
    final Color textMuted = isDark ? Colors.white38 : Colors.grey[500]!;
    final Color divider =
        isDark ? AppColors.nightDivider : Colors.grey.shade200;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: bg,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: appBarBg,
          systemOverlayStyle:
              isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          elevation: 0,
          centerTitle: true,
          title: Text(
            "Settings",
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  ProfileHeroCard(
                    cardBg: cardBg,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    currentUser: currentUser,
                    profileImage: _profileImage,
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),

                padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SettingsSectionLabel(label: "Account", textMuted: textMuted),
                    const SizedBox(height: 8),
                    AccountSettingsCard(
                      cardBg: cardBg,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      dividerColor: divider,
                      onProfileTap: _navigateToProfile,
                    ),
                    const SizedBox(height: 24),
                    SettingsSectionLabel(label: "Support", textMuted: textMuted),
                    const SizedBox(height: 8),
                    SupportSettingsCard(
                      cardBg: cardBg,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      dividerColor: divider,
                    ),
                    const SizedBox(height: 24),
                    LogoutButton(
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onConfirmed: _handleLogoutConfirmed,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}