---
date: 2026-03-27
updated: 2026-03-30
topic: schedule-screen
---

# Экран расписания UniSched

## Problem Frame

Экран расписания — центральный экран приложения. Тема, SyncStatusBar и WeekStrip уже реализованы. Нужно достроить оставшиеся компоненты тайм-лайна и собрать финальный экран с данными из мок-репозитория.

## Текущее состояние

| Компонент | Статус |
|---|---|
| `AppColors`, `AppTextStyles`, `AppTheme` | ✓ готово |
| `SyncStatusBar` | ✓ готово |
| `WeekStrip` + `_DayChip` | ✓ готово |
| `scheduleProvider`, `selectedDayProvider` | ✓ готово |
| Мок-данные (`ScheduleRepositoryImpl`) | ✓ готово (5 дней, активная пара в среду) |
| `TimelineItem` | ⚠ заглушка (`Placeholder`) |
| `LessonCard` + субкомпоненты | ✗ не реализовано |
| `BreakRow` | ✗ не реализовано |
| `ScheduleScreen` (финальная сборка) | ✗ не реализовано |

## Requirements

- R1. **LessonCard** — `timeline/lesson_card/lesson_card.dart`. Левая цветная полоска (4 px) по `AppColors.subjectColor(lesson.subject)`. Белый/surface контейнер с `borderRadius: 12`. Завершённые пары — `Opacity(0.48)`. Содержит `TeacherChip`, `ActiveBadge` (только если пара идёт сейчас), `LessonProgressBar` (только если пара идёт сейчас).
- R2. **TeacherChip** — `timeline/lesson_card/teacher_chip.dart`. Компактный чип: иконка `person_outline` + `lesson.teacher`. Отдельный виджет, переиспользуемый внутри `LessonCard`.
- R3. **ActiveBadge** — `timeline/lesson_card/active_badge.dart`. Пульсирующая точка (анимация opacity + scale, 2200 ms) + текст "Сейчас идёт". Accent-цвет. Показывается только когда `now` между `startTime` и `endTime`.
- R4. **LessonProgressBar** — `timeline/lesson_card/lesson_progress_bar.dart`. Gradient `accent → teal` (LinearGradient). Подписи "Прошло X мин / Осталось Y мин". Прогресс = `(now - start) / (end - start)`, clamp 0..1. Показывается только для активной пары.
- R5. **TimelineItem** — `timeline/item.dart`. Строка: колонка времени (48 px, `startTime` + `endTime`) + `LessonCard`. Принимает `Lesson lesson`. Вертикальная separator-линия (`AppColors.separator`) между парами не входит в `TimelineItem` — рисуется в списке `ScheduleScreen`.
- R6. **BreakRow** — `timeline/break_row.dart`. Горизонтальная линия + текст "Перерыв N мин" по центру. Принимает `int minutes`. Цвет: `label3`.
- R7. **ScheduleScreen** — финальная сборка `schedule_screen.dart`. Фиксированный header: `SyncStatusBar` (8 px margin top) → `WeekStrip` (8 px gap). Скроллируемое тело: `ListView` с `TimelineItem` и `BreakRow` между парами. Данные: `scheduleProvider` фильтруется по `selectedDayProvider`. Нижний padding 100 px под tab bar. Пустое состояние: текст "Нет пар" по центру.

## Структура файлов

```
lib/features/schedule/presentation/widgets/
├── sync_status_bar.dart          ✓
├── week_strip.dart               ✓
└── timeline/
    ├── item.dart                 (переписать, сейчас заглушка)
    ├── break_row.dart            (создать)
    └── lesson_card/
        ├── lesson_card.dart      (создать)
        ├── teacher_chip.dart     (создать)
        ├── active_badge.dart     (создать)
        └── lesson_progress_bar.dart  (создать)
```

## Success Criteria

- `flutter analyze` проходит без ошибок
- Экран показывает пары выбранного дня (из `selectedDayProvider`)
- Активная пара выделена: `ActiveBadge` + `LessonProgressBar` видны
- Завершённые пары затемнены (`Opacity(0.48)`)
- Между парами показывается `BreakRow` с реальным временем перерыва
- Пустой день показывает "Нет пар"
- Светлая и тёмная тема работают корректно

## Scope Boundaries

- Без реального API — только `ScheduleRepositoryImpl` с моками
- Без навигации в детальную карточку пары
- Без анимации переключения дня
- ExamCard, BottomNavBar — отдельные задачи

## Key Decisions

- **Структура папок**: вложенная `timeline/lesson_card/` — отдельный файл на каждый субкомпонент
- **ActiveBadge и LessonProgressBar**: показываются только внутри `LessonCard` когда пара активна — определяется по `DateTime.now()` относительно `lesson.startTime/endTime`
- **Separator между парами**: рисуется в `ScheduleScreen` (не в `TimelineItem`), т.к. не нужен после последней пары

## Next Steps

→ `/ce:work` для реализации
