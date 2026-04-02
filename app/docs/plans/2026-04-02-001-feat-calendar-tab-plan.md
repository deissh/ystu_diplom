---
title: "feat: Add Calendar Tab with Monthly View and Lesson Type Dots"
type: feat
status: active
date: 2026-04-02
origin: docs/brainstorms/2026-04-02-calendar-tab-requirements.md
---

# feat: Add Calendar Tab with Monthly View and Lesson Type Dots

## Overview

Add a new **Calendar** tab to the bottom navigation bar (position 2, between Schedule and Profile), replacing the non-functional Settings stub. The screen shows a monthly calendar with colored dots per lesson, a color legend, and a reused timeline widget below for the selected day's schedule.

## Problem Statement / Motivation

The Schedule tab only provides a weekly strip for day navigation. Users cannot see their schedule in a monthly context, plan ahead across weeks, or get a quick overview of busy days. The Calendar tab addresses this gap by surfacing a full month view while reusing existing timeline infrastructure.

## Proposed Solution

A presentation-only feature (`lib/features/calendar/presentation/`) that reads from the existing `scheduleProvider`. No new domain or data layers are needed. The screen is split into a fixed upper zone (calendar + legend) and a scrollable lower zone (timeline). Two new providers manage the displayed month and selected day, fully independent from the Schedule tab's state.

---

## Technical Considerations

### New dependency: `table_calendar`

The project has no existing calendar widget. `table_calendar` (^3.1.x) is the de-facto Flutter calendar library: highly customizable cell builders, built-in month navigation, and active maintenance. The custom `calendarBuilders` API allows injecting the colored dot row into each cell without overriding the library's layout engine.

> **Deferred decision (from origin doc):** If the app's iOS-style design cannot be achieved with `table_calendar`, replace with a custom `GridView`-based calendar. The plan assumes `table_calendar` unless blocked during implementation.

### AppColors: add `lessonTypeColor()`

There is currently no `LessonType → Color` mapping exposed in `AppColors`. The `_TypeBadge` inside `lesson_card.dart` has this logic inline. A shared static method must be added to avoid duplication between the badge and the calendar dots.

```dart
// lib/core/theme/app_colors.dart  (new method)
static Color lessonTypeColor(BuildContext context, LessonType type) =>
    switch (type) {
      LessonType.lecture  => resolve(context, accentLight,  accentDark),
      LessonType.practice => resolve(context, greenLight,   greenDark),
      LessonType.lab      => resolve(context, orangeLight,  orangeDark),
      LessonType.other    => resolve(context, label3Light,  label3Dark),
    };
```

`_TypeBadge` in `lesson_card.dart` should then delegate to this method (refactor in-scope).

### Timeline reuse

`ScheduleScreen._lessonsForDay()` and `_buildItems()` are `static` methods. They should be extracted to a shared helper (e.g., `lib/features/schedule/presentation/utils/schedule_ui_helpers.dart`) so `CalendarScreen` can call them without importing `ScheduleScreen`.

### Two new providers

```dart
// lib/features/calendar/presentation/providers/calendar_provider.dart

/// The month currently displayed in the calendar grid.
/// Normalized to the 1st day of the month at midnight.
final calendarDisplayMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

/// The day selected in the Calendar tab.
/// Independent from selectedDayProvider (Schedule tab).
final calendarSelectedDayProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});
```

When the user navigates months, both providers update atomically: `calendarDisplayMonthProvider` moves to the new month, `calendarSelectedDayProvider` resets to the 1st of that month.

### Router: replace Settings with Calendar

Current state: 2 `StatefulShellBranch`es but 3 `BottomNavigationBarItem`s — the Settings tab is visually present but crashes on tap (no route defined). This plan removes the Settings stub entirely and adds Calendar at index 1.

```
Before:  Schedule(0) | Profile(1) | Settings(2 — broken)
After:   Schedule(0) | Calendar(1) | Profile(2)
```

### Dot rendering in day cells

Each day cell receives up to **4 dots** maximum. If the day has more than 4 lessons, only the first 4 lesson types are shown (no overflow indicator). Dots are 5 dp circles, spaced 2 dp apart, horizontally centered below the day number.

