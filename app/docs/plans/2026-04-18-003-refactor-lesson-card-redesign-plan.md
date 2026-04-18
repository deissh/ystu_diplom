---
title: "refactor: Redesign lesson card — spacious layout, time inside card, patronymic initials, adaptive width"
type: refactor
status: active
date: 2026-04-18
origin: docs/brainstorms/2026-04-18-lesson-card-redesign-requirements.md
---

# refactor: Redesign lesson card — spacious layout, time inside card, patronymic initials, adaptive width

## Overview

Карточки занятий переоформляются: время переносится внутрь карточки, отступы увеличиваются, аватарка преподавателя вырастает, алгоритм инициалов исправляется (фамилия + отчество). `TimelineItem` упрощается до одного `LessonCard` с ограничением ширины для широких экранов.

## Problem Frame

Карточки выглядят компактно и информационно бедно. Время вынесено в отдельную колонку, из-за чего карточка не является самодостаточным элементом. Аватарка преподавателя показывает «ИА» для «Иванов А.В.» вместо «ИВ» (фамилия + отчество). На широких экранах (планшеты ≥ 600 dp) контент растягивается на весь экран.

## Requirements Trace

- R1. Время начала и окончания отображается внутри карточки в формате `09:50 – 11:25`
- R2. `TimelineItem` убирает внешнюю колонку времени; карточка занимает всю доступную ширину
- R3. Внутренние отступы карточки увеличиваются для просторного вида
- R4. Порядок элементов: время → [бейдж + название] → [аватарка + аудитория] → (активное: ActiveBadge + ProgressBar)
- R5. Инициалы аватарки = фамилия[0] + отчество[0]; работает для обоих форматов (`А.В.` и полного имени)
- R6. Размер аватарки 28–32 dp вместо 22 dp
- R7. На узких экранах (< 360 dp) нет переполнения: тест предмета — 2 строки max, имя преподавателя — ellipsis
- R8. На широких экранах (≥ 600 dp) ширина ограничена на уровне `TimelineItem` через `AppLayout.maxContent(context)`

## Scope Boundaries

- Цветовая схема карточек и левая полоса не меняются
- Новые поля в сущность `Lesson` не добавляются
- `WeekStrip`, `BreakRow`, `SyncStatusBar` не затрагиваются
- Анимации карточек (появление, свайп) — вне скоупа
- `schedule_ui_helpers.dart` — не меняется (только потребители `TimelineItem`)

## Context & Research

### Relevant Code and Patterns

- `lib/features/schedule/presentation/widgets/timeline/item.dart` — текущий `TimelineItem`: 48 dp колонка + `LessonCard`; содержит `@Preview`, который нужно обновить; `_fmt()` переедет в `lesson_card.dart`
- `lib/features/schedule/presentation/widgets/timeline/lesson_card/lesson_card.dart` — текущий padding `fromLTRB(10, 10, 12, 10)`; subject уже имеет `maxLines: 2, overflow: TextOverflow.ellipsis`
- `lib/features/schedule/presentation/widgets/timeline/lesson_card/teacher_chip.dart` — аватарка 22 dp; инициалы из первых двух пробел-разделённых слов; текст без overflow-защиты
- `lib/core/layout/app_layout.dart` — `maxContent()` определён (680/720 dp), но нигде не вызывается в приложении — `TimelineItem` станет первым потребителем
- `lib/features/schedule/presentation/utils/schedule_ui_helpers.dart` — `buildScheduleItems()` — единственный эмиттер `TimelineItem`; используется в `schedule_screen.dart` и `calendar_screen.dart`
- Паттерн цветов: `AppColors.resolve(context, light, dark)` везде; `Theme.of(context).brightness` только для `cardShadow` — оставить как есть
- Паттерн overflow: только в `lesson_card.dart` (subject), `TextOverflow.ellipsis` + `maxLines` как int

### Institutional Learnings

- `docs/solutions/` не существует в проекте — институциональных учений нет

### External References

- Не применимо — кодовая база имеет достаточно паттернов для всех аспектов работы

## Key Technical Decisions

