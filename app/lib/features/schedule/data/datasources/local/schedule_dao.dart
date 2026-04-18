import 'package:drift/drift.dart';

import '../../models/lesson_model.dart';
import 'drift_database.dart';

part 'schedule_dao.g.dart';

@DriftAccessor(tables: [LessonsTable])
class ScheduleDao extends DatabaseAccessor<AppDatabase>
    with _$ScheduleDaoMixin {
  ScheduleDao(super.db);

  /// Реактивный стрим занятий для [groupId] в диапазоне [from]..[to].
  Stream<List<LessonsTableData>> watchLessons({
    required String groupId,
    required DateTime from,
    required DateTime to,
  }) =>
      (select(lessonsTable)
            ..where(
              (t) =>
                  t.groupId.equals(groupId) &
                  t.startTime.isBiggerOrEqualValue(from) &
                  t.startTime.isSmallerOrEqualValue(to),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
          .watch();

  /// Разовая выборка занятий для [groupId] в диапазоне [from]..[to].
  Future<List<LessonsTableData>> getLessons({
    required String groupId,
    required DateTime from,
    required DateTime to,
  }) =>
      (select(lessonsTable)
            ..where(
              (t) =>
                  t.groupId.equals(groupId) &
                  t.startTime.isBiggerOrEqualValue(from) &
                  t.startTime.isSmallerOrEqualValue(to),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
          .get();

  /// Upsert-вставка занятий из data-моделей.
  ///
  /// Использует insertOnConflictUpdate: не удаляет строку, обновляет только
  /// изменившиеся поля при конфликте uniqueKeys.
  Future<void> insertLessons(List<LessonModel> models) => batch(
        (b) => b.insertAll(
          lessonsTable,
          models.map(_toCompanion).toList(),
          mode: InsertMode.insertOrReplace,
        ),
      );

  LessonsTableCompanion _toCompanion(LessonModel m) =>
      LessonsTableCompanion.insert(
        groupId: m.groupId,
        subject: m.subject,
        teacher: m.teacher,
        room: m.room,
        type: m.type,
        startTime: m.startTime,
        endTime: m.endTime,
      );
}
