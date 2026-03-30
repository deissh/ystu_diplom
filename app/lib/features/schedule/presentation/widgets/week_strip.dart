import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/schedule_provider.dart';

/// Horizontal week strip showing 7 day chips (Mon–Sun).
///
/// The active chip (matching [selectedDayProvider]) has an accent background.
/// Chips for days that have lessons show a small indicator dot below the date.
class WeekStrip extends ConsumerWidget {
  const WeekStrip({super.key});

  static const List<String> _dayLabels = [
    'ПН',
    'ВТ',
    'СР',
    'ЧТ',
    'ПТ',
    'СБ',
    'ВС',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(selectedDayProvider);
    final scheduleAsync = ref.watch(scheduleProvider);

    // Days that have at least one lesson
    final daysWithLessons = <int>{};
    scheduleAsync.whenData((days) {
      for (final day in days) {
        daysWithLessons.add(_dayKey(day.date));
      }
    });

    final now = DateTime.now();
    // Monday of current week
    final monday = now.subtract(Duration(days: now.weekday - 1));

    final Color surface =
        AppColors.resolve(context, AppColors.surfaceLight, AppColors.surfaceDark);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Row(
        children: List.generate(7, (i) {
          final day = monday.add(Duration(days: i));
          final isSelected = _isSameDay(day, selectedDay);
          final hasLessons = daysWithLessons.contains(_dayKey(day));
          return Expanded(
            child: _DayChip(
              dayLabel: _dayLabels[i],
              dayNumber: day.day,
              isSelected: isSelected,
              hasLessons: hasLessons,
              onTap: () => ref.read(selectedDayProvider.notifier).state = day,
            ),
          );
        }),
      ),
    );
  }

  static int _dayKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Day chip ─────────────────────────────────────────────────────────────────

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.dayLabel,
    required this.dayNumber,
    required this.isSelected,
    required this.hasLessons,
    required this.onTap,
  });

  final String dayLabel;
  final int dayNumber;
  final bool isSelected;
  final bool hasLessons;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent =
        AppColors.resolve(context, AppColors.accentLight, AppColors.accentDark);
    final Color label2 =
        AppColors.resolve(context, AppColors.label2Light, AppColors.label2Dark);
    final Color label3 =
        AppColors.resolve(context, AppColors.label3Light, AppColors.label3Dark);

    final Color textColor = isSelected ? Colors.white : label2;
    final Color labelColor =
        isSelected ? Colors.white.withValues(alpha: 0.85) : label3;
    final Color dotColor = isSelected ? Colors.white : accent;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dayLabel,
              style: AppTextStyles.dayChipLabel.copyWith(color: labelColor),
            ),
            const SizedBox(height: 2),
            Text(
              '$dayNumber',
              style: AppTextStyles.dayChipNumber.copyWith(color: textColor),
            ),
            const SizedBox(height: 3),
            // Indicator dot
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: hasLessons ? dotColor : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
