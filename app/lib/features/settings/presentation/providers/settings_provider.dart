import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/logger.dart';
import '../../../../core/startup/app_startup_notifier.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../data/datasources/local/settings_local_datasource.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/use_cases/get_settings.dart';
import '../../domain/use_cases/save_settings.dart';

// ── Инфраструктурные провайдеры ───────────────────────────────────────────────

final settingsLocalDatasourceProvider =
    Provider<SettingsLocalDatasource>((_) => const SettingsLocalDatasource());

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(ref.watch(settingsLocalDatasourceProvider));
});

final getSettingsProvider = Provider<GetSettings>((ref) {
  return GetSettings(ref.watch(settingsRepositoryProvider));
});

final saveSettingsProvider = Provider<SaveSettings>((ref) {
  return SaveSettings(ref.watch(settingsRepositoryProvider));
});

// ── Notifier ──────────────────────────────────────────────────────────────────

/// Провайдер настроек приложения.
///
/// [build] загружает настройки из SharedPreferences.
/// [setTheme] меняет тему и сохраняет её немедленно.
/// [resetAllData] очищает все данные и настройки, затем
/// инвалидирует [appStartupProvider], что тригерит редирект на онбординг.
class SettingsNotifier extends AsyncNotifier<AppSettings> {
  bool _isResetting = false;

  @override
  Future<AppSettings> build() => ref.watch(getSettingsProvider).call();

  Future<void> setTheme(AppTheme theme) async {
    final current = state.valueOrNull ?? AppSettings.defaults;
    final updated = AppSettings(
      theme: theme,
      notificationsEnabled: current.notificationsEnabled,
    );
    state = AsyncValue.data(updated);
    try {
      await ref.read(saveSettingsProvider).call(updated);
    } on CacheFailure catch (e) {
      AppLogger.error('SettingsNotifier.setTheme: ${e.message}');
      // Откат state при ошибке сохранения
      state = AsyncValue.data(current);
    } catch (e) {
      AppLogger.error('SettingsNotifier.setTheme: $e');
      state = AsyncValue.data(current);
    }
  }

  /// Атомарный сброс всех данных приложения.
  ///
  /// Порядок шагов намеренный — см. план:
  /// docs/plans/2026-04-18-001-feat-settings-theme-reset-plan.md
  ///
  /// Бросает исключение при ошибке — вызывающий код должен показать
  /// сообщение об ошибке вместо редиректа.
  Future<void> resetAllData() async {
    if (_isResetting) return;
    _isResetting = true;
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1–3. Очищаем SharedPreferences
      await prefs.remove('profile');
      await prefs.remove('onboarding_complete');
      await prefs.remove('app_settings');

      // 4. Очищаем Drift
      await ref.read(databaseProvider).clearAllData();

      // 5. Сбрасываем selectedSubjectProvider
      ref.read(selectedSubjectProvider.notifier).state = null;

      // 6. Инвалидируем profileNotifierProvider
      ref.invalidate(profileNotifierProvider);

      // 7. Инвалидируем себя
      ref.invalidate(settingsNotifierProvider);

      // 8. Последним — тригерит RouterNotifier → GoRouter → /onboarding
      ref.invalidate(appStartupProvider);
    } finally {
      _isResetting = false;
    }
  }
}

final settingsNotifierProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
