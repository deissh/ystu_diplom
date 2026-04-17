import '../../../../core/errors/failure.dart';
import '../../data/models/teacher_model.dart';

abstract interface class TeachersRepository {
  Future<List<TeacherModel>> getTeachers();

  /// Явный fetch из API с propagation ошибки.
  ///
  /// Возвращает null при успехе, [Failure] при ошибке сети/парсинга.
  /// Используется в онбординге для отображения состояния Retry.
  Future<Failure?> refreshTeachers();
}
