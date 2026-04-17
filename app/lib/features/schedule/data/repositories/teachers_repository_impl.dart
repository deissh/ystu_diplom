import '../../../../core/errors/app_exception.dart';
import '../../../../core/logger.dart';
import '../../data/datasources/local/teachers_dao.dart';
import '../../data/datasources/remote/api_client.dart';
import '../../data/datasources/remote/parser.dart';
import '../../data/models/teacher_model.dart';
import '../../domain/repositories/teachers_repository.dart';

class TeachersRepositoryImpl implements TeachersRepository {
  const TeachersRepositoryImpl(this._dao, this._apiClient, this._parser);

  final TeachersDao _dao;
  final ApiClient _apiClient;
  final ScheduleParser _parser;

  @override
  Future<List<TeacherModel>> getTeachers() async {
    final cached = await _dao.getAllTeachers();
    _sync();
    return cached
        .map((row) => TeacherModel(id: row.id, name: row.name))
        .toList();
  }

  Future<void> _sync() async {
    try {
      final json = await _apiClient.fetchTeachers();
      final teacherModels = _parser.parseTeachers(json);
      await _dao.upsertTeachers(teacherModels);
    } on NetworkException catch (e) {
      AppLogger.warning('Teachers sync failed (network): ${e.message}');
    } on ParseException catch (e) {
      AppLogger.error('Teachers sync failed (parse): ${e.message}');
    }
  }
}
