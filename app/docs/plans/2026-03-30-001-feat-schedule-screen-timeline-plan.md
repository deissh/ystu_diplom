---
title: "feat: Implement schedule screen timeline components"
type: feat
status: completed
date: 2026-03-30
origin: docs/brainstorms/2026-03-27-schedule-screen-requirements.md
---

# feat: Implement schedule screen timeline components

## Overview

Достроить центральный экран расписания: реализовать компоненты тайм-лайна (`LessonCard` + субкомпоненты, `BreakRow`, `TimelineItem`) и финально собрать `ScheduleScreen` из уже готовых и новых виджетов. Данные — моки из `ScheduleRepositoryImpl`. Дизайн-система (`AppColors`, `AppTextStyles`) уже полностью готова.

**Что уже сделано:** `SyncStatusBar`, `WeekStrip`, `scheduleProvider`, `selectedDayProvider`, мок-данные (5 дней, активная пара в среду), вся тема.

**Что осталось:** 6 файлов виджетов + финальная сборка экрана.

(see origin: docs/brainstorms/2026-03-27-schedule-screen-requirements.md)

---

## Структура файлов

```
lib/features/schedule/presentation/widgets/
├── sync_status_bar.dart           ✓ готово
├── week_strip.dart                ✓ готово
└── timeline/
    ├── item.dart                  ⚠ переписать (сейчас Placeholder)
    ├── break_row.dart             ✗ создать
    └── lesson_card/
        ├── lesson_card.dart       ✗ создать
        ├── teacher_chip.dart      ✗ создать
        ├── active_badge.dart      ✗ создать
        └── lesson_progress_bar.dart ✗ создать

lib/features/schedule/presentation/screens/
└── schedule_screen.dart           ⚠ дополнить (добавить ListView с тайм-лайном)
```

---

## Acceptance Criteria

- [ ] `flutter analyze` проходит без ошибок и предупреждений
- [ ] Экран показывает пары выбранного дня (`selectedDayProvider`)
- [ ] Активная пара (среда в моках) показывает `ActiveBadge` + `LessonProgressBar`
- [ ] Завершённые пары затемнены (`Opacity(0.48)`)
- [ ] Между каждыми двумя парами стоит `BreakRow` с реальным временем перерыва
- [ ] День без пар показывает "Нет пар" по центру
- [ ] Светлая и тёмная тема работают корректно (тема сейчас захардкожена в `ThemeMode.dark` в `app.dart:17`)
- [ ] Нижний padding 100 px под tab bar
- [ ] Нет использования устаревшего `Color.withOpacity` — только `withValues(alpha:)`

---

## Detailed Implementation Plan

### Шаг 1 — `teacher_chip.dart`

**Файл:** `lib/features/schedule/presentation/widgets/timeline/lesson_card/teacher_chip.dart`

```dart
// Принимает: String teacher  (формат "Иванов А.В.")
// Рендерит: круглый аватар 24×24 (accent цвет, белые инициалы) + имя преподавателя
```

**Логика инициалов:**
- Разбить `teacher` по пробелу → взять первые символы первых двух слов
- `"Иванов А.В."` → `"ИА"` (первая буква фамилии + первая буква имени)
- Использовать `AppTextStyles.teacherInitials` (уже определён: 8 sp, w700, белый)
- Для имени: `AppTextStyles.teacherName.copyWith(color: label3)` (12 sp, w400)
- Аватар: `Container(width: 24, height: 24, decoration: BoxDecoration(color: accent, shape: BoxShape.circle))`

**Паттерн:** `StatelessWidget`, не `ConsumerWidget` (нет провайдеров)

---

### Шаг 2 — `active_badge.dart`

**Файл:** `lib/features/schedule/presentation/widgets/timeline/lesson_card/active_badge.dart`

```dart
// Рендерит: пульсирующая зелёная точка + "Сейчас идёт"
// Анимация: SingleTickerProviderStateMixin + AnimationController (2200 ms, repeat reverse)
// Такой же паттерн как _PulsingDot в sync_status_bar.dart:135
```

- Точка 8×8, `AppColors.greenLight/Dark`
- Текст "Сейчас идёт", `AppTextStyles.activeBadge.copyWith(color: accent)` (10 sp, w600)
- `StatefulWidget` с `SingleTickerProviderStateMixin`
- Анимировать `opacity` (1.0→0.5) и `scale` (1.0→1.3), `Curves.easeInOut`

> Не выносить `_PulsingDot` в шаренный виджет — YAGNI, дублирование минимально.

---

### Шаг 3 — `lesson_progress_bar.dart`

**Файл:** `lib/features/schedule/presentation/widgets/timeline/lesson_card/lesson_progress_bar.dart`

```dart
// Принимает: DateTime startTime, DateTime endTime
// Рендерит: трек + градиентный fill + подписи "Прошло X мин / Осталось Y мин"
```

