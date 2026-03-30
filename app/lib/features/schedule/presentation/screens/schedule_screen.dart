import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
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

    final Color bg =
        AppColors.resolve(context, AppColors.bgLight, AppColors.bgDark);

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
                  final lessons = _lessonsForDay(days, selectedDay);
                  if (lessons.isEmpty) {
                    return const _EmptyDay();
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    children: _buildItems(lessons),
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, _) => const _EmptyDay(),
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
        final breakMin = lessons[i + 1]
            .startTime
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

class _EmptyDay extends StatelessWidget {
  const _EmptyDay();

  @override
  Widget build(BuildContext context) {
    final Color label3 =
        AppColors.resolve(context, AppColors.label3Light, AppColors.label3Dark);
    return Center(
      child: Text(
        'Нет пар',
        style: AppTextStyles.meta.copyWith(color: label3),
      ),
    );
  }
}
