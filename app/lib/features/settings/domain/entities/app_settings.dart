import 'package:flutter/material.dart';

enum AppTheme { system, light, dark }

extension AppThemeX on AppTheme {
  ThemeMode toThemeMode() => switch (this) {
        AppTheme.system => ThemeMode.system,
        AppTheme.light => ThemeMode.light,
        AppTheme.dark => ThemeMode.dark,
      };
}

class AppSettings {
  final AppTheme theme;
  final bool notificationsEnabled;

  const AppSettings({
    required this.theme,
    required this.notificationsEnabled,
  });

  static const defaults = AppSettings(
    theme: AppTheme.system,
    notificationsEnabled: true,
  );
}