- **`_fmt` переезжает в `lesson_card.dart`**: `TimelineItem` больше не отображает время, поэтому `_fmt` будет нужен только в `LessonCard`. Копируем как `_fmtTime` (или с тем же именем) и удаляем из `item.dart`.
- **Алгоритм инициалов через split по `[ .]`**: разбиваем строку по regex `[ .]`, фильтруем пустые токены, берём token[0][0] + token[2][0] если есть, иначе token[0][0]. Это корректно обрабатывает и «Иванов А.В.» → ["Иванов","А","В",""] → "ИВ", и «Иванов Александр Владимирович» → ["Иванов","Александр","Владимирович"] → "ИВ".
- **`ConstrainedBox` в `TimelineItem` без дополнительного `Padding`**: `ListView` в `schedule_screen` уже несёт `AppLayout.hPad` как padding — добавлять Padding внутри `TimelineItem` нельзя (двойной отступ). Только `ConstrainedBox(maxWidth: AppLayout.maxContent(context))` с `Center`.
- **Размер шрифта инициалов**: при аватарке 28–32 dp текущие 8 sp слишком малы. Применяем `.copyWith(fontSize: 10)` в `TeacherChip` — переопределяем только размер, цвет white остаётся из `AppTextStyles.teacherInitials`.
- **`@Preview` в `item.dart` обновляется**: после удаления колонки времени превью должно отражать новый вид — просто карточка на всю ширину с временем внутри.

## Open Questions

### Resolved During Planning

- **Нужно ли менять `schedule_ui_helpers.dart`?** Нет — эта утилита только строит список `TimelineItem` виджетов; сам `TimelineItem` меняется, а не его вызов.
- **Не создаст ли `ConstrainedBox` двойной отступ с `hPad` ListView?** Нет — `ConstrainedBox` ограничивает только ширину контента, горизонтальные отступы остаются у родительского `ListView`.
- **Нужно ли обновлять `AppTextStyles`?** Нет — изменение размера шрифта инициалов делается через `.copyWith` в вызывающем виджете.

### Deferred to Implementation

- **Точный размер аватарки (28, 30 или 32 dp)**: выбирается при реализации исходя из визуального баланса с новыми отступами карточки.
- **Точные значения отступов карточки**: текущие `fromLTRB(10, 10, 12, 10)` → целевые `fromLTRB(12, 14, 14, 14)` или `fromLTRB(12, 12, 14, 12)` — уточняется при визуальной проверке.
- **Реальный формат поля `teacher` из API**: сейчас используются моковые данные формата «Иванов А.В.». При подключении реального API нужно убедиться, что алгоритм корректен для фактических данных.

## High-Level Technical Design

> *Это иллюстрация предполагаемого подхода — ориентировочное руководство для ревью, не спецификация для реализации.*

### Структура карточки после редизайна

```
TimelineItem
└── Center
    └── ConstrainedBox(maxWidth: AppLayout.maxContent(context))
        └── LessonCard
            ├── Left strip (4 dp, subject color)
            └── Column (padding: ~12–14 dp со всех сторон)
                ├── Row: "09:50 – 11:25"  ← НОВОЕ
                ├── SizedBox(height: 6)
                ├── Row: [_TypeBadge] [SizedBox(7)] [subject name, maxLines:2]
                ├── SizedBox(height: 8)
                ├── Row: [Expanded → TeacherChip] [SizedBox(8)] [📍 room]
                └── (if active): SizedBox(8) + ActiveBadge + SizedBox(6) + LessonProgressBar
```

### Алгоритм инициалов

```
tokens = teacher.split(RegExp(r'[ .]')).where(s => s.isNotEmpty).toList()
if tokens.isEmpty: return ''                // guard: пустая строка / пробелы
result = tokens[0][0]                       // фамилия
if tokens.length >= 3: result += tokens[2][0]  // отчество
else if tokens.length >= 2: result += tokens[1][0]  // fallback: имя
```

## Implementation Units

- [ ] **Unit 1: Исправить TeacherChip**

**Goal:** Обновить алгоритм инициалов (фамилия + отчество), увеличить аватарку, добавить overflow-защиту на имя преподавателя.

**Requirements:** R5, R6, R7 (частично)

**Dependencies:** Нет по коду; визуальный размер аватарки (28–32 dp) финализируется совместно с Unit 2 при визуальной проверке

**Files:**
- Modify: `lib/features/schedule/presentation/widgets/timeline/lesson_card/teacher_chip.dart`

