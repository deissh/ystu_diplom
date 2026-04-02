---
date: 2026-03-30
topic: schedule-screen-improvements
focus: Что еще не хватает, что можно улучшить и изменить на экране с расписанием?
---

# Ideation: Улучшения экрана расписания

## Codebase Context

- Flutter / Riverpod / Drift / GoRouter
- Экран расписания: `WeekStrip` (только текущая неделя, нет nav), `SyncStatusBar`, `LessonCard` + `TeacherChip` / `ActiveBadge` / `LessonProgressBar`, `TimelineItem`, `BreakRow`
- `Lesson` entity: `subject`, `teacher`, `room`, `type: String` (ЛЕК/ПР/ЛАБ), `startTime`, `endTime`
- `ScheduleScreen` фильтрует по `selectedDayProvider`, единое пустое состояние "Нет пар"
- `LessonCard` вызывает `DateTime.now()` в `build()` — stale state
- `SyncStatusBar` время не тикает
- Drift schema v1 — нет полей `subgroup`, `weekType`

## Ranked Ideas

### 1. Навигация по неделям (currentWeekProvider)
**Description:** Добавить `currentWeekProvider: StateProvider<DateTime>` (хранит понедельник отображаемой недели). WeekStrip получает стрелки ← / → для перехода на предыдущую/следующую неделю. `selectedDayProvider` остаётся прежним — навигация по дням внутри недели не меняется.
**Rationale:** Без навигации по неделям приложение показывает только текущую неделю — пользователь не может планировать и смотреть вперёд. Это критический missing feature.
**Downsides:** Нужно убедиться, что mock-данные охватывают несколько недель или честно показывают "нет данных".
**Confidence:** 95%
**Complexity:** Medium
**Status:** Explored → `/ce:brainstorm` 2026-03-30

### 2. `nowProvider` — реактивные часы
**Description:** `StreamProvider<DateTime>` тикает раз в минуту. `LessonCard`, `LessonProgressBar`, `SyncStatusBar` наблюдают провайдер вместо прямого вызова `DateTime.now()` в `build()`. Прогресс-бар начинает реально двигаться. В тестах переопределяется через `overrides`.
**Rationale:** Stale active-state и застывший прогресс-бар подрывают доверие к приложению. Один провайдер решает три проблемы одновременно.
**Downsides:** `LessonCard` становится `ConsumerWidget` (был `StatelessWidget`). Минимальный overhead.
**Confidence:** 98%
**Complexity:** Low
**Status:** Explored → `/ce:brainstorm` 2026-03-30

### 3. `LessonType` enum
**Description:** `final String type` → `enum LessonType { lecture, practice, lab, other }` с `displayLabel` (ЛЕК/ПР/ЛАБ), `color(BuildContext)`, `fromString(String)`. `_TypeBadge` в `LessonCard` использует enum-свойства. `LessonModel.toEntity()` вызывает `LessonType.fromString`.
**Rationale:** Компилятор ловит опечатки. Каждый новый потребитель типа (фильтр, экспорт, статистика) получает правильное поведение автоматически. 40 строк кода закрывают целый класс ошибок.
**Downsides:** Требует обновления `LessonModel`, всех тестов и mock-данных.
**Confidence:** 97%
**Complexity:** Low
**Status:** Explored → `/ce:brainstorm` 2026-03-30

### 4. Три разных пустых состояния
**Description:** Вместо одного `_EmptyDay` — три виджета: `_WeekendState` ("Выходной день — отдыхай 🎉"), `_FreeDayState` ("Нет пар — свободный день"), `_ErrorState(failure, onRetry)` с описанием ошибки и кнопкой Retry. Выбор зависит от `isWeekend(selectedDay)` и `scheduleAsync` состояния.
**Rationale:** Тихая ошибка ("Нет пар" при сетевом сбое) подрывает доверие. Студент считает, что занятий нет, а на самом деле данные не загрузились.
**Downsides:** Нужно использовать `Failure` из domain (уже есть `NetworkFailure`, `ParseFailure`, `CacheFailure`).
**Confidence:** 96%
**Complexity:** Low
**Status:** Explored → `/ce:brainstorm` 2026-03-30

### 5. Детальный экран пары
**Description:** Тап по `LessonCard` → `/schedule/lesson/:id` с полным именем преподавателя, корпусом/этажом аудитории, полем для заметок пользователя. GoRouter уже настроен.
**Rationale:** Поверхность карточки — мёртвое пространство без действий. Детальный экран — естественный следующий шаг.
**Downsides:** Требует нового маршрута, нового экрана, расширения `Lesson` entity.
**Confidence:** 85%
**Complexity:** Medium
**Status:** Unexplored

### 6. Плотность пар в WeekStrip
**Description:** Вместо бинарной точки-индикатора — мини-бар из N сегментов (1–6+). Понедельник с 7 парами визуально отличается от пятницы с 2. Данные уже загружены в `scheduleProvider`.
**Rationale:** Точка говорит "есть пары". Бар говорит "тяжёлый день". Когнитивная нагрузка планирования снижается.
**Downsides:** Нужно пересчитывать плотность при загрузке данных.
**Confidence:** 88%
**Complexity:** Low
**Status:** Unexplored

### 7. `subgroup` + `weekType` в Lesson entity и Drift schema
**Description:** Добавить nullable `String? subgroup` и `bool? isOddWeek` в `Lesson` и `LessonsTable`. Исправить `uniqueKeys` в Drift (сейчас дедуплицирует по `{groupId, startTime, subject}` без учёта подгруппы).
**Rationale:** Российские расписания почти всегда чётные/нечётные + подгруппы. Schema на v1 без пользовательских данных — добавить поля бесплатно. После — потребуется migration.
**Downsides:** Потребует изменения парсера и mock-данных для тестирования.
**Confidence:** 92%
**Complexity:** Low
**Status:** Unexplored

## Rejection Summary

| # | Idea | Reason Rejected |
|---|------|-----------------|
| 1 | AppColors.subjectColor как pluggable provider | YAGNI — 5 категорий, нет реальных данных |
| 2 | Route-addressable selectedDay | Нет sharing use case для диплома |
| 3 | Multi-profile overlay | V2 feature, требует data-layer переработки |
| 4 | Continuous vertical timeline (kill WeekStrip) | Слишком радикально, сломает весь текущий экран |
| 5 | "What do I do next" как главный экран | Новый экран/маршрут, не улучшение текущего |
| 6 | Behavioral demands metadata (что принести) | Спекулятивно, нет UX-дизайна |
| 7 | Per-lesson staleness indicators | Требует `syncedAt` field + UI, высокая сложность при малой ценности сейчас |
| 8 | Teacher/room tappable affordances | Нет backend teacherId/roomId — affordance без назначения |
| 9 | Cancellation/exception fields in Lesson | API-контракт ещё не определён |

## Session Log
- 2026-03-30: Initial ideation — 30 идей (4 агента × ~7-8), 22 уникальных после дедупликации, 7 выживших. Выбраны идеи #1+#2+#3+#4 для `/ce:brainstorm`.
