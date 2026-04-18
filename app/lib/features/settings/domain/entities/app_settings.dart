import 'package:flutter/cupertino.dart';

enum AppTheme { system, light, dark }

extension AppThemeX on AppTheme {
  /// Returns the [Brightness] for [CupertinoApp.theme].
  /// [AppTheme.system] returns null — CupertinoApp follows the device setting.
  Brightness? toBrightness() => switch (this) {
        AppTheme.system => null,
        AppTheme.light => Brightness.light,
        AppTheme.dark => Brightness.dark,
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
