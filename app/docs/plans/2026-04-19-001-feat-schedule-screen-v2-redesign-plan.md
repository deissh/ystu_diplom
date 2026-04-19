---
title: "feat: Schedule Screen v2 — greeting header, section label, external time column, card layout"
type: feat
status: active
date: 2026-04-19
origin: docs/brainstorms/2026-04-18-schedule-screen-v2-redesign-requirements.md
---

# feat: Schedule Screen v2 Redesign

## Overview

Приводим экран расписания в соответствие с целевым макетом. Пять изменений:
1. Персонализированный заголовок с приветствием, датой и иконкой уведомлений.
2. `WeekStrip` без кнопок-стрелок (только свайп).
3. Метка секции "СЕГОДНЯ • N ПАР" над списком занятий.
4. Время занятия переносится во внешнюю левую колонку `TimelineItem`.
5. `LessonCard` — тип занятия в правый угол, бейдж "ЗАВЕРШЕНО" для прошедших.

## Problem Frame

Текущий экран расписания (Image 2) не соответствует целевому макету (Image 1) по четырём визуальным направлениям. Изменения носят исключительно presentational-характер: данные и бизнес-логика не затрагиваются.

(см. origin: `docs/brainstorms/2026-04-18-schedule-screen-v2-redesign-requirements.md`)

## Requirements Trace

- R1. Приветствие "Привет, [Имя]! 👋" над `SyncStatusBar`.
- R2. Строка с текущей датой под приветствием: "День недели, D месяца".
- R3. Иконка колокольчика справа от приветствия, без обработчика.
- R4. Имя из `Profile.displayName`; при отсутствии — "Привет! 👋".
- R5. Кнопки-стрелки `WeekStrip` удалены; навигация только свайпом.
- R6. Метка "СЕГОДНЯ • N ПАР" / "ДН, D МЕС • N ПАР" перед списком занятий.
- R7. Время занятия в внешней левой колонке ~52 dp в `TimelineItem`.
- R8. `LessonCard` не рендерит строку времени; `nowProvider`, `isActive`, `isPast` сохраняются.
- R9. Бейдж типа занятия — в правом верхнем углу карточки (справа от названия).
- R10. Бейдж "ЗАВЕРШЕНО" для прошедших занятий; `Opacity(0.48)` сохраняется.

## Scope Boundaries

- Функциональность уведомлений (колокольчик — только иконка).
- Цветовая схема карточек и левая цветная полоска.
- Формат данных `teacher`, `room`.
- Анимации карточек.
- Нижняя навигационная панель.
- `CalendarScreen` и его взаимодействие с `buildScheduleItems`.

## Context & Research

### Relevant Code and Patterns

- `lib/features/schedule/presentation/screens/schedule_screen.dart` — хост-экран; Column содержит SyncStatusBar, WeekStrip, ListView.
- `lib/features/schedule/presentation/widgets/week_strip.dart` — стрелки (`IconButton`) для удаления; свайп-обработчик `onHorizontalDragEnd` уже проверяет `canGoPrev`/`canGoNext`.
- `lib/features/schedule/presentation/widgets/timeline/item.dart` — текущий `Center(ConstrainedBox(LessonCard))`; реструктурируется в `Row([_TimeColumn, Expanded(LessonCard)])`.
- `lib/features/schedule/presentation/widgets/timeline/lesson_card/lesson_card.dart` — удаляется `Text` с временем; `_TypeBadge` переезжает вправо; добавляется `_CompletedBadge`.
- `lib/features/schedule/presentation/utils/schedule_ui_helpers.dart` — `buildScheduleItems` shared с `CalendarScreen`; сигнатура не меняется.
- `lib/features/profile/presentation/providers/profile_provider.dart` — `profileNotifierProvider`: `AsyncNotifierProvider<ProfileNotifier, Profile?>`. Паттерн доступа: `ref.watch(profileNotifierProvider).valueOrNull`.
- `lib/features/schedule/presentation/providers/schedule_provider.dart` — `nowProvider`: `StreamProvider<DateTime>` с тиком каждые 30 с; `selectedDayProvider`, `currentWeekProvider`.
- `lib/core/theme/app_text_styles.dart` — `screenTitle` (26sp, w700), `sectionHeader` (13sp, w600, uppercase), `timeStart`/`timeEnd`, `badge` (10sp, w600, uppercase), `meta` (12sp, w400).
- `lib/core/theme/app_colors.dart` — `label2Light/Dark` (основной текст), `label3Light/Dark` (вторичный), `AppColors.resolve(context, light, dark)`.
- `lib/core/layout/app_layout.dart` — `AppLayout.hPad(context)` для горизонтальных отступов, `AppLayout.maxContent(context)` для ширины.
- `pubspec.yaml` — пакет `intl ^0.20.0` уже добавлен (используется `table_calendar`); доступен для `DateFormat` при необходимости.

