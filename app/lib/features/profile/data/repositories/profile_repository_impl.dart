import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/logger.dart';
import '../../data/datasources/local/profile_local_datasource.dart';
import '../../data/models/profile_model.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._datasource);

  final ProfileLocalDatasource _datasource;

  @override
  Future<Profile?> getProfile() async {
    try {
      final model = await _datasource.getProfile();
      return model?.toEntity();
    } on CacheException catch (e) {
      AppLogger.error('ProfileRepository.getProfile: ${e.message}');
      return null;
    }
  }

  @override
  Future<void> saveProfile(Profile profile) async {
    try {
      await _datasource.saveProfile(ProfileModel.fromEntity(profile));
    } on CacheException catch (e) {
      AppLogger.error('ProfileRepository.saveProfile: ${e.message}');
      throw CacheFailure(e.message);
    }
  }

  @override
  Future<void> deleteProfile() async {
    try {
      await _datasource.deleteProfile();
    } on CacheException catch (e) {
      AppLogger.error('ProfileRepository.deleteProfile: ${e.message}');
      throw CacheFailure(e.message);
    }
  }
}