**Компоновка:**
```
[====gradient====-------]   ← ClipRRect / Stack
Прошло 30 мин      Осталось 60 мин  ← Row(mainAxisAlignment: spaceBetween)
```

**Расчёт прогресса:**
```dart
final now = DateTime.now();
final total = endTime.difference(startTime).inSeconds;
final elapsed = now.difference(startTime).inSeconds.clamp(0, total);
final progress = elapsed / total;  // 0.0..1.0
final elapsedMin = (elapsed / 60).round();
final remainingMin = ((total - elapsed) / 60).round();
```

**Визуал трека:**
```dart
Container(
  height: 4,
  decoration: BoxDecoration(
    color: surface3,
    borderRadius: BorderRadius.circular(2),
  ),
  child: FractionallySizedBox(
    widthFactor: progress,
    alignment: Alignment.centerLeft,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [accent, teal]),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  ),
)
```

- `AppTextStyles.progressLabel.copyWith(color: label3)` для подписей
- `StatelessWidget` (прогресс вычисляется при каждом `build` — допустимо для мока)

---

### Шаг 4 — `lesson_card.dart`

**Файл:** `lib/features/schedule/presentation/widgets/timeline/lesson_card/lesson_card.dart`

```dart
// Принимает: Lesson lesson
// Определяет isActive / isPast внутри
```

**Логика состояний:**
```dart
final now = DateTime.now();
final isActive = now.isAfter(lesson.startTime) && now.isBefore(lesson.endTime);
final isPast   = now.isAfter(lesson.endTime);
```

**Визуальная структура:**
```
┌─[4px strip]─────────────────────────┐
│ [ЛЕК] Математический анализ         │
│ 👤 Иванов А.В.        ┃ ▪ 301       │
│ [ActiveBadge]         (если active)  │
│ [LessonProgressBar]   (если active)  │
└──────────────────────────────────────┘
```

**Детали:**
- Обёртка: `Opacity(opacity: isPast ? 0.48 : 1.0, child: ...)`
- `Container` с `surfaceLight/Dark` + `borderRadius: 12` + тень (только светлая тема)
- Левая полоска: отдельный `Container(width: 4, color: AppColors.subjectColor(lesson.subject))` внутри `Row`
- Тип-бейдж (ЛЕК/ПР/ЛАБ): `Container(padding: EdgeInsets.symmetric(h:6, v:2), decoration: BoxDecoration(color: _typeColor(lesson.type), borderRadius: 6), child: Text(lesson.type.toUpperCase(), style: AppTextStyles.badge.copyWith(color: Colors.white)))`
- `_typeColor`: `'ЛЕК' → accent`, `'ПР' → green`, `'ЛАБ' → orange` (статический метод или `switch`)
- Комната: `Icon(Icons.location_on_outlined, size: 13) + Text(lesson.room, style: AppTextStyles.meta.copyWith(color: label3))`
- `StatelessWidget`

---

### Шаг 5 — `break_row.dart`

**Файл:** `lib/features/schedule/presentation/widgets/timeline/break_row.dart`

```dart
// Принимает: int minutes
// Рендерит: ──────── Перерыв 15 мин ────────
```

```dart
Row(
  children: [
    Expanded(child: Divider(color: separator, thickness: 0.5)),
    Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Text('Перерыв $minutes мин', style: AppTextStyles.breakLabel.copyWith(color: label3)),
    ),
    Expanded(child: Divider(color: separator, thickness: 0.5)),
  ],
)
```

- `StatelessWidget`, `margin: EdgeInsets.symmetric(vertical: 4)`

---

### Шаг 6 — `item.dart` (переписать)

**Файл:** `lib/features/schedule/presentation/widgets/timeline/item.dart`

```dart
// Принимает: Lesson lesson
// Рендерит: [Колонка времени 48px] | [LessonCard]
```

```
┌──────────────────────────────────────┐
│ 09:50  │ [LessonCard]                │
│ 11:25  │                             │
└──────────────────────────────────────┘
```

**Детали:**
- Левая колонка: `SizedBox(width: 48)` с двумя `Text` (start / end)
  - Start: `AppTextStyles.timeStart.copyWith(color: label2)` (12 sp, w500)
  - End: `AppTextStyles.timeEnd.copyWith(color: label3)` (11 sp, w400)
  - Между ними: 4px gap
- `SizedBox(width: 12)` разделитель
- `Expanded(child: LessonCard(lesson: lesson))`
- Сохранить `@Preview` аннотацию — обновить с реальным мок-уроком

Формат времени: `'${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}'`

---

### Шаг 7 — `schedule_screen.dart` (финальная сборка)

**Файл:** `lib/features/schedule/presentation/screens/schedule_screen.dart`

