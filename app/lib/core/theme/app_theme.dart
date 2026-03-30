import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Provides [ThemeData] for light and dark modes.
///
/// Named [AppThemeData] to avoid collision with the [AppTheme] enum defined
/// in `features/settings/domain/entities/app_settings.dart`.
///
/// Usage in MaterialApp.router:
///   theme: AppThemeData.light(),
///   darkTheme: AppThemeData.dark(),
///   themeMode: themeMode,
class AppThemeData {
  const AppThemeData._();

  static ThemeData light() => _build(
        brightness: Brightness.light,
        bg: AppColors.bgLight,
        surface: AppColors.surfaceLight,
        label: AppColors.labelLight,
        accent: AppColors.accentLight,
        error: AppColors.redLight,
        separator: AppColors.separatorLight,
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        bg: AppColors.bgDark,
        surface: AppColors.surfaceDark,
        label: AppColors.labelDark,
        accent: AppColors.accentDark,
        error: AppColors.redDark,
        separator: AppColors.separatorDark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color bg,
    required Color surface,
    required Color label,
    required Color accent,
    required Color error,
    required Color separator,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: accent,
        onPrimary: Colors.white,
        secondary: accent,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: label,
        error: error,
        onError: Colors.white,
      ),
      cardColor: surface,
      dividerColor: separator,
      textTheme: TextTheme(
        displayLarge: AppTextStyles.screenTitle.copyWith(color: label),
        titleMedium: AppTextStyles.subjectName.copyWith(color: label),
        bodyMedium: AppTextStyles.meta.copyWith(color: label),
        labelSmall: AppTextStyles.badge.copyWith(color: label),
      ),
      // Disable default splash / highlight effects for tap feedback.
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }
}
