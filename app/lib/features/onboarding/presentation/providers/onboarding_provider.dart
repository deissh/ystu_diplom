import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/logger.dart';
import '../../../../core/startup/app_startup_notifier.dart';
import '../../../profile/data/datasources/local/profile_local_datasource.dart';
import '../../../profile/data/models/profile_model.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../schedule/data/models/group_institute_model.dart';
import '../../../schedule/data/models/teacher_model.dart';
import '../../../schedule/domain/entities/selected_subject.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class OnboardingState {
  final ProfileMode? mode;
  final String? selectedGroupName;
  final int? selectedSubgroup;
  final String? displayName;
  final int? selectedTeacherId;
  final String? selectedTeacherName;

  final bool isLoadingList;
  final Failure? listFailure;

  final List<GroupInstituteModel> groups;
  final List<TeacherModel> teachers;

  final bool isSaving;

  const OnboardingState({
    this.mode,
    this.selectedGroupName,
    this.selectedSubgroup,
    this.displayName,
    this.selectedTeacherId,
    this.selectedTeacherName,
    this.isLoadingList = false,
    this.listFailure,
    this.groups = const [],
    this.teachers = const [],
    this.isSaving = false,
  });

  OnboardingState copyWith({
    ProfileMode? mode,
    String? selectedGroupName,
    int? selectedSubgroup,
    String? displayName,
    int? selectedTeacherId,
    String? selectedTeacherName,
    bool? isLoadingList,
    Failure? listFailure,
    bool clearListFailure = false,
    List<GroupInstituteModel>? groups,
    List<TeacherModel>? teachers,
    bool? isSaving,
  }) {
    return OnboardingState(
      mode: mode ?? this.mode,
      selectedGroupName: selectedGroupName ?? this.selectedGroupName,
      selectedSubgroup: selectedSubgroup ?? this.selectedSubgroup,
      displayName: displayName ?? this.displayName,
      selectedTeacherId: selectedTeacherId ?? this.selectedTeacherId,
      selectedTeacherName: selectedTeacherName ?? this.selectedTeacherName,
      isLoadingList: isLoadingList ?? this.isLoadingList,
      listFailure: clearListFailure ? null : (listFailure ?? this.listFailure),
      groups: groups ?? this.groups,
      teachers: teachers ?? this.teachers,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier(this._ref) : super(const OnboardingState());

  final Ref _ref;

  /// Вызывается при выборе режима (страница 0).
  /// Запускает загрузку списка групп или преподавателей.
  Future<void> selectMode(ProfileMode mode) async {
    state = state.copyWith(mode: mode, isLoadingList: true, clearListFailure: true);
    await _loadList(mode);
  }

  Future<void> _loadList(ProfileMode mode) async {
    if (mode == ProfileMode.student) {
      // Показываем тёплый кэш сразу
      final cachedGroups =
          await _ref.read(groupsRepositoryProvider).getGroups();
      state = state.copyWith(groups: cachedGroups);

      // Явный refresh для онбординга
      final failure =
          await _ref.read(groupsRepositoryProvider).refreshGroups();

      if (failure != null && cachedGroups.isEmpty) {
        // Только блокируем, если кэш пустой
        state = state.copyWith(isLoadingList: false, listFailure: failure);
      } else {
        // Тёплый кэш есть — обновляем список после refresh
        if (failure == null) {
          final updated =
              await _ref.read(groupsRepositoryProvider).getGroups();
          state = state.copyWith(
            groups: updated,
            isLoadingList: false,
            clearListFailure: true,
          );
        } else {
          state = state.copyWith(isLoadingList: false, clearListFailure: true);
        }
      }
    } else {
      // Teacher mode
      final cachedTeachers =
          await _ref.read(teachersRepositoryProvider).getTeachers();
      state = state.copyWith(teachers: cachedTeachers);

      final failure =
          await _ref.read(teachersRepositoryProvider).refreshTeachers();

      if (failure != null && cachedTeachers.isEmpty) {
        state = state.copyWith(isLoadingList: false, listFailure: failure);
      } else {
        if (failure == null) {
          final updated =
              await _ref.read(teachersRepositoryProvider).getTeachers();
          state = state.copyWith(
            teachers: updated,
            isLoadingList: false,
            clearListFailure: true,
          );
        } else {
          state = state.copyWith(isLoadingList: false, clearListFailure: true);
        }
      }
    }
  }

  Future<void> retryLoadList() async {
    if (state.mode == null) return;
    state = state.copyWith(isLoadingList: true, clearListFailure: true);
    await _loadList(state.mode!);
  }

  void selectGroup(String groupName) {
    state = state.copyWith(selectedGroupName: groupName);
  }

  void selectSubgroup(int subgroup) {
    state = state.copyWith(selectedSubgroup: subgroup);
  }

  void setDisplayName(String? name) {
    state = state.copyWith(displayName: name?.trim().isEmpty == true ? null : name?.trim());
  }

  void selectTeacher(int teacherId, String teacherName) {
    state = state.copyWith(
      selectedTeacherId: teacherId,
      selectedTeacherName: teacherName,
    );
  }

  Future<void> complete() async {
    if (state.isSaving) return;
    state = state.copyWith(isSaving: true);

    try {
      final profile = _buildProfile();
      if (profile == null) {
        state = state.copyWith(isSaving: false);
        return;
      }

      final datasource = const ProfileLocalDatasource();
      await datasource.completeOnboarding(ProfileModel.fromEntity(profile));

      // Сидируем selectedSubjectProvider перед инвалидацией startup
      final subject = _subjectFromProfile(profile);
      if (subject != null) {
        _ref.read(selectedSubjectProvider.notifier).state = subject;
      }

      // Инвалидируем startup — GoRouter redirect сработает, переходим на /schedule
      _ref.invalidate(appStartupProvider);
    } catch (e) {
      AppLogger.error('Onboarding complete failed: $e');
      state = state.copyWith(isSaving: false);
    }
  }

  Profile? _buildProfile() {
    return switch (state.mode) {
      ProfileMode.student when state.selectedGroupName != null &&
          state.selectedSubgroup != null =>
        Profile(
          mode: ProfileMode.student,
          groupName: state.selectedGroupName,
          subgroup: state.selectedSubgroup,
          displayName: state.displayName,
        ),
      ProfileMode.teacher when state.selectedTeacherId != null =>
        Profile(
          mode: ProfileMode.teacher,
          teacherId: state.selectedTeacherId,
          teacherName: state.selectedTeacherName,
        ),
      _ => null,
    };
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

final onboardingProvider =
    StateNotifierProvider.autoDispose<OnboardingNotifier, OnboardingState>(
  (ref) => OnboardingNotifier(ref),
);