**Логика фильтрации:**
```dart
final selectedDay = ref.watch(selectedDayProvider);
final scheduleAsync = ref.watch(scheduleProvider);

List<Lesson> _lessonsForDay(List<ScheduleDay> days, DateTime day) {
  for (final d in days) {
    if (d.date.year == day.year && d.date.month == day.month && d.date.day == day.day) {
      return d.lessons;
    }
  }
  return const [];
}
```

**Сборка ListView:**
```dart
// Для списка [A, B, C] собираем: [item(A), break(A→B), item(B), break(B→C), item(C)]
final items = <Widget>[];
for (int i = 0; i < lessons.length; i++) {
  items.add(TimelineItem(lesson: lessons[i]));
  if (i < lessons.length - 1) {
    final breakMin = lessons[i + 1].startTime.difference(lessons[i].endTime).inMinutes;
    if (breakMin > 0) items.add(BreakRow(minutes: breakMin));
  }
}
```

**Структура экрана:**
```dart
Column(
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
          if (lessons.isEmpty) return const _EmptyDay();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            children: _buildItems(lessons),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const _EmptyDay(), // кэш показывается через SyncStatusBar
      ),
    ),
  ],
)
```

- `AppBar` убрать (или оставить с пустым `title` и `elevation: 0`) — выглядит чище без него
- `Scaffold(backgroundColor: AppColors.resolve(context, bgLight, bgDark))`
- Приватный виджет `_EmptyDay` — центрированный текст "Нет пар" в `label3`

---

## Technical Considerations

- **`withOpacity` vs `withValues`:** Весь новый код должен использовать `color.withValues(alpha: 0.48)`, не устаревший `withOpacity`. `WeekStrip` использует `withOpacity` — не трогать (за рамками задачи).
- **Нет `Timer`/`Stream` для обновления прогресс-бара:** Прогресс вычисляется при `build`. Для диплома достаточно; реальное обновление каждую секунду — отдельная задача.
- **`@Preview` аннотации:** Обновить `item.dart` preview с реальным `Lesson` из моков. Остальные виджеты (`lesson_card`, `active_badge`, `lesson_progress_bar`) — добавить `@Preview` по тому же паттерну что в `sync_status_bar.dart:18-23`.
- **Импорты:** Каждый файл в `lesson_card/` нужно импортировать в `lesson_card.dart`. `item.dart` импортирует `lesson_card/lesson_card.dart`. `schedule_screen.dart` импортирует `timeline/item.dart` и `timeline/break_row.dart`.
- **AppBar:** Сейчас `AppBar(title: Text('Расписание'))`. После добавления `SyncStatusBar` в body — можно убрать AppBar совсем или оставить как spacer (зависит от дизайна).

---

## System-Wide Impact

- **Затронутые файлы:** только `presentation/` слой. Нет изменений в `domain/`, `data/`, `core/`.
- **Провайдеры:** Читаем `scheduleProvider` и `selectedDayProvider` — не меняем логику провайдеров.
- **Роутер:** `ScheduleScreen` уже зарегистрирован как `/schedule` в `app_router.dart:17`.
- **Навигация:** `_ScaffoldWithNavBar` в роутере имеет 3 пункта в `BottomNavigationBar`, но только 2 бранча (`/schedule`, `/profile`) — лишний пункт "Настройки" будет крешить. Не трогать роутер в рамках этой задачи.

---

## Dependencies / References

**Внутренние:**
- `lib/core/theme/app_colors.dart` — `AppColors.subjectColor`, `AppColors.resolve`, все цветовые токены
- `lib/core/theme/app_text_styles.dart` — `AppTextStyles.badge`, `.meta`, `.timeStart`, `.timeEnd`, `.breakLabel`, `.teacherName`, `.teacherInitials`, `.activeBadge`, `.progressLabel`
- `lib/features/schedule/domain/entities/lesson.dart` — `Lesson` entity
- `lib/features/schedule/domain/entities/schedule_day.dart` — `ScheduleDay`
- `lib/features/schedule/presentation/providers/schedule_provider.dart` — `scheduleProvider`, `selectedDayProvider`
- `lib/features/schedule/presentation/widgets/sync_status_bar.dart:135` — паттерн `_PulsingDot` для `ActiveBadge`
- `lib/features/schedule/presentation/widgets/week_strip.dart:90` — паттерн `_DayChip` для card компонентов

**Origin document:** [docs/brainstorms/2026-03-27-schedule-screen-requirements.md](../brainstorms/2026-03-27-schedule-screen-requirements.md)
Ключевые решения перенесены:
- Структура `timeline/lesson_card/` с отдельным файлом на каждый субкомпонент
- `AppColors.subjectColor(lesson.subject)` для левой полоски
- `ActiveBadge` + `LessonProgressBar` только для активной пары (по `DateTime.now()`)
- Separator-линия между парами рендерится в `ScheduleScreen` как `BreakRow`, не в `TimelineItem`
