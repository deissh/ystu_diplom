import '../../../../../core/errors/app_exception.dart';
import '../../models/group_institute_model.dart';
import '../../models/lesson_model.dart';
import '../../models/schedule_day_model.dart';
import '../../models/teacher_model.dart';

/// Парсер JSON-ответов API ЯГТУ в data-модели.
///
/// Все методы выбрасывают [ParseException] при некорректном JSON.
class ScheduleParser {
  const ScheduleParser();

  List<GroupInstituteModel> parseGroups(Map<String, dynamic> json) {
    try {
      final items = json['items'] as List;
      return items
          .cast<Map<String, dynamic>>()
          .map(GroupInstituteModel.fromJson)
          .toList();
    } catch (e) {
      throw ParseException('Не удалось разобрать список групп: $e');
    }
  }

  List<TeacherModel> parseTeachers(Map<String, dynamic> json) {
    try {
      final items = json['items'] as List;
      return items
          .cast<Map<String, dynamic>>()
          .map(TeacherModel.fromJson)
          .toList();
    } catch (e) {
      throw ParseException('Не удалось разобрать список преподавателей: $e');
    }
  }

  List<ScheduleDayModel> parseGroupSchedule(
    Map<String, dynamic> json,
    String groupId,
  ) {
    try {
      return _parseWeeks(json['items'] as List, groupId);
    } on ParseException {
      rethrow;
    } catch (e) {
      throw ParseException('Не удалось разобрать расписание группы: $e');
    }
  }

  List<ScheduleDayModel> parseTeacherSchedule(Map<String, dynamic> json) {
    try {
      final teacherId =
          (json['teacher'] as Map<String, dynamic>)['id'].toString();
      return _parseWeeks(json['items'] as List, teacherId);
    } on ParseException {
      rethrow;
    } catch (e) {
      throw ParseException(
          'Не удалось разобрать расписание преподавателя: $e');
    }
  }

  List<ScheduleDayModel> _parseWeeks(List weeks, String groupId) {
    final days = <ScheduleDayModel>[];

    for (final week in weeks) {
      final weekMap = week as Map<String, dynamic>;
      final weekDays = weekMap['days'] as List;

      for (final day in weekDays) {
        final dayMap = day as Map<String, dynamic>;
        final info = dayMap['info'] as Map<String, dynamic>;
        final weekNumber = info['weekNumber'] as int;
        final date = DateTime.parse(info['date'] as String).toLocal();

        final lessons = (dayMap['lessons'] as List)
            .cast<Map<String, dynamic>>()
            .where((l) => _parityMatches(l['parity'] as int? ?? 0, weekNumber))
            .map((l) => LessonModel.fromJson(l, groupId: groupId))
            .toList();

        if (lessons.isNotEmpty) {
          days.add(ScheduleDayModel(date: date, lessons: lessons));
        }
      }
    }

    return days;
  }

  /// Возвращает true если занятие нужно показывать на данной неделе.
  ///
  /// parity: 0=каждую неделю, 1=нечётная, 2=чётная.
  bool _parityMatches(int parity, int weekNumber) {
    if (parity == 0) return true;
    if (parity == 1) return weekNumber.isOdd;
    if (parity == 2) return weekNumber.isEven;
    return true;
  }
}
