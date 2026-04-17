import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/errors/app_exception.dart';
import '../../models/profile_model.dart';

/// SharedPreferences ключи.
const _kProfile = 'profile';
const _kOnboardingComplete = 'onboarding_complete';

class ProfileLocalDatasource {
  const ProfileLocalDatasource();

  Future<ProfileModel?> getProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_kProfile);
      if (json == null) return null;
      return ProfileModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (e) {
      throw CacheException('Не удалось прочитать профиль: $e');
    }
  }

  Future<void> saveProfile(ProfileModel model) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kProfile, jsonEncode(model.toJson()));
    } catch (e) {
      throw CacheException('Не удалось сохранить профиль: $e');
    }
  }

  Future<void> deleteProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kProfile);
    } catch (e) {
      throw CacheException('Не удалось удалить профиль: $e');
    }
  }

  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboardingComplete) ?? false;
  }

  /// Сохраняет профиль, затем устанавливает флаг завершения онбординга.
  ///
  /// ВАЖНО: порядок записи намеренный — профиль первым.
  /// Если приложение упадёт между записями, флаг останется false и
  /// пользователь пройдёт онбординг повторно (recoverable).
  Future<void> completeOnboarding(ProfileModel model) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kProfile, jsonEncode(model.toJson()));
      await prefs.setBool(_kOnboardingComplete, true);
    } catch (e) {
      throw CacheException('Не удалось завершить онбординг: $e');
    }
  }
}
