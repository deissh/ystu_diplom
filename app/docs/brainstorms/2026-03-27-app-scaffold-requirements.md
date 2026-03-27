---
date: 2026-03-27
topic: app-scaffold
---

# Каркас приложения и базовые механизмы работы с данными

## Problem Frame

Flutter-проект создан с чистой архитектурой (domain/data/presentation), но все файлы data- и presentation-слоёв являются заглушками. Зависимости (Riverpod, Drift, Dio, GoRouter) не добавлены в `pubspec.yaml`. Без работающего каркаса невозможно разрабатывать и проверять функциональные фичи.

## Requirements

- R1. В `pubspec.yaml` добавлены зависимости: `flutter_riverpod`, `riverpod_annotation`, `drift`, `drift_flutter`, `path_provider`, `dio`, `go_router`; dev-зависимости: `build_runner`, `drift_dev`, `riverpod_generator`.
- R2. `AppDatabase` (Drift) содержит таблицу `LessonsTable` с полями, соответствующими сущности `Lesson`, версию БД `schemaVersion = 1`, и пустой список миграций `MigrationStrategy`.
- R3. `ScheduleDao` реализует методы `watchAllLessons()` (Stream) и `insertLessons(List)` с аннотациями Drift.
- R4. `databaseProvider` (`Provider<AppDatabase>`) инициализируется через `driftDatabase(name: 'ystu_schedule')` и доступен всему дереву виджетов через `ProviderScope`.
- R5. `app_router.dart` настраивает `GoRouter` с `ShellRoute`, оборачивающим три маршрута (`/schedule`, `/profile`, `/settings`) в общий `Scaffold` с `BottomNavigationBar`.
- R6. `App` в `app.dart` обёрнута в `ProviderScope`; роутер подключён через `MaterialApp.router`.
- R7. Экраны `ScheduleScreen`, `ProfileScreen`, `SettingsScreen` реализованы как `ConsumerWidget` с `Scaffold`, `AppBar` и `Center(child: Text('TODO'))`.
- R8. `schedule_provider.dart` содержит `scheduleProvider` (`StreamProvider<List<Lesson>>`), читающий из `ScheduleDao` через `databaseProvider`.
- R9. `ApiClient` (Dio) содержит метод-заглушку `fetchSchedule(String groupId)`, возвращающий пустой список.
- R10. `Parser` содержит метод-заглушку `parse(String html)`, возвращающий пустой список `Lesson`.
- R11. PWA поддержка обеспечена наличием `web/` директории с корректным `manifest.json` (Flutter создаёт её автоматически при создании проекта с `--platforms=web`).

## Success Criteria

- `flutter pub get` завершается без ошибок.
- `flutter analyze` не возвращает ошибок.
- Приложение запускается на эмуляторе/браузере и отображает 3-табовую навигацию с placeholder-экранами.
- `databaseProvider` успешно создаёт SQLite-файл при старте приложения.
- `scheduleProvider` возвращает пустой список без ошибок при старте.

## Scope Boundaries

- Реальный HTTP-запрос к API YSTU и парсинг расписания — вне скоупа.
- Дизайн и стилизация экранов — вне скоупа.
- Онбординг и первый запуск (выбор группы) — вне скоупа.
- profile- и settings-провайдеры — вне скоупа (только schedule).

## Key Decisions

- **GoRouter + ShellRoute**: Декларативная навигация с поддержкой deep links и PWA, официальный пакет от Flutter/Google.
- **BottomNavigationBar (не NavigationBar)**: Выбрано пользователем.
- **Placeholder-экраны**: Только структура и навигация, без реального контента.
- **Drift с `drift_flutter`**: Использовать `driftDatabase()` — официальный способ инициализации для мобильных и Web.
- **schemaVersion = 1**: Первая версия, миграции не требуются на этом этапе.

## Dependencies / Assumptions

- Проект уже содержит корректную структуру папок и domain-сущности (`Lesson`, `ScheduleDay`, `Profile`, `AppSettings`).
- Поддержка Web-платформы включена в проекте (директория `web/` существует).
- Dart SDK `^3.11.3`, Flutter — последняя стабильная версия.

## Outstanding Questions

### Resolve Before Planning
_Нет блокирующих вопросов._

### Deferred to Planning
- [Affects R2][Needs research] Какие именно поля нужны в `LessonsTable`: совпадают ли они 1:1 с `Lesson` или нужны дополнительные поля (group_id, week_number, is_odd_week)?
- [Affects R9][Needs research] Базовый URL YSTU API и формат параметров запроса.

## Next Steps

→ `/ce:plan` для структурированного планирования реализации
