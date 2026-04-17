import 'package:drift/drift.dart';

import '../../models/teacher_model.dart';
import 'drift_database.dart';

part 'teachers_dao.g.dart';

@DriftAccessor(tables: [Teachers])
class TeachersDao extends DatabaseAccessor<AppDatabase>
    with _$TeachersDaoMixin {
  TeachersDao(super.db);

  Future<List<TeacherData>> getAllTeachers() => select(teachers).get();

  Future<void> upsertTeachers(List<TeacherModel> teacherModels) => batch(
        (b) => b.insertAllOnConflictUpdate(
          teachers,
          teacherModels
              .map(
                (t) => TeachersCompanion(
                  id: Value(t.id),
                  name: Value(t.name),
                ),
              )
              .toList(),
        ),
      );
}
