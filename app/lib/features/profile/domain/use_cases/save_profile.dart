import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

class SaveProfile {
  final ProfileRepository _repository;

  const SaveProfile(this._repository);

  Future<void> call(Profile profile) => _repository.saveProfile(profile);
}
