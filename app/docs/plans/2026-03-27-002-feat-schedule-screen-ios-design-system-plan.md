---
title: "feat: Implement schedule screen with iOS design system"
type: feat
status: active
date: 2026-03-27
origin: docs/brainstorms/2026-03-27-schedule-screen-requirements.md
---

# feat: Implement schedule screen with iOS design system

## Overview

Реализовать центральный экран расписания приложения UniSched в iOS-стиле. Задача включает три слоя:
1. **Тема** — вынести цвета и стили в `core/theme/`, подключить к `MaterialApp.router`.
2. **Компоненты** — реализовать `SyncStatusBar`, `WeekStrip`, `LessonCard`, `TimelineItem`, `BreakRow`.
3. **Экран** — собрать `ScheduleScreen` из компонентов, данные из `scheduleProvider`.

(see origin: docs/brainstorms/2026-03-27-schedule-screen-requirements.md)

## Problem Statement / Motivation

Экран расписания (`schedule_screen.dart`) сейчас возвращает `Scaffold` с заглушкой `TODO`. Тема приложения задана хардкодом `ColorScheme.fromSeed(deepPurple)` в `app.dart`. `settingsProvider` не существует. Виджеты в `widgets/timeline/` либо пустые, либо возвращают `Placeholder()`. Приложение не отображает данные и не поддерживает темёмную тему.

## Proposed Solution

Реализовать послойно: сначала тема → провайдеры → мок-данные → компоненты → экран.

```
core/theme/
├── app_colors.dart       # все цветовые константы light/dark + subjectColor()
├── app_text_styles.dart  # все TextStyle константы
└── app_theme.dart        # ThemeData.light() / ThemeData.dark() фабрики

features/schedule/presentation/
├── providers/schedule_provider.dart   # + selectedDayProvider
├── widgets/
│   ├── sync_status_bar.dart           # новый
│   ├── week_strip.dart                # новый (+ DayChip)
│   ├── lesson_card.dart               # новый (+ TeacherChip, ActiveBadge, LessonProgressBar)
│   └── timeline/
│       ├── item.dart                  # заменить
│       └── break_item.dart            # заменить (пустой → BreakRow)
└── screens/schedule_screen.dart       # полная замена

features/settings/presentation/providers/settings_provider.dart  # создать
app.dart                                                          # обновить
```

## Technical Considerations

### Архитектура

- **AppColors** — класс со `static const` полями (не `ThemeExtension`). Два статических геттера: `AppColors.light` и `AppColors.dark`. Метод `AppColors.subjectColor(String subject)` делает case-insensitive проверку ключевых слов.
- **AppTheme** — статические методы `AppTheme.light()` и `AppTheme.dark()` возвращают `ThemeData` с `useMaterial3: true`, `ColorScheme`, `TextTheme` из `AppTextStyles`.
- **settingsProvider** — `NotifierProvider<SettingsNotifier, AppSettings>`. Состояние in-memory (нет `shared_preferences` в `pubspec.yaml`). `SettingsRepositoryImpl` уже возвращает `AppSettings.defaults` — безопасно. Позволяет менять тему в рамках сессии.
- **selectedDayProvider** — `StateProvider<DateTime>` в `schedule_provider.dart`, начальное значение `DateTime.now()`. WeekStrip пишет в него при тапе, ScheduleScreen читает для фильтрации уроков.
- **Sync status** — производится из `scheduleProvider`: `AsyncLoading` → синхронизация, `AsyncError` → офлайн, `AsyncData` → актуально. Отдельный провайдер не нужен (scope boundary: без реального API).
- **LessonProgressBar** — `StreamBuilder` с `Stream.periodic(const Duration(minutes: 1))`. Перестраивает только прогресс-бар, не весь `LessonCard`.
- **ActiveBadge** — opacity pulse через `AnimationController` + `AnimatedBuilder` (входит в scope: это анимация виджета, не переключение темы).
- **Mock data** — добавить `Stream.value(_mockDays)` в `ScheduleRepositoryImpl.watchSchedule`. Мок — список `ScheduleDay` на текущую неделю с несколькими уроками, один из которых совпадает с `DateTime.now()`.

### Решения по SpecFlow-пробелам

