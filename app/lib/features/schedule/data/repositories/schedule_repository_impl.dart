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
    // TODO: fetch from remote, fallback to local cache
    return [];
  }

  @override
  Stream<List<ScheduleDay>> watchSchedule({
    required String groupId,
    required DateTime from,
    required DateTime to,
  }) {
    // TODO: delegate to ScheduleDao.watchLessons() and group into ScheduleDay
    return const Stream.empty();
  }
}
