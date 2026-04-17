import '../entities/schedule_day.dart';
import '../entities/selected_subject.dart';
import '../repositories/schedule_repository.dart';

class GetSchedule {
  final ScheduleRepository _repository;

  const GetSchedule(this._repository);

  Stream<List<ScheduleDay>> call({
    required SelectedSubject subject,
    required DateTime from,
    required DateTime to,
  }) {
    return _repository.watchSchedule(subject: subject, from: from, to: to);
  }
}
