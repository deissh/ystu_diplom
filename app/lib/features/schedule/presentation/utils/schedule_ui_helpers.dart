import 'package:flutter/material.dart';

import '../../domain/entities/lesson.dart';
import '../../domain/entities/schedule_day.dart';
import '../widgets/timeline/break_row.dart';
import '../widgets/timeline/current_time_indicator.dart';
import '../widgets/timeline/item.dart';

/// Shared UI utilities for rendering schedule data in timeline format.
///
/// Used by both [ScheduleScreen] and [CalendarScreen] to avoid duplication.

/// Returns lessons for [day] from [days], or an empty list.
List<Lesson> lessonsForDay(List<ScheduleDay> days, DateTime day) {
  for (final d in days) {
    if (d.date.year == day.year &&
        d.date.month == day.month &&
        d.date.day == day.day) {
      return d.lessons;
    }
  }
  return const [];
}

/// Interleaves [TimelineItem]s, [BreakRow]s, and an optional
/// [CurrentTimeIndicator] for the given [lessons].
///
/// Pass [now] (typically from `nowProvider`) **only when the currently selected
/// day is today**. When [now] is non-null the function finds the first lesson
/// that has not yet ended and inserts the indicator immediately before it:
///
/// - `now` before all lessons → indicator at the top of the list.
/// - `now` during lesson i → indicator before lesson i (the card shows
///   its own progress bar).
/// - `now` in the break between lesson i and lesson i+1 → indicator between
///   the [BreakRow] and lesson i+1.
/// - `now` after all lessons → no indicator (the day is over).
List<Widget> buildScheduleItems(List<Lesson> lessons, {DateTime? now}) {
  // Determine the insertion point for the current-time indicator.
  // indicatorBeforeIndex == i  →  insert indicator before lessons[i].
  int? indicatorBeforeIndex;
  if (now != null && lessons.isNotEmpty) {
    for (int i = 0; i < lessons.length; i++) {
      if (now.isBefore(lessons[i].endTime)) {
        indicatorBeforeIndex = i;
        break;
      }
    }
  }

  final items = <Widget>[];

  // Insert indicator at the very top when now is before lesson 0.
  if (indicatorBeforeIndex == 0) {
    items.add(CurrentTimeIndicator(now: now!));
    items.add(const SizedBox(height: 4));
  }

  for (int i = 0; i < lessons.length; i++) {
    items.add(TimelineItem(lesson: lessons[i]));

    if (i < lessons.length - 1) {
      final breakMin =
          lessons[i + 1].startTime.difference(lessons[i].endTime).inMinutes;
      if (breakMin > 0) {
        items.add(BreakRow(minutes: breakMin));
      }
      items.add(const SizedBox(height: 8));

      // Insert indicator after the break gap, before lessons[i+1].
      if (indicatorBeforeIndex == i + 1) {
        items.add(CurrentTimeIndicator(now: now!));
        items.add(const SizedBox(height: 4));
      }
    }
  }

  return items;
}
