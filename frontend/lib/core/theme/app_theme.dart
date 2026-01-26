import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bgTop,
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.dark,
        primary: AppColors.borderCyan,
        secondary: AppColors.purple,
        surface: AppColors.surface1,
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          height: 1.3,
        ),
        bodySmall: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          height: 1.3,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.outlineLow,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 20,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface1,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.borderCyan,
        unselectedItemColor: AppColors.textMuted,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
    );
  }
}
