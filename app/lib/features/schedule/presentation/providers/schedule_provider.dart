import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local/drift_database.dart';
import '../../data/repositories/schedule_repository_impl.dart';
import '../../domain/entities/schedule_day.dart';
import '../../domain/repositories/schedule_repository.dart';

/// Singleton провайдер базы данных Drift.
///
/// Non-autoDispose: AppDatabase живёт весь lifecycle приложения.
/// ref.onDispose(db.close) — корректно закрывает SQLite-соединение
/// при диспозе ProviderScope (выход из приложения / teardown тестов).
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Провайдер репозитория расписания.
final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return const ScheduleRepositoryImpl();
});

/// Реактивный стрим расписания.
///
/// ref.keepAlive() — стрим не диспозируется при уходе пользователя
/// с экрана расписания, избегая мигания загрузки при возврате.
///
/// TODO: параметризовать groupId/from/to через profileProvider.
final scheduleProvider = StreamProvider<List<ScheduleDay>>((ref) {
  ref.keepAlive();
  final repo = ref.watch(scheduleRepositoryProvider);
  return repo.watchSchedule(
    groupId: '',
    from: DateTime.utc(2020),
    to: DateTime.utc(2030),
  );
});

/// Currently selected day in the WeekStrip.
///
/// Initialized to today. WeekStrip writes to this provider on tap;
/// ScheduleScreen reads it to filter the lesson list.
final selectedDayProvider = StateProvider<DateTime>((ref) => DateTime.now());
