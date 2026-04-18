import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/errors/app_exception.dart';
import '../../models/app_settings_model.dart';
import '../../../domain/entities/app_settings.dart';

const _kAppSettings = 'app_settings';

class SettingsLocalDatasource {
  const SettingsLocalDatasource();

  Future<AppSettings> getSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_kAppSettings);
      if (json == null) return AppSettings.defaults;
      return AppSettingsModel.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      ).toEntity();
    } catch (e) {
      // Повреждённые настройки — возвращаем defaults, не крашим приложение
      return AppSettings.defaults;
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(AppSettingsModel.fromEntity(settings).toJson());
      await prefs.setString(_kAppSettings, json);
    } catch (e) {
      throw CacheException('Не удалось сохранить настройки: $e');
    }
  }

  Future<void> clearSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kAppSettings);
    } catch (e) {
      throw CacheException('Не удалось очистить настройки: $e');
    }
  }
}
