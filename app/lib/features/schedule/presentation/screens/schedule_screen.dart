import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/schedule_day.dart';
import '../providers/schedule_provider.dart';
import '../widgets/sync_status_bar.dart';
import '../widgets/timeline/break_row.dart';
import '../widgets/timeline/item.dart';
import '../widgets/week_strip.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(selectedDayProvider);
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
            const SizedBox(height: 8),
            const SyncStatusBar(),
            const SizedBox(height: 8),
            const WeekStrip(),
            const SizedBox(height: 12),
            Expanded(
              child: scheduleAsync.when(
                data: (days) {
                  if (selectedDay.weekday > DateTime.friday) {
                    return const _WeekendState();
                  }
                  final lessons = _lessonsForDay(days, selectedDay);
                  if (lessons.isEmpty) {
                    return const _FreeDayState();
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    children: _buildItems(lessons),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
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

  /// Returns lessons for [day] from the schedule list, or an empty list.
  static List<Lesson> _lessonsForDay(List<ScheduleDay> days, DateTime day) {
    for (final d in days) {
      if (d.date.year == day.year &&
          d.date.month == day.month &&
          d.date.day == day.day) {
        return d.lessons;
      }
    }
    return const [];
  }

  /// Interleaves [TimelineItem]s and [BreakRow]s for the given [lessons].
  static List<Widget> _buildItems(List<Lesson> lessons) {
    final items = <Widget>[];
    for (int i = 0; i < lessons.length; i++) {
      items.add(TimelineItem(lesson: lessons[i]));
      if (i < lessons.length - 1) {
        final breakMin = lessons[i + 1].startTime
            .difference(lessons[i].endTime)
            .inMinutes;
        if (breakMin > 0) {
          items.add(BreakRow(minutes: breakMin));
        }
      }
      if (i < lessons.length - 1) {
        items.add(const SizedBox(height: 8));
      }
    }
    return items;
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _WeekendState extends StatelessWidget {
  const _WeekendState();

  @override
  Widget build(BuildContext context) {
    return _StateMessage(message: 'Выходной - отдыхай!');
  }
}

class _FreeDayState extends StatelessWidget {
  const _FreeDayState();

  @override
  Widget build(BuildContext context) {
    return _StateMessage(message: 'Нет пар - свободный день');
  }
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
      CacheFailure() => 'Не удалось прочитать сохраненное расписание',
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
