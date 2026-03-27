import 'package:drift/drift.dart';

import '../../../data/models/lesson_model.dart';
import '../../../domain/entities/lesson.dart';
import 'drift_database.dart';

part 'schedule_dao.g.dart';

@DriftAccessor(tables: [LessonsTable])
class ScheduleDao extends DatabaseAccessor<AppDatabase>
    with _$ScheduleDaoMixin {
  ScheduleDao(super.db);

  /// Реактивный стрим всех занятий.
  ///
  /// TODO: параметризовать по groupId + date range когда будет
  /// реализован профиль пользователя.
  Stream<List<LessonsTableData>> watchAllLessons() =>
      select(lessonsTable).watch();

  /// Upsert-вставка занятий.
  ///
  /// Использует insertOnConflictUpdate (не insertOrReplace):
  /// не удаляет строку, обновляет только изменившиеся поля
  /// при конфликте uniqueKeys.
  Future<void> insertLessons(List<Lesson> lessons) => batch(
        (b) => b.insertAllOnConflictUpdate(
          lessonsTable,
          lessons.map(_toCompanion).toList(),
        ),
      );

  LessonsTableCompanion _toCompanion(Lesson lesson) {
    final m = LessonModel.fromEntity(lesson);
    return LessonsTableCompanion.insert(
      groupId: '',
      subject: m.subject,
      teacher: m.teacher,
      room: m.room,
      type: m.type,
      startTime: m.startTime,
      endTime: m.endTime,
    );
  }
}
