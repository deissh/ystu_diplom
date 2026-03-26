import '../../domain/entities/app_settings.dart';

class AppSettingsModel {
  final String theme;
  final bool notificationsEnabled;

  const AppSettingsModel({
    required this.theme,
    required this.notificationsEnabled,
  });

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) => AppSettingsModel(
        theme: json['theme'] as String? ?? 'system',
        notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'theme': theme,
        'notifications_enabled': notificationsEnabled,
      };

  factory AppSettingsModel.fromEntity(AppSettings settings) => AppSettingsModel(
        theme: settings.theme.name,
        notificationsEnabled: settings.notificationsEnabled,
      );

  AppSettings toEntity() => AppSettings(
        theme: AppTheme.values.byName(theme),
        notificationsEnabled: notificationsEnabled,
      );
}
