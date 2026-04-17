import 'lesson_model.dart';

/// Внутренняя модель парсера: один день расписания с уже отфильтрованными
/// по чётности занятиями. Не выходит за пределы data-слоя.
class ScheduleDayModel {
  const ScheduleDayModel({required this.date, required this.lessons});

  final DateTime date;

  /// Занятия, прошедшие фильтр чётности недели.
  final List<LessonModel> lessons;
}
