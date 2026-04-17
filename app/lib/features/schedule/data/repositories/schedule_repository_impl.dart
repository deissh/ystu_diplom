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
import '../../domain/repositories/schedule_repository.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  const ScheduleRepositoryImpl(this._dao, this._apiClient, this._parser);

  final ScheduleDao _dao;
  final ApiClient _apiClient;
  final ScheduleParser _parser;

  @override
  Future<List<ScheduleDay>> getSchedule({
    required String groupId,
    required DateTime from,
    required DateTime to,
  }) async {
    if (groupId.isEmpty) return [];
    final rows = await _dao.getLessons(groupId: groupId, from: from, to: to);
    unawaited(_sync(groupId));
    return _toScheduleDays(rows);
  }

  @override
  Stream<List<ScheduleDay>> watchSchedule({
    required String groupId,
    required DateTime from,
    required DateTime to,
  }) {
    if (groupId.isEmpty) return Stream.value([]);
    unawaited(_sync(groupId));
    return _dao
        .watchLessons(groupId: groupId, from: from, to: to)
        .map(_toScheduleDays);
  }

  /// Фоновая синхронизация: получает расписание из API и сохраняет в Drift.
  ///
  /// Ошибки только логируются — они не прерывают Drift-стрим.
  Future<void> _sync(String groupId) async {
    try {
      final json = await _apiClient.fetchGroupSchedule(groupId);
      final dayModels = _parser.parseGroupSchedule(json, groupId);
      final lessons = dayModels.expand((d) => d.lessons).toList();
      await _dao.insertLessons(lessons);
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
