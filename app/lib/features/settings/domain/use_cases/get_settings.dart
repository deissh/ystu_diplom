import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

class GetSettings {
  final SettingsRepository _repository;

  const GetSettings(this._repository);

  Future<AppSettings> call() => _repository.getSettings();
}
