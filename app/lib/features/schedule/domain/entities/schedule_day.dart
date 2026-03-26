import 'lesson.dart';

class ScheduleDay {
  final DateTime date;
  final List<Lesson> lessons;

  const ScheduleDay({
    required this.date,
    required this.lessons,
  });
}
