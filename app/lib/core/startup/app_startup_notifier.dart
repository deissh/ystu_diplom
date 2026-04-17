import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/profile/data/models/profile_model.dart';
import '../../features/profile/domain/entities/profile.dart';

/// Данные, загружаемые при старте приложения из SharedPreferences.
class AppStartupData {
  final bool onboardingComplete;
  final Profile? profile;

  const AppStartupData({
    required this.onboardingComplete,
    required this.profile,
  });
}

/// Загружает флаг онбординга и профиль пользователя при запуске.
///
/// Используется GoRouter redirect guard и app.dart для инициализации
/// [selectedSubjectProvider] до рендера первого экрана.
class AppStartupNotifier extends AsyncNotifier<AppStartupData> {
  @override
  Future<AppStartupData> build() async {
    final prefs = await SharedPreferences.getInstance();
    final flag = prefs.getBool('onboarding_complete') ?? false;
    final profileJson = prefs.getString('profile');
    Profile? profile;
    if (profileJson != null) {
      try {
        profile = ProfileModel.fromJson(
          jsonDecode(profileJson) as Map<String, dynamic>,
        ).toEntity();
      } catch (_) {
        // Повреждённый профиль — сбрасываем, онбординг повторится
        profile = null;
      }
    }
    return AppStartupData(onboardingComplete: flag, profile: profile);
  }
}

final appStartupProvider =
    AsyncNotifierProvider<AppStartupNotifier, AppStartupData>(
  AppStartupNotifier.new,
);
