import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/logger.dart';
import '../../data/datasources/local/drift_database.dart';
import '../../data/datasources/local/groups_dao.dart';
import '../../data/datasources/remote/api_client.dart';
import '../../data/datasources/remote/parser.dart';
import '../../data/models/group_institute_model.dart';
import '../../domain/repositories/groups_repository.dart';

class GroupsRepositoryImpl implements GroupsRepository {
  const GroupsRepositoryImpl(this._dao, this._apiClient, this._parser);

  final GroupsDao _dao;
  final ApiClient _apiClient;
  final ScheduleParser _parser;

  @override
  Future<List<GroupInstituteModel>> getGroups() async {
    final cached = await _dao.getAllGroups();
    // Background sync (fire and forget)
    _sync();
    return _toModels(cached);
  }

  @override
  Stream<List<GroupInstituteModel>> watchGroups() {
    _sync();
    return _dao.watchAllGroups().map(_toModels);
  }

  @override
  Future<Failure?> refreshGroups() async {
    try {
      final json = await _apiClient.fetchGroups();
      final institutes = _parser.parseGroups(json);
      await _dao.upsertGroups(institutes);
      return null;
    } on NetworkException catch (e) {
      AppLogger.warning('Groups refresh failed (network): ${e.message}');
      return NetworkFailure(e.message);
    } on ParseException catch (e) {
      AppLogger.error('Groups refresh failed (parse): ${e.message}');
      return ParseFailure(e.message);
    }
  }

  Future<void> _sync() async {
    try {
      final json = await _apiClient.fetchGroups();
      final institutes = _parser.parseGroups(json);
      await _dao.upsertGroups(institutes);
    } on NetworkException catch (e) {
      AppLogger.warning('Groups sync failed (network): ${e.message}');
    } on ParseException catch (e) {
      AppLogger.error('Groups sync failed (parse): ${e.message}');
    }
  }

  List<GroupInstituteModel> _toModels(List<GroupData> rows) {
    final Map<String, List<String>> byInstitute = {};
    for (final row in rows) {
      byInstitute.putIfAbsent(row.instituteName, () => []).add(row.groupName);
    }
    return byInstitute.entries
        .map((e) =>
            GroupInstituteModel(instituteName: e.key, groups: e.value))
        .toList();
  }
}
