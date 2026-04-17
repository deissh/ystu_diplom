import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/logger.dart';
import '../../../../core/startup/app_startup_notifier.dart';
import '../../../schedule/domain/entities/selected_subject.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../data/datasources/local/profile_local_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/use_cases/get_profile.dart';
import '../../domain/use_cases/save_profile.dart';

// ── Инфраструктурные провайдеры ───────────────────────────────────────────────

final profileLocalDatasourceProvider =
    Provider<ProfileLocalDatasource>((_) => const ProfileLocalDatasource());

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(ref.watch(profileLocalDatasourceProvider));
});

final getProfileProvider = Provider<GetProfile>((ref) {
  return GetProfile(ref.watch(profileRepositoryProvider));
});

final saveProfileProvider = Provider<SaveProfile>((ref) {
  return SaveProfile(ref.watch(profileRepositoryProvider));
});

// ── Notifier ──────────────────────────────────────────────────────────────────

/// Провайдер текущего профиля пользователя.
///
/// [build] загружает профиль из SharedPreferences.
/// [save] сохраняет профиль и обновляет [selectedSubjectProvider].
class ProfileNotifier extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() => ref.watch(getProfileProvider).call();

  Future<void> save(Profile profile) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(saveProfileProvider).call(profile);

      // Обновляем selectedSubjectProvider — расписание реагирует немедленно
      final subject = _subjectFromProfile(profile);
      ref.read(selectedSubjectProvider.notifier).state = subject;

      // Пересчёт startup state чтобы GoRouter не редиректил обратно
      ref.invalidate(appStartupProvider);

      state = AsyncValue.data(profile);
    } on CacheFailure catch (e) {
      AppLogger.error('ProfileNotifier.save: ${e.message}');
      state = AsyncValue.error(e, StackTrace.current);
    } catch (e, st) {
      AppLogger.error('ProfileNotifier.save: $e');
      state = AsyncValue.error(e, st);
    }
  }

  SelectedSubject? _subjectFromProfile(Profile profile) {
    return switch (profile.mode) {
      ProfileMode.student => profile.groupName != null
          ? GroupSubject(profile.groupName!)
          : null,
      ProfileMode.teacher =>
        profile.teacherId != null && profile.teacherName != null
            ? TeacherSubject(profile.teacherId!, profile.teacherName!)
            : null,
    };
  }
}

final profileNotifierProvider =
    AsyncNotifierProvider<ProfileNotifier, Profile?>(ProfileNotifier.new);
