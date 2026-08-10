import 'package:flutter/material.dart';

class AppColors {
  static const Color forestDark = Color(0xFF1B3022);
  static const Color forestMid = Color(0xFF2D6A4F);
  static const Color forestLight = Color(0xFF52B788);

  static const Color creamBg = Color(0xFFF9FBF9);
  static const Color creamCard = Colors.white;

  static const Color nightBg = Color(0xFF0F1B14); 
  static const Color nightCard = Color(0xFF16241C); 
  static const Color nightDivider = Color(0xFF213024);
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.creamBg,
      primaryColor: AppColors.forestMid,
      colorScheme: ColorScheme.light(
        primary: AppColors.forestMid,
        secondary: AppColors.forestLight,
        surface: AppColors.creamCard,
        onSurface: AppColors.forestDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.forestDark,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.forestMid
              : Colors.grey,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.forestMid
              : Colors.grey.shade300,
        ),
      ),
      dividerColor: const Color(0xFFE4E9E4),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.nightBg,
      primaryColor: AppColors.forestLight,
      colorScheme: ColorScheme.dark(
        primary: AppColors.forestLight,
        secondary: AppColors.forestMid,
        surface: AppColors.nightCard,
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.forestLight
              : Colors.grey,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.forestMid
              : Colors.grey.shade800,
        ),
      ),
      dividerColor: AppColors.nightDivider,
    );
  }
}