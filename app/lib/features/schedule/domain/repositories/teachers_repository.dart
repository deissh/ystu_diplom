import '../../data/models/teacher_model.dart';

abstract interface class TeachersRepository {
  Future<List<TeacherModel>> getTeachers();
}
