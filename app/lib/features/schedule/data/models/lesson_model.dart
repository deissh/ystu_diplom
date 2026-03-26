import '../../domain/entities/lesson.dart';

class LessonModel {
  final String subject;
  final String teacher;
  final String room;
  final String type;
  final DateTime startTime;
  final DateTime endTime;

  const LessonModel({
    required this.subject,
    required this.teacher,
    required this.room,
    required this.type,
    required this.startTime,
    required this.endTime,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      subject: json['subject'] as String,
      teacher: json['teacher'] as String,
      room: json['room'] as String,
      type: json['type'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
    );
  }

  Lesson toEntity() => Lesson(
        subject: subject,
        teacher: teacher,
        room: room,
        type: type,
        startTime: startTime,
        endTime: endTime,
      );
}
