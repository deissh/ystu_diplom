import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl();

  @override
  Future<Profile?> getProfile() async {
    // TODO: load from local storage
    return null;
  }

  @override
  Future<void> saveProfile(Profile profile) async {
    // TODO: persist to local storage
  }

  @override
  Future<void> deleteProfile() async {
    // TODO: remove from local storage
  }
}