Weekend cells (Saturday/Sunday) show no dots and no special visual treatment (same background as other cells without lessons).

### State persistence across tab switches

`StatefulShellRoute.indexedStack` preserves widget state. Both `calendarDisplayMonthProvider` and `calendarSelectedDayProvider` are `StateProvider` (non-autoDispose), so state survives tab switching.

---

## System-Wide Impact

- **Interaction graph:** `CalendarScreen` reads `scheduleProvider` (already `keepAlive`) and `nowProvider`. Both are shared with `ScheduleScreen` — no additional network calls or DB reads are triggered.
- **Error propagation:** Calendar inherits the same `scheduleProvider` error state. The `SyncStatusBar` widget (reused from Schedule feature) surfaces sync errors above the calendar grid.
- **State lifecycle:** `calendarSelectedDayProvider` and `calendarDisplayMonthProvider` are not autoDisposed. They live for the app's lifetime, same as `selectedDayProvider` and `currentWeekProvider` in the schedule feature.
- **Router index shift:** Removing Settings and inserting Calendar at index 1 shifts Profile from index 1 to index 2. Any deep links or tests that hardcode `shell.goBranch(1)` to reach Profile will break — verify there are none.
- **`_TypeBadge` refactor:** Delegating to the new `AppColors.lessonTypeColor()` is a pure refactor (same visual output). No behavioral change.

---

## Acceptance Criteria

- [ ] Bottom navigation shows: Расписание | Календарь | Профиль (Settings tab removed)
- [ ] Calendar screen opens on current month with today selected by default
- [ ] Monthly calendar grid renders all days of the selected month
- [ ] Each day cell shows up to 4 colored dots (one per lesson, color = LessonType)
- [ ] Tapping a day cell updates the timeline below to show that day's lessons
- [ ] Color legend below the calendar shows all 4 lesson types with their colors and labels
- [ ] Navigating to another month auto-selects the 1st day of the new month
- [ ] Timeline shows correct empty states: weekend message, free-day message, error state with retry
- [ ] `SyncStatusBar` is displayed above the calendar and shows sync errors
- [ ] Selecting a day in Calendar does NOT affect the selected day in the Schedule tab (and vice versa)
- [ ] Calendar state (selected day, displayed month) is preserved when switching tabs
- [ ] `AppColors.lessonTypeColor()` is a shared static method; `_TypeBadge` uses it
- [ ] `flutter analyze` passes with no new warnings

---

## Dependencies & Risks

| Item | Detail |
|------|--------|
| **`table_calendar` dependency** | Must be added to `pubspec.yaml`. Verify no version conflicts with existing dependencies (Flutter SDK ^3.x, Dart ^3.11.3). |
| **`scheduleProvider` data range** | Currently hardcoded `from: 2020, to: 2030` with mock data. Calendar dots will be empty until real API integration is done — this is expected and acceptable for this PR. |
| **`_TypeBadge` refactor** | Small in-scope refactor. Risk: zero, purely mechanical delegation to new method. |
| **Static method extraction** | Moving `_lessonsForDay` / `_buildItems` out of `ScheduleScreen`. Risk: low — they are already `static` with no captured state. |
| **Settings removal** | The `/settings` route was never implemented (CLAUDE.md: "known stub"). Removing it is safe. |

---

## Implementation Phases

### Phase 1: Foundation

1. Add `table_calendar: ^3.1.0` to `pubspec.yaml`, run `flutter pub get`
2. Add `AppColors.lessonTypeColor(BuildContext context, LessonType type)` to `lib/core/theme/app_colors.dart`
3. Refactor `_TypeBadge` in `lib/features/schedule/presentation/widgets/timeline/lesson_card/lesson_card.dart` to use the new method
4. Extract `_lessonsForDay()` and `_buildItems()` from `ScheduleScreen` into `lib/features/schedule/presentation/utils/schedule_ui_helpers.dart`
5. Update `ScheduleScreen` to import and call the extracted helpers

### Phase 2: Calendar feature

