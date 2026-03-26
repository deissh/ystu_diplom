enum AppTheme { system, light, dark }

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
