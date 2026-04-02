import 'package:flutter/material.dart';

import '../../domain/entities/lesson.dart';
import '../../domain/entities/schedule_day.dart';
import '../widgets/timeline/break_row.dart';
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

/// Interleaves [TimelineItem]s and [BreakRow]s for the given [lessons].
List<Widget> buildScheduleItems(List<Lesson> lessons) {
  final items = <Widget>[];
  for (int i = 0; i < lessons.length; i++) {
    items.add(TimelineItem(lesson: lessons[i]));
    if (i < lessons.length - 1) {
      final breakMin =
          lessons[i + 1].startTime.difference(lessons[i].endTime).inMinutes;
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