### Institutional Learnings

- Нет релевантных записей в `docs/solutions/`.

## Key Technical Decisions

1. **`isPast` определение**: `now.isAfter(lesson.endTime)` — то же, что уже в `LessonCard`. Для прошлых дней все занятия `isPast = true`; для будущих — `false`. Поведение корректно без дополнительных условий.

2. **Opacity + badge**: Сохраняем `Opacity(0.48)` И добавляем "ЗАВЕРШЕНО" badge. Opacity обеспечивает визуальную иерархию (прошедшие уходят на второй план); badge добавляет семантическую метку. Badge при opacity 0.48 остаётся читаемым на белом фоне.

3. **Метка секции — placement**: Рендерится над `ListView` в `Column` внутри `scheduleAsync.when(data:)`, а не внутри `buildScheduleItems`. Сигнатура `buildScheduleItems` не меняется — `CalendarScreen` не затрагивается.

4. **Метка секции — N=0**: При `lessons.isEmpty` метка не рендерится — существующие `_FreeDayState`/`_WeekendState` обрабатывают пустые состояния.

5. **Время column — ConstrainedBox**: `Row([_TimeColumn(52dp), Expanded(LessonCard)])` целиком находится внутри `ConstrainedBox(maxContent)`. На широких экранах ограничение применяется к общей ширине (время + карточка).

6. **Вертикальное выравнивание**: `CrossAxisAlignment.start` на внешнем `Row` в `TimelineItem` — время выровнено по верхнему краю карточки.

7. **Greeting — имя преподавателя**: Используем `Profile.displayName` для обоих режимов (студент и преподаватель). `teacherName` хранится в формате "Иванов А.В." — первое слово даёт фамилию, а не имя. Если `displayName` не задан — "Привет! 👋".

8. **Profile async states**: При `AsyncLoading` и `AsyncError` заголовок показывает "Привет! 👋" (та же строка, что при отсутствии имени). Спиннер не нужен.

9. **Иконка уведомлений**: `CupertinoIcons.bell` — приложение активно мигрирует на Cupertino-виджеты.

10. **Русские строки для дат**: Hardcode двух списков: `_weekdaysFull` (для R2: "Понедельник"…"Воскресенье") и `_monthsGenitive` (для R2 и R6: "января"…"декабря"). Для section label — аббревиатуры из константы (ПН/ВТ/…). `intl`-пакет доступен, но для двух статических списков не нужен.

11. **`_CompletedBadge` стиль**: Серый pill — `Container(color: label3.withOpacity(0.15), borderRadius: 6, Text("ЗАВЕРШЕНО", style: badge, color: label3))`. Аналог `_TypeBadge`, но нейтральный цвет.

12. **Порядок строк в `LessonCard` после редизайна**:
    - Строка 1: `Row([Expanded(subject Text), _TypeBadge])`
    - Строка 2 (`isPast` only): `_CompletedBadge`
    - Строка 3: `Row([Expanded(TeacherChip), room icon + room Text])`
    - Строка 4 (`isActive` only): `ActiveBadge` + `LessonProgressBar`

## Open Questions

### Resolved During Planning

