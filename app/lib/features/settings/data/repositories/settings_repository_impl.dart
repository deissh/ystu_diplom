import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl();

  @override
  Future<AppSettings> getSettings() async {
    // TODO: load from SharedPreferences
    return AppSettings.defaults;
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    // TODO: persist to SharedPreferences
  }
}
