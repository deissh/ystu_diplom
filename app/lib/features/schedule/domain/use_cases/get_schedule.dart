import '../entities/schedule_day.dart';
import '../repositories/schedule_repository.dart';

class GetSchedule {
  final ScheduleRepository _repository;

  const GetSchedule(this._repository);

  Future<List<ScheduleDay>> call({
    required String groupId,
    required DateTime from,
    required DateTime to,
  }) {
    return _repository.getSchedule(groupId: groupId, from: from, to: to);
  }
}
