import 'dart:async';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/logger.dart';
import '../../data/datasources/local/drift_database.dart';
import '../../data/datasources/local/schedule_dao.dart';
import '../../data/datasources/remote/api_client.dart';
import '../../data/datasources/remote/parser.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/lesson_type.dart';
import '../../domain/entities/schedule_day.dart';
import '../../domain/entities/selected_subject.dart';
import '../../domain/repositories/schedule_repository.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  const ScheduleRepositoryImpl(this._dao, this._apiClient, this._parser);

  final ScheduleDao _dao;
  final ApiClient _apiClient;
  final ScheduleParser _parser;

  @override
  Stream<List<ScheduleDay>> watchSchedule({
    required SelectedSubject subject,
    required DateTime from,
    required DateTime to,
  }) {
    final subjectId = _subjectId(subject);
    unawaited(_sync(subject));
    return _dao
        .watchLessons(groupId: subjectId, from: from, to: to)
        .map(_toScheduleDays);
  }

  /// Уникальный строковый ключ субъекта для хранения в Drift.
  ///
  /// Группа: имя группы ('ЦИС-47').
  /// Преподаватель: строка-ID вида '42' (parser использует тот же ключ).
  String _subjectId(SelectedSubject subject) => switch (subject) {
        GroupSubject(groupName: final g) => g,
        TeacherSubject(teacherId: final id) => id.toString(),
      };

  Future<void> _sync(SelectedSubject subject) async {
    try {
      switch (subject) {
        case GroupSubject(groupName: final g):
          final json = await _apiClient.fetchGroupSchedule(g);
          final dayModels = _parser.parseGroupSchedule(json, g);
          final lessons = dayModels.expand((d) => d.lessons).toList();
          await _dao.insertLessons(lessons);
        case TeacherSubject(teacherId: final id):
          final json = await _apiClient.fetchTeacherSchedule(id);
          // parseTeacherSchedule использует id.toString() как groupId — тот же ключ.
          final dayModels = _parser.parseTeacherSchedule(json);
          final lessons = dayModels.expand((d) => d.lessons).toList();
          await _dao.insertLessons(lessons);
      }
    } on NetworkException catch (e) {
      AppLogger.warning('Schedule sync failed (network): ${e.message}');
    } on ParseException catch (e) {
      AppLogger.error('Schedule sync failed (parse): ${e.message}');
    }
  }

  List<ScheduleDay> _toScheduleDays(List<LessonsTableData> rows) {
    final Map<DateTime, List<Lesson>> byDay = {};
    for (final row in rows) {
      final day = DateTime(
        row.startTime.year,
        row.startTime.month,
        row.startTime.day,
      );
      byDay.putIfAbsent(day, () => []).add(Lesson(
        groupId: row.groupId,
        subject: row.subject,
        teacher: row.teacher,
        room: row.room,
        type: LessonType.fromString(row.type),
        startTime: row.startTime,
        endTime: row.endTime,
      ));
    }
    return byDay.entries
        .map((e) => ScheduleDay(date: e.key, lessons: e.value))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
}