**Approach:**
- Переписать `_initials(String name)`: разбивать строку по regex `[ .]`, фильтровать пустые токены; если токенов нет — вернуть `''`; брать tokens[0][0] + tokens[2][0] если tokens.length ≥ 3, иначе tokens[0][0] + tokens[1][0] если ≥ 2, иначе tokens[0][0]
- Изменить `width`/`height` аватарки с 22 на финальное значение (28–32 dp, точно при реализации)
- Имя преподавателя (`Text(teacher, ...)`) обернуть в `Flexible`, добавить `maxLines: 1, overflow: TextOverflow.ellipsis` — без `Flexible` `ellipsis` не сработает, т.к. внутренний `Row` использует `mainAxisSize: MainAxisSize.min` и не даёт `Text` ограниченную ширину
- На `Text(_initials(...), ...)` применить `.copyWith(fontSize: 10)` поверх `AppTextStyles.teacherInitials` (базовый стиль содержит `color: Colors.white`, `.copyWith` его сохраняет)

**Patterns to follow:**
- `lesson_card.dart` строки 83–84: `maxLines: 2, overflow: TextOverflow.ellipsis` — та же схема для текста преподавателя
- `.copyWith(color: label3)` на `teacherName` — аналогично применяем `.copyWith(fontSize: 10)` на `teacherInitials`

**Test scenarios:**
- Happy path: «Иванов А.В.» → инициалы «ИВ» (не «ИА»)
- Happy path: «Петрова Мария Сергеевна» → «ПС»
- Edge case: одно слово «Иванов» → «И» (без падения)
- Edge case: имя с двойным пробелом / trailing пробел → не падает
- Edge case: пустая строка → возвращает пустую строку или «?», не бросает исключение
- Happy path: имя преподавателя с длинным именем отображается с `ellipsis` без overflow

**Verification:**
- Аватарка показывает «ИВ» для «Иванов А.В.» в Widget Preview или ручном тесте
- Длинное имя обрезается точками вместо переполнения

---

- [ ] **Unit 2: Переработать LessonCard**

**Goal:** Добавить строку времени внутрь карточки, увеличить отступы, обновить порядок элементов.

**Requirements:** R1, R3, R4, R7 (частично)

**Dependencies:** Unit 1 (TeacherChip уже готов — его размер влияет на визуальный баланс карточки)

**Files:**
- Modify: `lib/features/schedule/presentation/widgets/timeline/lesson_card/lesson_card.dart`

**Approach:**
- Скопировать `_fmt(DateTime dt)` из `item.dart` в `lesson_card.dart` (переименовать в `_fmtTime` или оставить `_fmt`)
- В `Column` добавить строку времени первой: `Text('${_fmtTime(lesson.startTime)} – ${_fmtTime(lesson.endTime)}', style: AppTextStyles.timeStart.copyWith(color: label3))`, затем `SizedBox(height: 6)`
- Увеличить `padding` с `fromLTRB(10, 10, 12, 10)` до `fromLTRB(12, 14, 14, 14)` (точные значения — при реализации)
- Увеличить `SizedBox(height: 6)` между бейджем и строкой teacher/room до 8 dp
- Не трогать `_TypeBadge`, цветовую полосу, `ActiveBadge`, `LessonProgressBar`

**Patterns to follow:**
- `AppColors.resolve(context, light, dark)` для всех цветов — уже используется в файле
- `AppTextStyles.timeStart` / `AppTextStyles.timeEnd` уже определены — выбираем один стиль для строки времени

**Test scenarios:**
- Happy path: строка времени «09:50 – 11:25» присутствует в виджете над названием предмета
- Happy path: активная карточка показывает время + ActiveBadge + ProgressBar без overlap
- Happy path: прошедшая карточка (opacity 0.48) корректно показывает время
- Edge case: очень длинное название предмета (> 40 символов) — не ломает layout, переносится на 2 строки
- Edge case: `startTime == endTime` (нулевая длительность) — строка времени выводится без краша

**Verification:**
- Карточка визуально выше и просторнее, чем прежде
- Время видно сразу без обращения к внешней колонке

---

- [ ] **Unit 3: Упростить TimelineItem + адаптивность**

**Goal:** Убрать внешнюю колонку времени, добавить `ConstrainedBox` для широких экранов, обновить `@Preview`.

**Requirements:** R2, R8

**Dependencies:** Unit 2 (время должно быть в карточке до удаления колонки из `TimelineItem`)

**Files:**
- Modify: `lib/features/schedule/presentation/widgets/timeline/item.dart`

