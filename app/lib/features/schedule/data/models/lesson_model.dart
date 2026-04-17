import '../../domain/entities/lesson.dart';
import '../../domain/entities/lesson_type.dart';

class LessonModel {
  const LessonModel({
    required this.groupId,
    required this.subject,
    required this.teacher,
    required this.room,
    required this.type,
    required this.startTime,
    required this.endTime,
  });

  final String groupId;
  final String subject;
  final String teacher;
  final String room;

  /// Хранится как Cyrillic-лейбл: 'ЛЕК', 'ПР', 'ЛАБ', '?'.
  final String type;
  final DateTime startTime;
  final DateTime endTime;

  /// Создаёт модель из JSON-объекта занятия API ЯГТУ.
  ///
  /// [groupId] передаётся явно, т.к. в JSON занятия он не присутствует —
  /// он известен из контекста запроса (имя группы).
  factory LessonModel.fromJson(
    Map<String, dynamic> json, {
    required String groupId,
  }) {
    return LessonModel(
      groupId: groupId,
      subject: json['lessonName'] as String,
      teacher: json['teacherName'] as String? ?? '',
      room: json['auditoryName'] as String? ?? '',
      type: _parseLessonType(json).label,
      startTime: DateTime.parse(json['startAt'] as String).toLocal(),
      endTime: DateTime.parse(json['endAt'] as String).toLocal(),
    );
  }

  factory LessonModel.fromEntity(Lesson e) => LessonModel(
        groupId: e.groupId,
        subject: e.subject,
        teacher: e.teacher,
        room: e.room,
        type: e.type.label,
        startTime: e.startTime.toUtc(),
        endTime: e.endTime.toUtc(),
      );

  Lesson toEntity() => Lesson(
        groupId: groupId,
        subject: subject,
        teacher: teacher,
        room: room,
        type: LessonType.fromString(type),
        startTime: startTime,
        endTime: endTime,
      );

  /// Маппинг isLecture/type → LessonType (R6 из требований).
  ///
  /// type — bitmask: 2=поток(лекция), 4=семинар, 8=семинар без потока.
  /// Значения 16, 64, 128, 256, 4096 маппятся в [LessonType.other].
  static LessonType _parseLessonType(Map<String, dynamic> json) {
    if (json['isLecture'] == true) return LessonType.lecture;
    final t = json['type'] as int? ?? 0;
    if (t == 4) return LessonType.practice;
    if (t == 8) return LessonType.lab;
    return LessonType.other;
  }
}