| Пробел | Решение |
|--------|---------|
| Mock data (Gap 1) | `Stream.value(_mockDays)` в `ScheduleRepositoryImpl` |
| `selectedDayProvider` (Gap 2) | `StateProvider<DateTime>` инициализирован `DateTime.now()` |
| Sync status source (Gap 3) | Производится из `AsyncValue` `scheduleProvider` (Option A) |
| ProgressBar cadence (Gap 4) | `Stream.periodic(Duration(minutes: 1))` |
| WeekStrip range (Gap 5) | Текущая календарная неделя (Пн–Вс) от `DateTime.now()` |
| Empty day state (Gap 6) | Центрированный текст "Занятий нет" |
| Subject fallback color (Gap 7) | `#8E8E93` (iOS secondary label) |
| darkTheme missing (Gap 9) | Добавить `darkTheme: AppTheme.dark()` в `app.dart` |
| settingsProvider stub (Gap 10) | `NotifierProvider` in-memory, defaults to `AppSettings.defaults` |
| Bottom padding (Gap 11) | `MediaQuery.of(context).padding.bottom + 80` вместо хардкода `100px` |

### Маппинг цвета предмета (AppColors.subjectColor)

```dart
// Ключевые слова в нижнем регистре
'матем' | 'алгебр'          → #AF52DE (purple)
'физик' | 'хими'            → #5AC8FA (teal)
'програм' | 'информ' | 'cs' → #34C759 (green)
'англий' | 'язык' | 'english' → #FF9500 (orange)
'истор' | 'философ' | 'социол' → #FF3B30 (red)
fallback                     → #8E8E93 (neutral)
```

### Анимации

- `ActiveBadge` — `AnimationController(duration: 1.5s)`, `repeat(reverse: true)`, opacity 1.0→0.3.
- Пульс точки `SyncStatusBar` — `AnimationController(duration: 2.2s)`, `repeat(reverse: true)`, scale 1.0→1.3 + opacity 1.0→0.5.
- Tap на карточку — `GestureDetector` + `AnimatedScale(scale: _pressed ? 0.98 : 1.0, duration: 120ms)`.

## System-Wide Impact

- **Interaction graph**: `SettingsNotifier.setTheme()` → `settingsProvider` rebuild → `app.dart` `ref.watch(settingsProvider)` → `MaterialApp.router` перестраивается с новым `themeMode` → все виджеты получают новый `Theme`. Запись в `selectedDayProvider` → `WeekStrip` rebuild + `ScheduleScreen` список уроков rebuild.
- **Error propagation**: `scheduleProvider` `AsyncError` → `SyncStatusBar` показывает "офлайн", `ScheduleScreen` показывает кэшированные данные или "Занятий нет". Ошибки не пробрасываются выше экрана.
- **State lifecycle**: `scheduleProvider` имеет `ref.keepAlive()` — переживает размонтирование экрана. `selectedDayProvider` — обычный `StateProvider`, сбрасывается при выходе из `ProviderScope`. Мок-данные не персистируются.

## Acceptance Criteria

- [ ] `flutter analyze` проходит без ошибок и предупреждений
- [ ] `flutter test` проходит (существующие тесты не сломаны)
- [ ] Светлая тема: фон `#F2F2F7`, карточки белые, акцент `#007AFF`
- [ ] Тёмная тема: фон `#000000`, карточки `#1C1C1E`, акцент `#0A84FF`
- [ ] `AppTheme.system` следует теме устройства
- [ ] WeekStrip показывает текущую неделю, сегодняшний день выделен accent-чипом
- [ ] Тап на DayChip обновляет список уроков на экране
- [ ] Текущий урок: `ActiveBadge` + `LessonProgressBar` с пульсом
- [ ] Прошедшие уроки: `opacity: 0.48`
- [ ] `SyncStatusBar` показывает корректное состояние (мок → "Данные актуальны")
- [ ] День без уроков показывает "Занятий нет"
- [ ] BreakRow показывается между парами с подписью длительности перерыва

## Implementation Phases

### Phase 1 — Theme Layer (R1, R2, R3)

**Файлы для создания/обновления:**

- `lib/core/theme/app_colors.dart` ← создать
- `lib/core/theme/app_text_styles.dart` ← создать
- `lib/core/theme/app_theme.dart` ← создать
- `lib/features/settings/presentation/providers/settings_provider.dart` ← заменить заглушку
- `lib/app.dart` ← обновить

**Ключевые моменты:**
- `app.dart` `ref.watch(settingsProvider)` → `.theme` → switch на `ThemeMode.system/.light/.dark`
- `MaterialApp.router(theme: AppTheme.light(), darkTheme: AppTheme.dark(), themeMode: ...)`
- `settingsProvider` = `NotifierProvider` с `SettingsNotifier extends Notifier<AppSettings>`

### Phase 2 — Mock Data + selectedDayProvider (поддержка для R5, R9)

**Файлы для обновления:**

- `lib/features/schedule/data/repositories/schedule_repository_impl.dart` ← добавить мок
- `lib/features/schedule/presentation/providers/schedule_provider.dart` ← добавить `selectedDayProvider`

