import 'lesson_type.dart';

class Lesson {
  const Lesson({
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
  final LessonType type;
  final DateTime startTime;
  final DateTime endTime;
}
