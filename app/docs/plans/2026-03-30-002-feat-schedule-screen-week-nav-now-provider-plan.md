---
title: "feat: Schedule screen — week navigation, nowProvider, LessonType enum, empty states"
type: feat
status: completed
date: 2026-03-30
origin: docs/brainstorms/2026-03-30-schedule-screen-improvements-requirements.md
---

# feat: Schedule screen — week navigation, nowProvider, LessonType enum, empty states

## Overview

Четыре связанных улучшения экрана расписания, устраняющих критические слабости первой реализации: нет навигации по неделям, stale active-state в карточках пар, `type: String` без типобезопасности, и одно пустое состояние на все случаи жизни.

(see origin: docs/brainstorms/2026-03-30-schedule-screen-improvements-requirements.md)

## Problem Statement

1. Пользователь видит только текущую неделю — невозможно смотреть на неделю вперёд/назад.
2. `LessonCard` вычисляет `isActive`/`isPast` один раз при рендере; прогресс-бар не движется, "Сейчас идёт" не гаснет по окончании пары.
3. `type: String` — логика типа разбросана по виджетам, добавление нового типа требует обновления нескольких мест.
4. Единственное пустое состояние "Нет пар" не различает выходной день, свободный день и сетевую ошибку.

## Proposed Solution

### Unit 1 — `LessonType` enum (без зависимостей, реализовывать первым)

Новый файл `lib/features/schedule/domain/entities/lesson_type.dart`:

```dart
enum LessonType {
  lecture, practice, lab, other;

  String get label => switch (this) {
    LessonType.lecture  => 'ЛЕК',
    LessonType.practice => 'ПР',
    LessonType.lab      => 'ЛАБ',
    LessonType.other    => '?',
  };

  static LessonType fromString(String value) => switch (value.toUpperCase()) {
    'ЛЕК' || 'LECTURE'  => LessonType.lecture,
    'ПР'  || 'PRACTICE'  => LessonType.practice,
    'ЛАБ' || 'LAB'       => LessonType.lab,
    _                    => LessonType.other,
  };
}
```

`Lesson.type: String` → `Lesson.type: LessonType`.

`_TypeBadge` в `lesson_card.dart` переключается с `switch (type.toUpperCase())` на `switch (lesson.type)` — enum-ветки вместо строковых.

`ScheduleRepositoryImpl` — все 13 вхождений `type: 'ЛЕК'/'ПР'/'ЛАБ'` → `type: LessonType.lecture/practice/lab`.

### Unit 2 — `nowProvider` + обновление виджетов

В `schedule_provider.dart` добавить:

```dart
final nowProvider = StreamProvider<DateTime>((ref) async* {
  ref.keepAlive();
  yield DateTime.now();
  yield* Stream.periodic(const Duration(seconds: 30), (_) => DateTime.now());
});
```

`LessonCard` (`StatelessWidget` → `ConsumerWidget`): `final now = DateTime.now()` → `ref.watch(nowProvider).valueOrNull ?? DateTime.now()`.

`LessonProgressBar` принимает дополнительный параметр `now`:
- `required this.now` вместо внутреннего `DateTime.now()`
- Caller: `LessonCard` передаёт `now` из `nowProvider`

`SyncStatusBar`: аналогично читает `ref.watch(nowProvider).valueOrNull ?? DateTime.now()` вместо `DateTime.now()` в методе `build`.

### Unit 3 — `currentWeekProvider` + навигация в WeekStrip

В `schedule_provider.dart` добавить:

```dart
DateTime _mondayOf(DateTime date) =>
    date.subtract(Duration(days: date.weekday - 1));

final currentWeekProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return _mondayOf(DateTime(now.year, now.month, now.day));
});
```

`WeekStrip` читает `currentWeekProvider` вместо вычисления `monday` из `DateTime.now()`.

Стрелки `‹` / `›` по краям: `IconButton` с `onPressed` изменяет `currentWeekProvider ± 7 дней`.

Лимит навигации: ±4 недели от сегодня. Стрелка неактивна (`onPressed: null`) при выходе за лимит.

Свайп (`GestureDetector.onHorizontalDragEnd`): `dx < -50` → следующая неделя, `dx > 50` → предыдущая.

При смене недели: если `selectedDay` не попадает в новую неделю, `selectedDayProvider` перебрасывается на понедельник новой недели.

### Unit 4 — Три пустых состояния

В `schedule_screen.dart` заменить `_EmptyDay` на три виджета:

```dart
data: (days) {
  if (selectedDay.weekday > 5) return const _WeekendState();
  final lessons = _lessonsForDay(days, selectedDay);
  if (lessons.isEmpty) return const _FreeDayState();
  return ListView(...);
},
error: (error, _) => _ErrorState(
  error: error,
  onRetry: () => ref.invalidate(scheduleProvider),
),
```

`_WeekendState`: текст "Выходной — отдыхай!", без кнопки Retry.
`_FreeDayState`: текст "Нет пар — свободный день", без кнопки Retry.
`_ErrorState(error, onRetry)`: описание ошибки через `switch (error)` по `Failure` subtype + кнопка "Повторить".

