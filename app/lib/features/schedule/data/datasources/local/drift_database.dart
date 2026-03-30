import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'schedule_dao.dart';

part 'drift_database.g.dart';

/// Таблица занятий в локальной БД.
///
/// Primary key отсутствует явно — Drift использует rowid автоматически.
/// Уникальность строки определяется composite unique constraint
/// [uniqueKeys] на (groupId, startTime, subject), что позволяет
/// корректно работать insertOnConflictUpdate при синхронизации.
class LessonsTable extends Table {
  @override
  String get tableName => 'lessons';

  TextColumn get groupId => text()();
  TextColumn get subject => text()();
  TextColumn get teacher => text()();
  TextColumn get room => text()();
  TextColumn get type => text()();

  /// Хранится как INTEGER (milliseconds since epoch, UTC).
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {groupId, startTime, subject},
      ];
}

@DriftDatabase(tables: [LessonsTable], daos: [ScheduleDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'ystu_schedule'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        beforeOpen: (details) async {
          if (details.wasCreated) {
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_lessons_group_start '
              'ON lessons(group_id, start_time)',
            );
          }
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

}
