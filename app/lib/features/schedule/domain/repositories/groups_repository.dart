import '../../../../core/errors/failure.dart';
import '../../data/models/group_institute_model.dart';

abstract interface class GroupsRepository {
  Future<List<GroupInstituteModel>> getGroups();
  Stream<List<GroupInstituteModel>> watchGroups();

  /// Явный fetch из API с propagation ошибки.
  ///
  /// Возвращает null при успехе, [Failure] при ошибке сети/парсинга.
  /// Используется в онбординге для отображения состояния Retry.
  Future<Failure?> refreshGroups();
}
