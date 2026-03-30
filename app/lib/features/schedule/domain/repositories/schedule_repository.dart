import '../entities/schedule_day.dart';

abstract interface class ScheduleRepository {
  Future<List<ScheduleDay>> getSchedule({
    required String groupId,
    required DateTime from,
    required DateTime to,
  });

  Stream<List<ScheduleDay>> watchSchedule({
    required String groupId,
    required DateTime from,
    required DateTime to,
  });
}