## Implementation Units

### IU-1: `LessonType` enum

**Goal:** Заменить `String type` в domain-слое на типобезопасный enum.

**Files:**
- `lib/features/schedule/domain/entities/lesson_type.dart` — создать
- `lib/features/schedule/domain/entities/lesson.dart:5` — `String type` → `LessonType type`
- `lib/features/schedule/presentation/widgets/timeline/lesson_card/lesson_card.dart:71,145-163` — `_TypeBadge` переключить на enum
- `lib/features/schedule/data/repositories/schedule_repository_impl.dart:59,68,76,88,96,104,118-120,129-133,160,167,176,183,190` — заменить строки на enum-значения

**Approach:**
1. Создать `lesson_type.dart` с enum и методами `label`, `fromString`.
2. Обновить `lesson.dart`: импорт + `LessonType type`.
3. Обновить `lesson_card.dart`: `_TypeBadge(type: lesson.type)`, switch по `LessonType`.
4. Обновить `schedule_repository_impl.dart`: все 13 callsite `type: LessonType.*`.

**Patterns to follow:** `lib/core/errors/failure.dart` — пример sealed class с exhaustive switch.

**Verification:** `flutter analyze` без ошибок. Все ветки `switch (lessonType)` exhaustive.

---

### IU-2: `nowProvider`

**Goal:** Единый реактивный источник времени; стрелки/прогресс-бар обновляются каждые 30 сек без перезапуска.

**Files:**
- `lib/features/schedule/presentation/providers/schedule_provider.dart` — добавить `nowProvider`
- `lib/features/schedule/presentation/widgets/timeline/lesson_card/lesson_card.dart` — `StatelessWidget` → `ConsumerWidget`, читать `nowProvider`
- `lib/features/schedule/presentation/widgets/timeline/lesson_card/lesson_progress_bar.dart` — добавить `required DateTime now`
- `lib/features/schedule/presentation/widgets/sync_status_bar.dart:65-68` — заменить `DateTime.now()` на `nowProvider`

**Approach:**
1. В `schedule_provider.dart` добавить `nowProvider` после `selectedDayProvider`.
2. `LessonCard`: добавить `import 'package:flutter_riverpod/flutter_riverpod.dart'`, сменить базовый класс, добавить `WidgetRef ref` в `build`, читать `nowProvider`.
3. `LessonProgressBar`: параметр `required this.now`, убрать внутренний `DateTime.now()`.
4. `SyncStatusBar`: читать `nowProvider.valueOrNull ?? DateTime.now()`.

**Patterns to follow:** `lib/features/schedule/presentation/widgets/week_strip.dart` — пример `ConsumerWidget` с `ref.watch`.

**Verification:** Запустить приложение; время в SyncStatusBar обновляется каждые 30 сек. `LessonCard` меняет состояние без горячей перезагрузки.

---

### IU-3: `currentWeekProvider` + WeekStrip navigation

**Goal:** Пользователь может переключаться между неделями тапом стрелок или свайпом.

**Files:**
- `lib/features/schedule/presentation/providers/schedule_provider.dart` — добавить `_mondayOf`, `currentWeekProvider`
- `lib/features/schedule/presentation/widgets/week_strip.dart` — полная переработка: провайдер-driven monday, стрелки, свайп, лимит ±4 недели

**Approach:**

В `schedule_provider.dart`:
```dart
DateTime _mondayOf(DateTime date) =>
    date.subtract(Duration(days: date.weekday - 1));

final currentWeekProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return _mondayOf(DateTime(now.year, now.month, now.day));
});
```

В `WeekStrip.build`:
1. Читать `currentWeekProvider` вместо вычисления `monday` из `DateTime.now()`.
2. Вычислять `todayMonday = _mondayOf(today)` для проверки лимита.
3. `canGoPrev = currentMonday.isAfter(todayMonday.subtract(const Duration(days: 28)))`
4. `canGoNext = currentMonday.isBefore(todayMonday.add(const Duration(days: 28)))`
5. Обернуть содержимое в `GestureDetector(onHorizontalDragEnd: ...)`.
6. По краям добавить `IconButton(icon: Icon(Icons.chevron_left/right), onPressed: canGoPrev/canGoNext ? () => _shift(ref, -7/7) : null)`.
7. `_shift`: изменить `currentWeekProvider`, затем проверить `selectedDayProvider` — если не попадает в новую неделю, обновить до monday.

**Patterns to follow:** Текущий `WeekStrip` (week_strip.dart:38-45) — паттерн вычисления monday.

**Verification:** Тап стрелки переключает чипы на следующую неделю. Свайп влево → следующая неделя. Стрелка становится неактивной на лимите ±4 недели.

---

### IU-4: Три пустых состояния

**Goal:** Выходной, свободный день и ошибка показывают разные сообщения; ошибка имеет кнопку Retry.

**Files:**
- `lib/features/schedule/presentation/screens/schedule_screen.dart` — заменить `_EmptyDay` на три состояния, обновить `scheduleAsync.when`

