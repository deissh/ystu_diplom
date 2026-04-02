import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../schedule/presentation/utils/schedule_ui_helpers.dart';
import '../../../schedule/presentation/widgets/sync_status_bar.dart';
import '../providers/calendar_provider.dart';
import '../widgets/lesson_type_legend.dart';
import '../widgets/month_grid.dart';

/// Calendar tab screen.
///
/// Layout (top-to-bottom):
///   [SyncStatusBar]       — conditional, shows sync errors
///   [MonthGrid]           — fixed monthly calendar with lesson-type dots
///   [LessonTypeLegend]    — color legend for the dots
///   [scrollable timeline] — pars for the selected day
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(calendarSelectedDayProvider);
    final scheduleAsync = ref.watch(scheduleProvider);

    final Color bg = AppColors.resolve(
      context,
      AppColors.bgLight,
      AppColors.bgDark,
    );

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            const SyncStatusBar(),
            const SizedBox(height: 4),
            // ── Calendar + legend (fixed) ──────────────────────────────
            scheduleAsync.when(
              data: (days) => MonthGrid(scheduleDays: days),
              loading: () => const MonthGrid(scheduleDays: []),
              error: (e, st) => const MonthGrid(scheduleDays: []),
            ),
            const LessonTypeLegend(),
            // ── Timeline (scrollable) ──────────────────────────────────
            Expanded(
              child: scheduleAsync.when(
                data: (days) {
                  if (selectedDay.weekday > DateTime.friday) {
                    return const _WeekendState();
                  }
                  final lessons = lessonsForDay(days, selectedDay);
                  if (lessons.isEmpty) {
                    return const _FreeDayState();
                  }
                  final bottomPad = kBottomNavigationBarHeight +
                      MediaQuery.of(context).padding.bottom;
                  return ListView(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad),
                    children: buildScheduleItems(lessons),
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) => _ErrorState(
                  error: error,
                  onRetry: () => ref.invalidate(scheduleProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty / error states ──────────────────────────────────────────────────────

class _WeekendState extends StatelessWidget {
  const _WeekendState();

  @override
  Widget build(BuildContext context) =>
      const _StateMessage(message: 'Выходной — отдыхай!');
}

class _FreeDayState extends StatelessWidget {
  const _FreeDayState();

  @override
  Widget build(BuildContext context) =>
      const _StateMessage(message: 'Нет пар — свободный день');
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final Color accent = AppColors.resolve(
      context,
      AppColors.accentLight,
      AppColors.accentDark,
    );
    final Color label3 = AppColors.resolve(
      context,
      AppColors.label3Light,
      AppColors.label3Dark,
    );

    final message = switch (error) {
      NetworkFailure() => 'Не удалось загрузить расписание: проблемы с сетью',
      ParseFailure() => 'Не удалось обработать данные расписания',
      CacheFailure() => 'Не удалось прочитать сохранённое расписание',
      _ => 'Ошибка загрузки расписания',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.meta.copyWith(color: label3),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: accent),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final Color label3 = AppColors.resolve(
      context,
      AppColors.label3Light,
      AppColors.label3Dark,
    );
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTextStyles.meta.copyWith(color: label3),
      ),
    );
  }
}