- **Граничные недели при swipe**: Уже обрабатываются — `onHorizontalDragEnd` проверяет `canGoPrev`/`canGoNext` перед `_shiftWeek`. (см. origin Key Decisions)
- **N=0 для section label**: Метка не рендерится при пустом списке; существующие empty states достаточны.
- **Opacity vs badge**: Оба сохраняются. (Decision #2)
- **Badge цвет**: Серый (`label3` с alpha). (Decision #11)
- **teacher greeting**: `displayName` для обоих режимов. (Decision #7)

### Deferred to Implementation

- Точная ширина временно́й колонки (52 dp vs minIntrinsicWidth) — подобрать при наличии устройства с крупным шрифтом.
- Нужно ли обновлять `TimelineItem.previewLecture()` — зависит от того, используется ли Widget Preview в CI.

## Implementation Units

- [x] **Unit 1: ScheduleHeader widget**

**Goal:** Персонализированный заголовок с приветствием, датой и иконкой уведомлений.

**Requirements:** R1, R2, R3, R4

**Dependencies:** Нет (profileNotifierProvider уже реализован).

**Files:**
- Create: `lib/features/schedule/presentation/widgets/schedule_header.dart`
- Modify: `lib/features/schedule/presentation/screens/schedule_screen.dart`

**Approach:**
- Новый `ScheduleHeader` (ConsumerWidget); вставляется в Column ScheduleScreen первым элементом — перед `SyncStatusBar`.
- Watches `profileNotifierProvider.valueOrNull` → `Profile?`. Loading/Error → `null`.
- Greeting name: `profile?.displayName?.trim()` — если не null и не пустая → "Привет, {name}! 👋", иначе → "Привет! 👋".
- Date row: `DateTime.now()` → форматируется с помощью `_weekdaysFull[now.weekday - 1]` + `now.day.toString()` + `_monthsGenitive[now.month - 1]`. Цвет: `label3`.
- Дата не реактивна к `nowProvider` (обновление при midnight не требуется в рамках скоупа).
- Layout: `Padding(hPad, Row([Column([greetingText, dateText]), Spacer(), CupertinoButton(icon: CupertinoIcons.bell, onPressed: null)]))`.
- Вертикальный отступ сверху: `SizedBox(height: 12)` (как до SyncStatusBar).

**Patterns to follow:**
- `lib/features/schedule/presentation/widgets/sync_status_bar.dart` — ConsumerWidget, `AppColors.resolve`, `AppTextStyles`.
- Стиль greeting: `AppTextStyles.screenTitle` (26sp, w700); цвет `label2`.
- Стиль date: `AppTextStyles.meta` (12sp, w400) с цветом `label3`.

**Test scenarios:**
- Happy path: profile loaded, displayName = "Кирилл" → виджет содержит текст "Привет, Кирилл! 👋".
- Happy path: profile loaded, displayName = null → виджет содержит "Привет! 👋".
- Edge case: profileNotifierProvider в AsyncLoading → виджет содержит "Привет! 👋".
- Edge case: profileNotifierProvider в AsyncError → виджет содержит "Привет! 👋".
- Happy path: date row содержит текущий день недели и месяц на русском.
- Happy path: bell icon присутствует в дереве виджетов.

**Verification:** Заголовок отображается над SyncStatusBar; имя подставляется из профиля; дата соответствует сегодняшнему дню.

---

- [x] **Unit 2: WeekStrip — удаление кнопок-стрелок**

**Goal:** Убрать arrow-кнопки из WeekStrip; навигация по неделям только жестом.

**Requirements:** R5

**Dependencies:** Нет.

**Files:**
- Modify: `lib/features/schedule/presentation/widgets/week_strip.dart`

**Approach:**
- Удалить два блока `IconButton` (`canGoPrev ? () => _shiftWeek(ref, -7) : null` и аналог для next).
- Переменные `canGoPrev`, `canGoNext` — оставить (используются в `onHorizontalDragEnd`).
- Удалить импорты `Icons.chevron_left`/`Icons.chevron_right` если стали неиспользуемыми.
- Убедиться, что `Row` с `IconButton` заменяется на `Row(children: [Expanded(...day chips...)])` без обёртки с кнопками.

**Patterns to follow:**
- Существующий `onHorizontalDragEnd` — паттерн граничной проверки.

**Test scenarios:**
- Happy path: WeekStrip рендерится без кнопок-стрелок (нет виджетов с иконкой `chevron`).
- Happy path: swipe влево → неделя сдвигается вперёд.
- Happy path: swipe вправо → неделя сдвигается назад.
- Edge case: swipe вперёд на последней разрешённой неделе → `currentWeekProvider` не изменяется.
- Edge case: swipe назад на первой разрешённой неделе → `currentWeekProvider` не изменяется.

**Verification:** Нет `IconButton` с chevron в дереве виджетов; свайп переключает неделю.

---

- [x] **Unit 3: Section count label**

**Goal:** Метка "СЕГОДНЯ • N ПАР" / "ДН, D МЕС • N ПАР" над списком занятий.

**Requirements:** R6

**Dependencies:** Нет (использует уже вычисленные `lessons` и `isToday` в ScheduleScreen).

**Files:**
- Modify: `lib/features/schedule/presentation/screens/schedule_screen.dart`

**Approach:**
- Метка рендерится в `scheduleAsync.when(data:)` при `lessons.isNotEmpty`.
- Расположение: `Padding(EdgeInsets.fromLTRB(hPad, 0, hPad, 8), Text(labelText, style: AppTextStyles.sectionHeader, color: label3))` помещается между WeekStrip и `ListView` как отдельный `Column` child. `ListView` не меняется.
- Формат: если `isToday` → `"СЕГОДНЯ • ${lessons.length} ПАР"`.
- Иначе → `"${_dayAbbr[selectedDay.weekday - 1]}, ${selectedDay.day} ${_monthGenitive[selectedDay.month - 1].toUpperCase()} • ${lessons.length} ПАР"`.
- Константы (приватные в файле или helper): `_dayAbbr = ['ПН','ВТ','СР','ЧТ','ПТ','СБ','ВС']`; `_monthGenitive = ['ЯНВАРЯ','ФЕВРАЛЯ','МАРТА','АПРЕЛЯ','МАЯ','ИЮНЯ','ИЮЛЯ','АВГУСТА','СЕНТЯБРЯ','ОКТЯБРЯ','НОЯБРЯ','ДЕКАБРЯ']`.

**Patterns to follow:**
- `AppTextStyles.sectionHeader` — 13sp, w600, letterSpacing 0.6 (uppercase).
- `AppColors.label3Light/Dark` для цвета текста метки.

**Test scenarios:**
- Happy path (today, 6 lessons): label = "СЕГОДНЯ • 6 ПАР".
- Happy path (Monday April 20, 3 lessons): label = "ПН, 20 АПРЕЛЯ • 3 ПАР".
- Happy path (January 5, 1 lesson): label = "ВС, 5 ЯНВАРЯ • 1 ПАР".
- Edge case (lessons.isEmpty): label не рендерится; виден только empty state.
- Edge case (выходной, нет занятий): `_WeekendState`, label отсутствует.

**Verification:** Label видна над списком при наличии занятий; отсутствует при пустом дне.

---

- [x] **Unit 4: TimelineItem — внешняя временна́я колонка**

**Goal:** Структура `TimelineItem` перестраивается — время занятия переносится в левую колонку.

**Requirements:** R7

**Dependencies:** Unit 5 (LessonCard больше не рендерит время — оба юнита лучше применять вместе).

**Files:**
- Modify: `lib/features/schedule/presentation/widgets/timeline/item.dart`

**Approach:**
- Новый `build` возвращает `Center(ConstrainedBox(maxContent, IntrinsicHeight(Row([_TimeColumn(lesson), SizedBox(width: 8), Expanded(LessonCard(lesson))]))))`.
- `CrossAxisAlignment.start` на `Row`.
- `_TimeColumn` — приватный `StatelessWidget` в item.dart: фиксированная ширина `52` dp, содержит `Column([Text(startTime, style: timeStart, color: label2), Text(endTime, style: timeEnd, color: label3)])`.
- `_fmt` для форматирования времени: `'${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}'` — дублировать из LessonCard или вынести в общий helper (на усмотрение реализатора).

**Patterns to follow:**
- `AppTextStyles.timeStart` (12sp, w500) + `AppColors.label2Light/Dark` для времени начала.
- `AppTextStyles.timeEnd` (11sp, w400) + `AppColors.label3Light/Dark` для времени окончания.
- Паттерн `ConstrainedBox(maxContent)` из текущего `item.dart`.

**Test scenarios:**
- Happy path: `TimelineItem` рендерит колонку с временем слева и карточку справа.
- Happy path: колонка содержит два `Text` с корректным временем (08:30 / 10:05).
- Edge case (wide screen ≥600dp): суммарная ширина (колонка + карточка) ограничена `maxContent`.
- Edge case (узкий экран <360dp): колонка 52dp, карточка занимает оставшуюся ширину без overflow.

**Verification:** В дереве виджетов `LessonCard` не содержит Text с временем; `TimelineItem` содержит колонку с временем слева.

---

- [x] **Unit 5: LessonCard — repositioning badge, removing time, adding "Завершено" state**

**Goal:** Удалить строку времени из карточки, переместить тип занятия вправо, добавить "ЗАВЕРШЕНО" badge.

**Requirements:** R8, R9, R10

**Dependencies:** Unit 4 (оба юнита затрагивают отображение времени в одной связке).

**Files:**
- Modify: `lib/features/schedule/presentation/widgets/timeline/lesson_card/lesson_card.dart`

**Approach:**
- Удалить `Text('${_fmt(startTime)} – ${_fmt(endTime)}')` и прилегающий `SizedBox(height: 6)`. (R8)
- `ref.watch(nowProvider)`, `isActive`, `isPast` — оставить без изменений.
- Строка 1 (новая): `Row([Expanded(Text(subject, maxLines: 2, overflow: ellipsis)), SizedBox(width: 6), _TypeBadge(type)])`. (R9)
- Строка 2 (`if isPast`): `Padding(top: 4, _CompletedBadge())`. (R10)
- Строка 3 (teacher + room): без изменений.
- Строка 4 (`if isActive`): без изменений (ActiveBadge + LessonProgressBar).
- Сохранить `Opacity(0.48)` для `isPast`.

**`_CompletedBadge`** (новый приватный виджет в том же файле):
- `Container(padding: EdgeInsets.symmetric(horizontal:6, vertical:2), decoration: BoxDecoration(color: label3.withOpacity(0.12), borderRadius: 6), child: Text("ЗАВЕРШЕНО", style: badge, color: label3))`.
- Аналог `_TypeBadge` по структуре, нейтральный цвет.

**Patterns to follow:**
- Структура `_TypeBadge` как шаблон для `_CompletedBadge`.
- Существующий `Opacity(isPast ? 0.48 : 1.0)` — сохранить.

**Test scenarios:**
- Happy path (upcoming lesson): карточка содержит `[subject | badge]`, teacher+room; нет "ЗАВЕРШЕНО"; opacity = 1.0.
- Happy path (active lesson): карточка содержит `[subject | badge]`, teacher+room, `ActiveBadge`, `LessonProgressBar`; нет "ЗАВЕРШЕНО".
- Happy path (past lesson): карточка содержит `[subject | badge]`, "ЗАВЕРШЕНО", teacher+room; opacity = 0.48.
- Edge case (длинное название, 2 строки): subject переносится, `_TypeBadge` остаётся справа (не вытесняется).
- Edge case (isPast + isActive не могут быть true одновременно): только один из них true.

**Verification:** Нет строки времени внутри карточки; `_TypeBadge` справа от названия; "ЗАВЕРШЕНО" виден для прошедших занятий при opacity 0.48.

---

## System-Wide Impact

- **Interaction graph:** `buildScheduleItems` (shared с `CalendarScreen`) — сигнатура не меняется, `CalendarScreen` не затрагивается.
- **Unchanged invariants:** `BreakRow`, `SyncStatusBar`, `ActiveBadge`, `LessonProgressBar`, `TeacherChip`, `CurrentTimeIndicator` — без изменений.
- **State lifecycle risks:** Нет — все изменения чисто presentational.
- **API surface parity:** N/A.
- **Integration coverage:** После Units 4+5 запустить `flutter analyze` и проверить отсутствие `_fmt` дублирования; убедиться, что `CalendarScreen` рендерится корректно.

## Risks & Dependencies

| Риск | Митигация |
|------|-----------|
| 52dp слишком мало при системном масштабе шрифта > 1.0 | При visual-тестировании увеличить systemFontScale; при overflow использовать `FittedBox` или увеличить ширину до 56dp |
| `buildScheduleItems` shared с CalendarScreen | Сигнатура не меняется; проверить CalendarScreen после Units 4+5 |
| `_fmt` дублирован в item.dart и lesson_card.dart | Вынести в `schedule_ui_helpers.dart` или добавить в LessonType entity — на усмотрение реализатора |

## Sources & References

- **Origin document:** [docs/brainstorms/2026-04-18-schedule-screen-v2-redesign-requirements.md](docs/brainstorms/2026-04-18-schedule-screen-v2-redesign-requirements.md)
- Related code: `lib/features/schedule/presentation/` (все файлы feature-экрана)
- Prior plan (lesson card redesign): `docs/plans/2026-04-18-003-refactor-lesson-card-redesign-plan.md`
