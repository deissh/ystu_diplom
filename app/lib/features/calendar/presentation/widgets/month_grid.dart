import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../schedule/domain/entities/schedule_day.dart';
import '../providers/calendar_provider.dart';

/// Monthly calendar grid with colored lesson-type dots in each day cell.
///
/// Reads [calendarDisplayMonthProvider] and [calendarSelectedDayProvider]
/// from Riverpod; writes back on user interaction.
class MonthGrid extends ConsumerWidget {
  const MonthGrid({super.key, required this.scheduleDays});

  final List<ScheduleDay> scheduleDays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayMonth = ref.watch(calendarDisplayMonthProvider);
    final selectedDay = ref.watch(calendarSelectedDayProvider);

    final Color accent = AppColors.resolve(
      context,
      AppColors.accentLight,
      AppColors.accentDark,
    );
    final Color label = AppColors.resolve(
      context,
      AppColors.labelLight,
      AppColors.labelDark,
    );
    final Color label3 = AppColors.resolve(
      context,
      AppColors.label3Light,
      AppColors.label3Dark,
    );

    return TableCalendar(
      locale: 'ru_RU',
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: displayMonth,
      selectedDayPredicate: (day) => isSameDay(day, selectedDay),
      calendarFormat: CalendarFormat.month,
      availableCalendarFormats: const {CalendarFormat.month: ''},
      startingDayOfWeek: StartingDayOfWeek.monday,
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: AppTextStyles.subjectName.copyWith(color: label),
        leftChevronIcon: Icon(Icons.chevron_left, color: accent),
        rightChevronIcon: Icon(Icons.chevron_right, color: accent),
        headerPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: AppTextStyles.dayChipLabel.copyWith(color: label3),
        weekendStyle: AppTextStyles.dayChipLabel.copyWith(color: label3),
      ),
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        defaultTextStyle: AppTextStyles.dayChipNumber.copyWith(color: label),
        weekendTextStyle: AppTextStyles.dayChipNumber.copyWith(color: label3),
        todayDecoration: BoxDecoration(
          color: accent.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        todayTextStyle: AppTextStyles.dayChipNumber.copyWith(color: accent),
        selectedDecoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        selectedTextStyle: AppTextStyles.dayChipNumber.copyWith(
          color: Colors.white,
        ),
        tableBorder: const TableBorder(),
        cellPadding: EdgeInsets.zero,
        cellMargin: const EdgeInsets.all(2),
      ),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) =>
            _DayCell(day: day, scheduleDays: scheduleDays, isSelected: false),
        selectedBuilder: (context, day, focusedDay) =>
            _DayCell(day: day, scheduleDays: scheduleDays, isSelected: true, accent: accent),
        todayBuilder: (context, day, focusedDay) =>
            _DayCell(day: day, scheduleDays: scheduleDays, isToday: true, accent: accent),
      ),
      onDaySelected: (selectedDay, focusedDay) {
        final normalized = DateTime(
          selectedDay.year,
          selectedDay.month,
          selectedDay.day,
        );
        ref.read(calendarSelectedDayProvider.notifier).state = normalized;
      },
      onPageChanged: (focusedDay) {
        final firstOfMonth = DateTime(focusedDay.year, focusedDay.month, 1);
        ref.read(calendarDisplayMonthProvider.notifier).state = firstOfMonth;
        ref.read(calendarSelectedDayProvider.notifier).state = firstOfMonth;
      },
    );
  }
}

// ── Day cell ──────────────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.scheduleDays,
    this.isSelected = false,
    this.isToday = false,
    this.accent,
  });

  final DateTime day;
  final List<ScheduleDay> scheduleDays;
  final bool isSelected;
  final bool isToday;
  final Color? accent;

  static const int _maxDots = 4;
  static const double _dotSize = 5;
  static const double _dotSpacing = 2;

  @override
  Widget build(BuildContext context) {
    final Color textColor = _textColor(context);
    final Color bgColor = _bgColor(context);
    final dots = _dotsForDay(context);

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: AppTextStyles.dayChipNumber.copyWith(color: textColor),
          ),
          if (dots.isNotEmpty) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: dots
                  .map(
                    (color) => Container(
                      width: _dotSize,
                      height: _dotSize,
                      margin: const EdgeInsets.symmetric(
                        horizontal: _dotSpacing / 2,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Color _textColor(BuildContext context) {
    if (isSelected) return Colors.white;
    if (isToday && accent != null) return accent!;
    final isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
    return AppColors.resolve(
      context,
      isWeekend ? AppColors.label3Light : AppColors.labelLight,
      isWeekend ? AppColors.label3Dark : AppColors.labelDark,
    );
  }

  Color _bgColor(BuildContext context) {
    if (isSelected && accent != null) return accent!;
    if (isToday && accent != null) return accent!.withValues(alpha: 0.15);
    return Colors.transparent;
  }

  List<Color> _dotsForDay(BuildContext context) {
    for (final sd in scheduleDays) {
      if (sd.date.year == day.year &&
          sd.date.month == day.month &&
          sd.date.day == day.day) {
        final lessons = sd.lessons.take(_maxDots).toList();
        return lessons
            .map((l) => AppColors.lessonTypeColor(context, l.type))
            .toList();
      }
    }
    return const [];
  }
}
