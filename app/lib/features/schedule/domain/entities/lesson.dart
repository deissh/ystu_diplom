class Lesson {
  final String subject;
  final String teacher;
  final String room;
  final String type;
  final DateTime startTime;
  final DateTime endTime;

  const Lesson({
    required this.subject,
    required this.teacher,
    required this.room,
    required this.type,
    required this.startTime,
    required this.endTime,
  });
}
