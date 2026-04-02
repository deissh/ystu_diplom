import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The month currently displayed in the calendar grid.
///
/// Normalized to the 1st day of the month at midnight local time.
/// Updating this provider also resets [calendarSelectedDayProvider] to
/// the 1st of the new month — done explicitly in the UI via [ref.read].
final calendarDisplayMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

/// The day selected in the Calendar tab.
///
/// Independent from `selectedDayProvider` in the Schedule tab (R6).
/// Initialised to today; updated when the user taps a day cell or
/// navigates to a different month (auto-selects 1st of new month).
final calendarSelectedDayProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});
