import 'package:flutter/material.dart';
import '../../../theme/theme_controller.dart';
import '../../../theme/app_theme.dart';
import 'setting_list_tile.dart';

/// "Account" settings card: My Profile + Dark Mode toggle.
class AccountSettingsCard extends StatelessWidget {
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color dividerColor;
  final VoidCallback onProfileTap;

  const AccountSettingsCard({
    super.key,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.dividerColor,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            SettingsListTile(
              icon: Icons.person_outline_rounded,
              iconColor: Colors.green,
              title: "My Profile",
              textPrimary: textPrimary,
              onTap: onProfileTap,
              trailing: Icon(Icons.chevron_right_rounded, color: textSecondary),
            ),
            SettingsTileDivider(color: dividerColor),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeController.instance.mode,
              builder: (context, mode, _) {
                final isDarkNow = mode == ThemeMode.dark;
                return SettingsListTile(
                  icon: Icons.dark_mode_outlined,
                  iconColor: const Color(0xFF378ADD),
                  title: "Dark Mode",
                  textPrimary: textPrimary,
                  onTap: () => ThemeController.instance.setDarkMode(!isDarkNow),
                  trailing: Switch.adaptive(
                    value: isDarkNow,
                    onChanged: (v) => ThemeController.instance.setDarkMode(v),
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.forestMid,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
