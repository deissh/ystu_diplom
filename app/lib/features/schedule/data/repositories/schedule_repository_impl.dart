import '../../domain/entities/schedule_day.dart';
import '../../domain/repositories/schedule_repository.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  const ScheduleRepositoryImpl();

  @override
  Future<List<ScheduleDay>> getSchedule({
    required String groupId,
    required DateTime from,
    required DateTime to,
  }) async {
    // TODO: implement — fetch from remote, fallback to local cache
    return [];
  }
}