**Approach:**
- Убрать 48 dp `SizedBox` с колонкой времени и `SizedBox(width: 10)` разделитель — весь `Row` становится просто `LessonCard`
- Обернуть `LessonCard` в `Center` → `ConstrainedBox(constraints: BoxConstraints(maxWidth: AppLayout.maxContent(context)))`: на узких экранах `maxContent` возвращает `infinity` → нет ограничения; на ≥ 600 dp — 680/720 dp
- Убрать приватный `_fmt` из `item.dart` (он перенесён в `lesson_card.dart`; grep подтверждает единственное вхождение в `item.dart` — `flutter analyze` также выдаст warning на неиспользуемый private метод)
- Обновить `previewLecture()`: убрать устаревшую колонку времени — превью должно отражать новый вид. **Важно:** перед обновлением `@Preview` проверить, что `import 'package:flutter/widget_previews.dart'` разрешается в текущей сборке (импорт присутствует и в `sync_status_bar.dart`); если это экспериментальный/stub API, оставить как есть без изменений или удалить аннотацию
- Добавить `import` для `AppLayout` если ещё нет

**Patterns to follow:**
- `AppLayout.hPad(context)` — паттерн в `schedule_screen.dart` строки 54–58 (уже используется на уровне ListView)
- `AppLayout.maxContent(context)` — паттерн из docstring в `app_layout.dart`

**Test scenarios:**
- Happy path: на экране 375 dp `LessonCard` занимает всю доступную ширину (без ограничений `maxContent`)
- Happy path: на экране 768 dp `LessonCard` ограничена до 680 dp и центрирована
- Integration: `buildScheduleItems()` возвращает `TimelineItem` без крэша после рефакторинга
- Edge case: `@Preview` рендерится без ошибок с новой структурой (без `_fmt`)

**Verification:**
- На широком экране карточка не растягивается на весь экран
- Нет двойного горизонтального отступа (ListView.padding + TimelineItem.padding)
- `flutter analyze` не выдаёт предупреждений

## System-Wide Impact

- **Interaction graph:** `buildScheduleItems()` в `schedule_ui_helpers.dart` используется в `ScheduleScreen` и `CalendarScreen` — оба экрана автоматически получают новый вид
- **Error propagation:** `_fmt` переезжает из `item.dart` в `lesson_card.dart`. После переноса его нужно удалить из `item.dart` — grep подтверждает единственное вхождение; `flutter analyze` также предупредит об неиспользуемом private методе
- **State lifecycle risks:** `LessonCard` — `ConsumerWidget`, смотрит `nowProvider`; добавление строки времени — pure display, без новых подписок
- **API surface parity:** `TeacherChip` и `LessonCard` — внутренние виджеты без экспортируемого API; `TimelineItem` — вызывается только через `buildScheduleItems()`, его публичный конструктор `{required this.lesson}` не меняется
- **Unchanged invariants:** сущность `Lesson`, `AppColors`, `AppTextStyles`, `BreakRow`, `WeekStrip`, `SyncStatusBar` — не меняются

## Risks & Dependencies

| Риск | Митигация |
|------|-----------|
| Двойной горизонтальный отступ (hPad у ListView + Padding внутри TimelineItem) | Использовать только `ConstrainedBox` без добавления `Padding` в `TimelineItem` |
| Алгоритм инициалов сломается при нестандартном формате имён из реального API | Добавить guard на пустые токены; fallback на одну букву; проверить при подключении реального парсера |
| `package:flutter/widget_previews.dart` не разрешается в стандартной сборке | Перед обновлением `@Preview` проверить `flutter analyze` — если импорт уже вызывает ошибку, удалить аннотацию; если проходит — оставить |
| `_fmt` остался в `item.dart` после переноса | `flutter analyze` выдаст warning на неиспользуемый private метод — ориентир при верификации Unit 3 |
| Карточка стала слишком высокой на маленьких экранах с активным занятием | Визуальная проверка на 375 dp с ActiveBadge + ProgressBar — оба занимают место |

## Sources & References

- **Origin document:** [docs/brainstorms/2026-04-18-lesson-card-redesign-requirements.md](docs/brainstorms/2026-04-18-lesson-card-redesign-requirements.md)
- Target files: `lib/features/schedule/presentation/widgets/timeline/item.dart`, `lesson_card/lesson_card.dart`, `lesson_card/teacher_chip.dart`
- Layout helper: `lib/core/layout/app_layout.dart`
- Entry point: `lib/features/schedule/presentation/utils/schedule_ui_helpers.dart`
