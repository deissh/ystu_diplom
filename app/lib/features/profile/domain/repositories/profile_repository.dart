import '../entities/profile.dart';

abstract interface class ProfileRepository {
  Future<Profile?> getProfile();
  Future<void> saveProfile(Profile profile);
  Future<void> deleteProfile();
}