6. Create `lib/features/calendar/presentation/providers/calendar_provider.dart` with `calendarDisplayMonthProvider` and `calendarSelectedDayProvider`
7. Create `lib/features/calendar/presentation/widgets/lesson_type_legend.dart` — static row of 4 color chips with labels
8. Create `lib/features/calendar/presentation/screens/calendar_screen.dart` — full screen layout
9. Create `lib/features/calendar/presentation/widgets/month_grid.dart` — `table_calendar` wrapper with custom cell builder

### Phase 3: Navigation wiring

10. Update `lib/router/app_router.dart`:
    - Remove `_settingsNavKey` and Settings `StatefulShellBranch`
    - Add `_calendarNavKey` and Calendar `StatefulShellBranch` at index 1
    - Reorder `BottomNavigationBarItem`s to: Расписание | Календарь | Профиль
11. Run `flutter analyze`, fix any issues
12. Manual smoke test: navigate all tabs, select days, switch months, verify timeline updates

---

## File Checklist

```
pubspec.yaml                                                          [modify] add table_calendar
lib/core/theme/app_colors.dart                                        [modify] add lessonTypeColor()
lib/features/schedule/presentation/widgets/timeline/lesson_card/
  lesson_card.dart                                                    [modify] _TypeBadge → lessonTypeColor()
lib/features/schedule/presentation/utils/
  schedule_ui_helpers.dart                                            [new]    _lessonsForDay, _buildItems
lib/features/schedule/presentation/screens/schedule_screen.dart       [modify] import helpers
lib/features/calendar/presentation/providers/
  calendar_provider.dart                                              [new]    display month + selected day
lib/features/calendar/presentation/widgets/
  lesson_type_legend.dart                                             [new]    color legend row
lib/features/calendar/presentation/widgets/
  month_grid.dart                                                     [new]    table_calendar wrapper
lib/features/calendar/presentation/screens/
  calendar_screen.dart                                                [new]    main screen
lib/router/app_router.dart                                            [modify] add calendar branch, remove settings
```

---

## Screen Layout Reference

```
+----------------------------------+
| SyncStatusBar (conditional)      |
+----------------------------------+
| < Апрель 2026 >                  |   ← month header with prev/next arrows
| Пн  Вт  Ср  Чт  Пт  Сб  Вс     |
|  -   1   2   3   4   5   6      |
|  7   8   9  10  11  12  13     |
|     ●●  ●●●  ●              |   ← colored dots (max 4, clipped)
| ...                              |
+----------------------------------+
| ● ЛЕК  ● ПР  ● ЛАБ  ● ?        |   ← lesson_type_legend.dart
+==================================+
| [scrollable timeline]            |
|  08:00  LessonCard               |
|    --- перерыв 10 мин ---        |
|  09:45  LessonCard               |
|  ...                             |
+----------------------------------+
```

---

## Outstanding Questions

### Deferred to Planning (carried from origin doc)

- **[Affects month_grid.dart][Needs research]** Verify `table_calendar ^3.1.x` is compatible with the project's Flutter/Dart SDK versions. If not, evaluate `syncfusion_flutter_calendar` or custom `GridView`.
- **[Affects calendar_screen.dart][Technical]** Determine minimum height for the timeline zone so at least one `TimelineItem` is visible without scrolling on common device sizes (375dp width).

---

## Sources & References

### Origin
- **Origin document:** [docs/brainstorms/2026-04-02-calendar-tab-requirements.md](../brainstorms/2026-04-02-calendar-tab-requirements.md)
  - Key decisions carried forward: Calendar replaces Settings tab (not adds a 4th); dot color = LessonType (not subject); max 4 dots per cell (clipped); independent day state from Schedule tab; auto-select 1st day on month navigation.

### Internal References
- Navigation pattern: `lib/router/app_router.dart`
- Provider patterns: `lib/features/schedule/presentation/providers/schedule_provider.dart`
- Timeline widgets: `lib/features/schedule/presentation/widgets/timeline/item.dart`, `break_row.dart`
- Color system: `lib/core/theme/app_colors.dart`
- LessonType enum: `lib/features/schedule/domain/entities/lesson_type.dart`
- Existing TypeBadge colors: `lib/features/schedule/presentation/widgets/timeline/lesson_card/lesson_card.dart`
- ScheduleScreen empty states to replicate: `lib/features/schedule/presentation/screens/schedule_screen.dart`
