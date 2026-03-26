import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

class SaveSettings {
  final SettingsRepository _repository;

  const SaveSettings(this._repository);

  Future<void> call(AppSettings settings) => _repository.saveSettings(settings);
}