**Мок-данные** — 5 дней текущей недели, по 2-4 урока в день, типы: `ЛЕК`, `ПР`, `ЛАБ`. Один урок совпадает с текущим временем для отображения `ActiveBadge`.

### Phase 3 — Компоненты (R4–R8)

Порядок разработки (по зависимостям):

1. `lib/features/schedule/presentation/widgets/sync_status_bar.dart`
   - `ConsumerWidget`, `ref.watch(scheduleProvider)` → статус
   - `AnimationController` для пульса точки (нужен `TickerProviderStateMixin` → `ConsumerStatefulWidget`)

2. `lib/features/schedule/presentation/widgets/week_strip.dart`
   - `ConsumerWidget` + `DayChip` (вложенный `StatelessWidget`)
   - Читает `selectedDayProvider`, пишет через `ref.read(...).state = day`
   - Вычисляет неделю: `startOfWeek = now.subtract(Duration(days: now.weekday - 1))`

3. `lib/features/schedule/presentation/widgets/lesson_card.dart`
   - Содержит вложенные: `_TeacherChip`, `_ActiveBadge` (с `AnimationController`), `_LessonProgressBar` (со `StreamBuilder`)
   - Принимает `Lesson lesson` + `bool isActive` + `bool isPast`

4. `lib/features/schedule/presentation/widgets/timeline/item.dart` ← заменить
   - `StatelessWidget`, принимает `Lesson`, `bool isActive`, `bool isPast`
   - Горизонтальный `Row`: `SizedBox(width: 46)` (время) + `Expanded` (LessonCard)

5. `lib/features/schedule/presentation/widgets/timeline/break_item.dart` ← создать
   - `StatelessWidget`, принимает `int breakMinutes`
   - Горизонтальная линия + текст

### Phase 4 — ScheduleScreen (R9)

- `lib/features/schedule/presentation/screens/schedule_screen.dart` ← полная замена
- `ConsumerWidget`
- Layout: `Column` → `SyncStatusBar` (fixed, не скроллится) + `WeekStrip` (fixed) + `Expanded(ListView)` (TimelineItem + BreakRow)
- Вычисление списка уроков на выбранный день:
  ```dart
  final selectedDay = ref.watch(selectedDayProvider);
  final scheduleAsync = ref.watch(scheduleProvider);
  // filter ScheduleDay where date.isOnSameDayAs(selectedDay)
  ```
- Нижний padding: `MediaQuery.of(context).padding.bottom + 80`

## Dependencies & Risks

- **`shared_preferences` отсутствует** — `settingsProvider` использует in-memory состояние. Смена темы не переживает рестарт приложения. Это известное ограничение, зафиксированное в CLAUDE.md как "planned dependency".
- **`ScheduleRepositoryImpl` возвращает мок** — реальная синхронизация с сервером не реализована. Мок нужно пометить комментарием `// TODO: replace with real sync` чтобы не забыть.
- **AnimationController** требует `TickerProvider` → `SyncStatusBar` и `ActiveBadge` должны быть `ConsumerStatefulWidget` или использовать `SingleTickerProviderStateMixin`. Это единственное место в кодовой базе с `StatefulWidget` в schedule-фиче.
- **Dart SDK `^3.11.3`** — `sealed class`, `switch expressions` доступны, можно использовать.

## Sources & References

### Origin

- **Origin document:** [docs/brainstorms/2026-03-27-schedule-screen-requirements.md](../brainstorms/2026-03-27-schedule-screen-requirements.md)
  - Key decisions carried forward: (1) AppColors как static const, не ThemeExtension; (2) subjectColor по ключевым словам; (3) компоненты в `features/schedule/presentation/widgets/`

### Internal References

- `lib/features/schedule/domain/entities/lesson.dart` — поля `Lesson`
- `lib/features/schedule/presentation/providers/schedule_provider.dart` — паттерн `StreamProvider` + `ref.keepAlive()`
- `lib/features/settings/domain/entities/app_settings.dart` — `AppTheme` enum, `AppSettings.defaults`
- `lib/core/extensions/date_time_extensions.dart` — `.isToday` доступен

### SpecFlow Analysis

- Gap 1 (mock data), Gap 2 (selectedDayProvider), Gap 3 (sync status), Gap 4 (progress update), Gap 5 (week range), Gap 6 (empty state), Gap 7 (fallback color), Gap 9 (darkTheme), Gap 10 (settingsProvider), Gap 11 (bottom padding) — все разрешены в разделе "Решения по SpecFlow-пробелам" выше.
