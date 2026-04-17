import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/datasources/local/drift_database.dart';
import '../../data/datasources/local/groups_dao.dart';
import '../../data/datasources/local/schedule_dao.dart';
import '../../data/datasources/local/teachers_dao.dart';
import '../../data/datasources/remote/api_client.dart';
import '../../data/datasources/remote/parser.dart';
import '../../data/repositories/groups_repository_impl.dart';
import '../../data/repositories/schedule_repository_impl.dart';
import '../../data/repositories/teachers_repository_impl.dart';
import '../../domain/entities/schedule_day.dart';
import '../../domain/entities/selected_subject.dart';
import '../../domain/repositories/groups_repository.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../../domain/repositories/teachers_repository.dart';

DateTime mondayOf(DateTime date) =>
    date.subtract(Duration(days: date.weekday - 1));

// ── Инфраструктурные провайдеры ───────────────────────────────────────────────

/// Singleton провайдер базы данных Drift.
///
/// Non-autoDispose: AppDatabase живёт весь lifecycle приложения.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final scheduleDaoProvider = Provider<ScheduleDao>((ref) {
  return ref.watch(databaseProvider).scheduleDao;
});

final groupsDaoProvider = Provider<GroupsDao>((ref) {
  return ref.watch(databaseProvider).groupsDao;
});

final teachersDaoProvider = Provider<TeachersDao>((ref) {
  return ref.watch(databaseProvider).teachersDao;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(dioProvider));
});

final parserProvider = Provider<ScheduleParser>((_) => const ScheduleParser());

// ── Репозитории ───────────────────────────────────────────────────────────────

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepositoryImpl(
    ref.watch(scheduleDaoProvider),
    ref.watch(apiClientProvider),
    ref.watch(parserProvider),
  );
});

final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  return GroupsRepositoryImpl(
    ref.watch(groupsDaoProvider),
    ref.watch(apiClientProvider),
    ref.watch(parserProvider),
  );
});

final teachersRepositoryProvider = Provider<TeachersRepository>((ref) {
  return TeachersRepositoryImpl(
    ref.watch(teachersDaoProvider),
    ref.watch(apiClientProvider),
    ref.watch(parserProvider),
  );
});

// ── Провайдеры состояния ──────────────────────────────────────────────────────

/// Выбранный субъект расписания (группа или преподаватель).
///
/// null — онбординг ещё не пройден.
/// Инициализируется из профиля в AppStartupNotifier после загрузки.
final selectedSubjectProvider = StateProvider<SelectedSubject?>((ref) => null);

/// Реактивный стрим расписания для выбранного субъекта.
///
/// ref.keepAlive() — стрим не диспозируется при уходе с экрана расписания,
/// избегая мигания загрузки при возврате.
final scheduleProvider = StreamProvider<List<ScheduleDay>>((ref) {
  ref.keepAlive();
  final subject = ref.watch(selectedSubjectProvider);
  if (subject == null) return Stream.value([]);
  final repo = ref.watch(scheduleRepositoryProvider);
  return repo.watchSchedule(
    subject: subject,
    from: DateTime.utc(2020),
    to: DateTime.utc(2030),
  );
});

/// Currently selected day in the WeekStrip.
final selectedDayProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final nowProvider = StreamProvider<DateTime>((ref) async* {
  ref.keepAlive();
  yield DateTime.now();
  yield* Stream.periodic(const Duration(seconds: 30), (_) => DateTime.now());
});

final currentWeekProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return mondayOf(DateTime(now.year, now.month, now.day));
});
