import '../entities/schedule_day.dart';
import '../entities/selected_subject.dart';

abstract interface class ScheduleRepository {
  Stream<List<ScheduleDay>> watchSchedule({
    required SelectedSubject subject,
    required DateTime from,
    required DateTime to,
  });
}
