import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'groups_dao.dart';
import 'schedule_dao.dart';
import 'teachers_dao.dart';

part 'drift_database.g.dart';

/// Таблица занятий.
///
/// Уникальность строки: composite unique constraint на (groupId, startTime, subject).
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

/// Таблица групп: институт → название группы.
///
/// Используется для пикера выбора группы в настройках.
@DataClassName('GroupData')
class Groups extends Table {
  @override
  String get tableName => 'groups';

  TextColumn get instituteName => text()();
  TextColumn get groupName => text()();

  @override
  Set<Column> get primaryKey => {instituteName, groupName};
}

/// Таблица преподавателей: id + имя.
///
/// Используется для пикера выбора преподавателя в настройках.
@DataClassName('TeacherData')
class Teachers extends Table {
  @override
  String get tableName => 'teachers';

  IntColumn get id => integer()();
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [LessonsTable, Groups, Teachers],
  daos: [ScheduleDao, GroupsDao, TeachersDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'ystu_schedule'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_lessons_group_start '
            'ON lessons(group_id, start_time)',
          );
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(groups);
            await m.createTable(teachers);
            // Сбрасываем кеш занятий: старые строки содержат groupId='',
            // что делает их бесполезными при фильтрации по группе.
            await customStatement('DELETE FROM lessons');
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