**Approach:**
1. Удалить `_EmptyDay`.
2. Добавить `_WeekendState`, `_FreeDayState`, `_ErrorState`.
3. В `scheduleAsync.when(data:)`: `if (selectedDay.weekday > 5) return const _WeekendState()` перед проверкой пустого списка.
4. В `scheduleAsync.when(error:)`: вернуть `_ErrorState(error: error, onRetry: () => ref.invalidate(scheduleProvider))`.
5. `_ErrorState.build`: `switch (error)` → если `Failure` — показать тип (`NetworkFailure`/`ParseFailure`/`CacheFailure`), иначе — "Ошибка загрузки".

**Patterns to follow:** `lib/core/errors/failure.dart` — `NetworkFailure`, `ParseFailure`, `CacheFailure`.

**Verification:** Суббота/воскресенье показывают "Выходной". Будний день без пар — "Нет пар — свободный день". Симулируемая ошибка — сообщение + кнопка "Повторить".

## Technical Considerations

- `nowProvider` использует `async*` генератор для немедленного первого `yield` — без этого первый тик будет через 30 секунд.
- `LessonProgressBar` принимает `now` как параметр — это делает виджет тестируемым через `overrides` без Clock-зависимостей.
- `currentWeekProvider` хранит только дату понедельника (нормализованную до полуночи без времени) — предотвращает ложные пересчёты.
- Лимит ±4 недели сравнивается по понедельникам (`isAfter`/`isBefore`) — не по точному timestamp.
- Порядок unit'ов важен: IU-1 (enum) → IU-2 (nowProvider) → IU-3 (weekNav) → IU-4 (emptyStates). IU-2 зависит от IU-1 (lesson_card.dart трогается в обоих).

## Acceptance Criteria

- [ ] **R1**: WeekStrip показывает стрелки ‹ / ›; тап переключает неделю на ±7 дней
- [ ] **R1**: Горизонтальный свайп выполняет то же действие
- [ ] **R1**: При смене недели `selectedDayProvider` перебрасывается на понедельник, если текущий день не в новой неделе
- [ ] **R1**: Стрелка ‹ неактивна на 4 недели назад от сегодня; › — на 4 недели вперёд
- [ ] **R2**: `nowProvider` существует в `schedule_provider.dart` как `StreamProvider<DateTime>`
- [ ] **R2**: `LessonCard` переключается в `active`/`past` без перезапуска приложения
- [ ] **R2**: `LessonProgressBar` принимает `now` как параметр и обновляет прогресс
- [ ] **R2**: `SyncStatusBar` показывает время из `nowProvider`
- [ ] **R3**: `lib/features/schedule/domain/entities/lesson_type.dart` содержит enum `LessonType`
- [ ] **R3**: `Lesson.type` имеет тип `LessonType`, не `String`
- [ ] **R3**: `_TypeBadge` использует `lesson.type.label` и `switch (lessonType)` без строковых проверок
- [ ] **R4**: Суббота/воскресенье — виджет `_WeekendState` с сообщением без Retry
- [ ] **R4**: Будний день без пар — виджет `_FreeDayState` с сообщением без Retry
- [ ] **R4**: Ошибка загрузки — виджет `_ErrorState` с описанием типа ошибки и кнопкой "Повторить"
- [ ] `flutter analyze` проходит без ошибок

## Dependencies & Risks

- **Зависимость IU-2 от IU-1**: `lesson_card.dart` редактируется в обоих unit'ах. Применять последовательно.
- **Merge conflict**: `schedule_screen.dart` и `CLAUDE.md` имеют конфликты между HEAD и feature-ветке. Разрешить перед первым коммитом.
- **Mock data**: `ScheduleRepositoryImpl._buildMockDays()` генерирует данные только для текущей недели — другие недели будут показывать пустые дни. Это ожидаемое поведение согласно scope boundaries (see origin doc).

## Scope Boundaries

- Без анимации перехода между неделями в списке пар.
- Без кэширования нескольких недель в моках.
- Без фильтрации по `LessonType`.
- Без auto-scroll к активной паре.
- Без отдельной кнопки "Сегодня".

## Sources & References

### Origin

- **Origin document:** [docs/brainstorms/2026-03-30-schedule-screen-improvements-requirements.md](../brainstorms/2026-03-30-schedule-screen-improvements-requirements.md)
  Key decisions carried forward:
  - Свайп + стрелки для навигации (самое натуральное мобильное взаимодействие)
  - Единый `nowProvider` — один источник времени для всех виджетов
  - `LessonType` в domain, не в UI

### Internal References

- `lib/features/schedule/presentation/providers/schedule_provider.dart` — добавить 2 провайдера
- `lib/features/schedule/presentation/widgets/week_strip.dart:38-45` — текущий паттерн вычисления monday
- `lib/features/schedule/presentation/widgets/timeline/lesson_card/lesson_card.dart` — `_TypeBadge` переработка
- `lib/core/errors/failure.dart` — `NetworkFailure`, `ParseFailure`, `CacheFailure` для R4
- `lib/features/schedule/data/repositories/schedule_repository_impl.dart` — 13 callsites для IU-1
