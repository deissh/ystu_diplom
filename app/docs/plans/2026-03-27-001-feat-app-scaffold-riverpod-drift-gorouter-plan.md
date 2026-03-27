---
title: "feat: App Scaffold — Riverpod, Drift, GoRouter, Placeholder UI"
type: feat
status: active
date: 2026-03-27
origin: docs/brainstorms/2026-03-27-app-scaffold-requirements.md
---

# feat: App Scaffold — Riverpod, Drift, GoRouter, Placeholder UI

---

## Enhancement Summary

**Углублён:** 2026-03-27
**Агенты:** architecture-strategist, data-integrity-guardian, julik-frontend-races, performance-oracle, code-simplicity, best-practices-researcher, framework-docs-researcher

### Ключевые улучшения

1. **`groupId` обязателен в `LessonsTable`** — без него все запросы смешивают данные всех групп; это блокирует upsert и фильтрацию.
2. **`Lesson.id` убран из domain entity** — auto-increment id является деталью персистентности и не должен существовать в доменном слое. Composite unique constraint `(groupId, startTime, subject)` — правильный подход.
3. **`insertOrReplace` заменён на `insertOnConflictUpdate`** — `insertOrReplace` удаляет и переставляет строку, обнуляя rowid и нарушая FK. `insertOnConflictUpdate` обновляет на месте.
4. **`scheduleProvider` должен проходить через `ScheduleRepository`** — прямая зависимость presentation → data/datasources нарушает Clean Architecture. Добавить `watchSchedule()` в интерфейс репозитория.
5. **GoRouter v14 breaking changes** — `StatefulShellBranch` требует явного `navigatorKey`; `GoRouterState.location` удалён — использовать `.uri`.
6. **`ref.onDispose(db.close)`** — обязательно для корректного закрытия SQLite при диспозе контейнера.
7. **`ProviderScope` строго в `main.dart`** — размещение внутри `App.build()` пересоздаёт весь контейнер провайдеров при ребилде `App`.

### Новые соображения

- `riverpod_annotation`/`riverpod_generator` — избыточны для 2 провайдеров на scaffold-этапе; использовать manual providers
- `DioClient` класс — YAGNI для заглушки; inline `Dio` в `ApiClient`
- `Parser` класс — YAGNI пока нет реального HTML; заглушка возвращает `[]` прямо из `ApiClient`
- Composite index на `(groupId, startTime)` нужен с самой первой схемы
- `ref.keepAlive()` в `scheduleProvider` — не допускает сброса стрима при навигации

---

## Overview

Подключить фундаментальную инфраструктуру приложения YSTU Schedule: добавить плановые зависимости в `pubspec.yaml`, реализовать Drift-базу данных с `LessonsTable` и `ScheduleDao`, настроить Riverpod с `ProviderScope` и ключевыми провайдерами, сконфигурировать GoRouter с `StatefulShellRoute` и `BottomNavigationBar`, конвертировать placeholder-экраны в `ConsumerWidget`, заглушить `ApiClient`.

После этой работы приложение компилируется, запускается, навигирует между тремя вкладками и читает из живой SQLite-базы — без реальных API-запросов.

## Problem Statement / Motivation

Flutter-проект имеет полную структуру папок Clean Architecture и domain-слой, но нулевую работающую инфраструктуру. Каждый файл data- и presentation-слоя — однострочная заглушка. `pubspec.yaml` содержит только `flutter` и `cupertino_icons`. Без каркаса никакая функциональная работа невозможна.

## Proposed Solution

Шесть последовательных фаз — зависимости → фикс домена → БД → Riverpod → навигация → экраны/стабы — так что каждая фаза даёт компилируемое промежуточное состояние.

---

## Technical Considerations

### Окончательные решения (после углублённого ревью)

- **`Lesson.id` НЕ добавляется в domain entity** — auto-increment id является деталью персистентности. Дать Drift сгенерировать rowid самостоятельно. Для уникальности использовать composite unique constraint `{groupId, startTime, subject}` прямо в таблице. `LessonModel` не требует поля `id`.

- **`groupId` добавляется в `LessonsTable`** — обязательно как `TextColumn groupId`. Без него невозможно фильтровать по группе и корректно работает `insertOnConflictUpdate`.

- **`WidgetsFlutterBinding.ensureInitialized()`** — первая строка `main()`, до `runApp`. `path_provider` требует инициализированного binding на мобильных платформах.

- **`ProviderScope` только в `main.dart`** — `runApp(const ProviderScope(child: App()))`. Никогда не размещать внутри `App.build()` — при ребилде `App` весь контейнер провайдеров пересоздаётся.

- **`StatefulShellRoute.indexedStack`** — сохраняет стек навигации и scroll-позицию каждой вкладки. GoRouter v14: каждый `StatefulShellBranch` требует явного `navigatorKey`. `goBranch(index, initialLocation: index == shell.currentIndex)` — канонический паттерн.

- **`scheduleProvider` через `ScheduleRepository`** — добавить `Stream<List<ScheduleDay>> watchSchedule()` в `ScheduleRepository` interface. `ScheduleRepositoryImpl` делегирует в DAO. Это сохраняет dependency rule (presentation → domain ← data) и не даёт precedent прямого bypassa.

- **`databaseProvider`**: `Provider<AppDatabase>` без `autoDispose` + `ref.onDispose(db.close)` — БД живёт весь lifecycle, корректно закрывается при диспозе контейнера.

- **`insertOnConflictUpdate`** вместо `insertOrReplace` — не удаляет строку (сохраняет rowid и FK), только обновляет изменившиеся поля.

- **`ref.keepAlive()`** в `scheduleProvider` — предотвращает сброс стрима при уходе с экрана расписания.

- **Drift на Web**: `driftDatabase()` из `drift_flutter` автоматически выбирает WASM/OPFS на web и file-based на мобильных — никаких пользовательских веток.

- **Manual Riverpod providers** (без codegen) — для 2 провайдеров scaffold-этапа `build_runner` и `riverpod_generator` излишни. Codegen добавить когда будет ≥5 провайдеров.

- **`DioClient` и `Parser`** — не создавать отдельные классы на scaffold-этапе. Inline `Dio()` прямо в `ApiClient`; заглушка возвращает `[]` без `Parser`.

---

## System-Wide Impact

- **`app.dart`** → `MaterialApp.router(routerConfig: appRouter)`. `App` становится `ConsumerWidget` для чтения `appRouter` из Riverpod (опционально — роутер можно сделать константой).
- **`main.dart`** → `WidgetsFlutterBinding.ensureInitialized()` + `ProviderScope`.
- **`ScheduleRepository` interface** → добавляется метод `watchSchedule()`.
- **`ScheduleRepositoryImpl`** → реализация `watchSchedule()` делегирует в DAO.
- **`LessonModel`** → добавляется `fromEntity()` (для write-path entity→companion).
- **`ScheduleRepositoryImpl`** остаётся нетронутым в остальном (вне скоупа).

---

## Acceptance Criteria

- [ ] `flutter pub get` завершается без ошибок
- [ ] `flutter analyze` возвращает ноль ошибок (no codegen needed)
- [ ] Приложение стартует на Android/iOS: `databaseProvider` создаёт SQLite-файл, `ref.onDispose` регистрирует `db.close`
- [ ] Приложение стартует в Chrome: `databaseProvider` инициализируется (WASM/OPFS через `drift_flutter`)
- [ ] Видна трёхтабовая `BottomNavigationBar`; нажатие на вкладку показывает нужный экран
- [ ] Возврат на вкладку сохраняет её состояние (`StatefulShellRoute.indexedStack`)
- [ ] Нажатие на активную вкладку возвращает к корню этой вкладки (через `initialLocation: index == shell.currentIndex`)
- [ ] `scheduleProvider` эмитирует пустой список на первом запуске без ошибок
- [ ] `scheduleProvider` использует `ScheduleRepository.watchSchedule()` (не прямой DAO)
- [ ] `fetchSchedule('test')` возвращает пустой список без ошибок
- [ ] `LessonsTable` имеет composite unique constraint на `(groupId, startTime, subject)`
- [ ] `LessonsTable` имеет composite index на `(groupId, startTime)`

---

## Implementation Phases

### Phase 1 — Dependencies (`pubspec.yaml`)

Добавить в `dependencies`:
```yaml
flutter_riverpod: ^2.6.1
drift: ^2.24.0
drift_flutter: ^0.2.0
path_provider: ^2.1.4   # используется drift_flutter внутри
dio: ^5.7.0
go_router: ^14.6.0
```

Добавить в `dev_dependencies`:
```yaml
build_runner: ^2.4.13   # нужен для Drift codegen
drift_dev: ^2.24.0
```

> `riverpod_annotation`, `riverpod_generator` **не добавлять** на данном этапе — для 2 провайдеров codegen избыточен (см. Enhancement Summary).

> ⚠️ Версии ориентировочные. Проверить актуальные на pub.dev: `drift` + `drift_dev` должны быть одной версии; `go_router` должен быть ≥14.0.0.

Запустить: `flutter pub get`

#### Research Insights: pubspec

**Важно для drift_flutter:**
- `drift_flutter` подтягивает `sqlite3_flutter_libs` транзитивно — явно добавлять не нужно.
- На web `drift_flutter` использует OPFS worker; убедиться, что `flutter build web` включает WASM asset. Команда `flutter run -d chrome` работает без дополнительных настроек.

**Совместимость пакетов:** drift + drift_dev должны быть строго одной версии. Если `flutter pub get` выдаёт конфликт `analyzer`, проверить на pub.dev страницу `drift_dev` → вкладку "Versions" → constraints на `analyzer`.

---

### Phase 2 — Domain Fix (`Lesson` + `ScheduleRepository` + `LessonModel`)

**`lib/features/schedule/domain/entities/lesson.dart`**

```dart
// НЕ добавлять поле id — это деталь персистентности, не домена.
// Текущая структура корректна:
class Lesson {
  final String subject;
  final String teacher;
  final String room;
  final String type;
  final DateTime startTime;  // всегда UTC
  final DateTime endTime;    // всегда UTC

  const Lesson({...});
}
```

**`lib/features/schedule/domain/repositories/schedule_repository.dart`**

Добавить метод стрима:
```dart
abstract interface class ScheduleRepository {
  Future<List<ScheduleDay>> getSchedule(String groupId, DateTime from, DateTime to);

  // Новый метод для реактивного UI (добавляется в Phase 2)
  Stream<List<ScheduleDay>> watchSchedule(String groupId, DateTime from, DateTime to);
}
```

**`lib/features/schedule/data/repositories/schedule_repository_impl.dart`**

Добавить заглушку для нового метода:
```dart
@override
Stream<List<ScheduleDay>> watchSchedule(String groupId, DateTime from, DateTime to) {
  // TODO: делегировать в scheduleDao.watchLessons(groupId, from, to)
  return const Stream.empty();
}
```

**`lib/features/schedule/data/models/lesson_model.dart`**

Добавить `fromEntity()`:
```dart
factory LessonModel.fromEntity(Lesson e) => LessonModel(
  subject: e.subject,
  teacher: e.teacher,
  room: e.room,
  type: e.type,
  startTime: e.startTime.toUtc(),  // нормализовать в UTC
  endTime: e.endTime.toUtc(),
);

// fromJson — добавить .toUtc() для надёжности:
factory LessonModel.fromJson(Map<String, dynamic> json) => LessonModel(
  subject: json['subject'] as String,
  teacher: json['teacher'] as String,
  room: json['room'] as String,
  type: json['type'] as String,
  startTime: DateTime.parse(json['start_time'] as String).toUtc(),
  endTime: DateTime.parse(json['end_time'] as String).toUtc(),
);
```

#### Research Insights: Domain Layer

**`Lesson.id` и Clean Architecture:**
- Auto-increment integer id — это суррогатный ключ базы данных, не атрибут бизнес-концепции «занятие».
- Идентичность занятия в предметной области определяется комбинацией `(groupId, startTime, subject)`. Это и есть natural key.
- Drift table хранит `rowid` автоматически; `LessonsTableCompanion` не требует явного поля `id`.

**UTC DateTime — правило:**
- Всегда нормализовывать в UTC при создании entity. `DateTime.parse('2025-09-01T08:00:00')` без суффикса `Z` → local time → может сдвинуться при смене timezone.
- В UI показывать `lesson.startTime.toLocal()`.

---

### Phase 3 — Drift Database

**`lib/features/schedule/data/datasources/local/drift_database.dart`**

```dart
// ВАЖНО: файл должен иметь директиву 'part':
// part 'drift_database.g.dart';

// @DriftDatabase(tables: [LessonsTable], daos: [ScheduleDao])
// class AppDatabase extends _$AppDatabase {
//   AppDatabase([QueryExecutor? executor])
//       : super(executor ?? driftDatabase(name: 'ystu_schedule'));
//
//   @override int get schemaVersion => 1;
//
//   @override MigrationStrategy get migration => MigrationStrategy(
//     onCreate: (m) => m.createAll(),  // создаёт все таблицы при первом открытии
//     beforeOpen: (_) async {
//       await customStatement('PRAGMA foreign_keys = ON');
//     },
//   );
//
//   late final scheduleDao = ScheduleDao(this);  // DAO-accessor
// }
//
// class LessonsTable extends Table {
//   @override String get tableName => 'lessons';
//
//   // НЕТ autoIncrement PK — используем composite unique constraint
//   TextColumn get groupId  => text()();           // ОБЯЗАТЕЛЬНО: группа для фильтрации
//   TextColumn get subject  => text()();
//   TextColumn get teacher  => text()();
//   TextColumn get room     => text()();
//   TextColumn get type     => text()();
//   DateTimeColumn get startTime => dateTime()();  // хранится как INTEGER (epoch ms)
//   DateTimeColumn get endTime   => dateTime()();
//
//   // Composite unique constraint — основа для insertOnConflictUpdate
//   @override
//   List<Set<Column>> get uniqueKeys => [
//     {groupId, startTime, subject},
//   ];
// }
```

> Drift хранит `DateTimeColumn` как `INTEGER` (milliseconds since epoch) по умолчанию — это корректно для сортировки и range-запросов в SQLite.

**`lib/features/schedule/data/datasources/local/schedule_dao.dart`**

```dart
// ВАЖНО: файл должен иметь директиву 'part':
// part 'schedule_dao.g.dart';

// @DriftAccessor(tables: [LessonsTable])
// class ScheduleDao extends DatabaseAccessor<AppDatabase> with _$ScheduleDaoMixin {
//   ScheduleDao(super.db);
//
//   // Реактивный стрим — пока без фильтров (scaffold).
//   // TODO (Phase profile): параметризовать по groupId + date range.
//   Stream<List<LessonsTableData>> watchAllLessons() =>
//       select(lessonsTable).watch();
//
//   // Upsert: insertOnConflictUpdate — НЕ insertOrReplace
//   // insertOrReplace удаляет строку и вставляет новую (теряет rowid, ломает FK)
//   // insertOnConflictUpdate обновляет только изменившиеся поля
//   Future<void> insertLessons(List<Lesson> lessons) =>
//       batch((b) => b.insertAllOnConflictUpdate(
//         lessonsTable,
//         lessons.map((l) => LessonModel.fromEntity(l).toCompanion()).toList(),
//       ));
// }
```

Запустить: `dart run build_runner build --delete-conflicting-outputs`

Это генерирует `drift_database.g.dart` и `schedule_dao.g.dart`.

#### Research Insights: Drift

**Правило `()()` в Drift:**
- Каждый геттер столбца заканчивается двумя парами скобок: `text()()`, `dateTime()()`.
- Первый вызов создаёт builder (`ColumnBuilder<T>`), второй финализирует (`Column<T>`). Пропуск второго `()` — compile-time ошибка.

**`part` directive:**
- Оба файла (`drift_database.dart` и `schedule_dao.dart`) должны иметь строку `part 'filename.g.dart';`.
- Без неё `build_runner` не генерирует код и появляется ошибка `_$AppDatabase class not found`.

**Composite unique constraint:**
- `uniqueKeys` — это гарантия на уровне SQLite, не только Dart.
- `insertOnConflictUpdate` работает через `INSERT OR REPLACE ... SET col=excluded.col` (SQLite UPSERT syntax). Конфликт определяется именно через `uniqueKeys`.

**Индексы:** Добавить в отдельной Dart-аннотации или через кастомный SQL. Простейший способ для scaffold — добавить через `beforeOpen`:

```dart
// В MigrationStrategy.beforeOpen (или отдельный onCreate шаг):
beforeOpen: (details) async {
  if (details.wasCreated) {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_lessons_group_start '
      'ON lessons(group_id, start_time)',
    );
  }
  await customStatement('PRAGMA foreign_keys = ON');
},
```

---

### Phase 4 — Riverpod Wiring

**`lib/main.dart`**

```dart
// WidgetsFlutterBinding.ensureInitialized() — ПЕРВАЯ строка, до runApp
// ProviderScope ОБЯЗАТЕЛЬНО в main.dart, НЕ внутри App.build()
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   runApp(const ProviderScope(child: App()));
// }
```

**`lib/features/schedule/presentation/providers/schedule_provider.dart`**

```dart
// Два manual-провайдера (без riverpod_annotation codegen на scaffold-этапе):

// 1. databaseProvider — singleton на весь lifecycle приложения
// final databaseProvider = Provider<AppDatabase>((ref) {
//   final db = AppDatabase();
//   ref.onDispose(db.close);  // ОБЯЗАТЕЛЬНО: закрыть DB при диспозе контейнера
//   return db;
// });

// 2. scheduleProvider — реактивный стрим через ScheduleRepository (не прямой DAO!)
// [Архитектурное требование: presentation читает domain, не data]
// ref.keepAlive() — не даёт Riverpod диспозить стрим при уходе с экрана
//
// final scheduleProvider = StreamProvider<List<ScheduleDay>>((ref) {
//   ref.keepAlive();  // стрим живёт всё время, пока жив ProviderScope
//   // TODO: параметризовать groupId через profileProvider
//   // Временная заглушка для scaffold (пустой стрим из impl):
//   return const Stream.empty();
// });
```

> На данном этапе `watchSchedule()` в `ScheduleRepositoryImpl` возвращает `Stream.empty()`, поэтому `scheduleProvider` будет в состоянии `AsyncValue.loading` постоянно — это корректно для placeholder-экранов.

#### Research Insights: Riverpod

**`ProviderScope` в `main.dart` — почему критично:**
- Если `ProviderScope` находится внутри `App.build()`, то при любом ребилде `App` (смена темы, localizations и т.д.) весь контейнер провайдеров уничтожается и пересоздаётся. База данных закрывается и открывается заново, все стримы сбрасываются, пользователь видит экран загрузки.
- Правило: один `ProviderScope` на верхнем уровне `runApp`, никогда nested за пределами feature-тестов.

**`ref.keepAlive()` для schedule stream:**
- По умолчанию `StreamProvider` — `autoDispose`: когда последний виджет отписывается (пользователь ушёл с экрана расписания), Riverpod диспозирует провайдер и Drift отписывается от стрима.
- При возврате пользователь видит `AsyncLoading` (мигание), хотя данные уже в БД.
- `ref.keepAlive()` внутри `build`-функции провайдера переводит его в never-dispose режим.

**`AsyncValue.when` для offline-first UX:**
```dart
// В ScheduleScreen:
asyncSchedule.when(
  skipLoadingOnReload: true,  // показывает старые данные во время фонового обновления
  data: (days) => ScheduleList(days: days),
  loading: () => const CircularProgressIndicator(),
  error: (e, _) => ErrorBanner(message: e.toString()),
);
```

---

### Phase 5 — Navigation (GoRouter)

**`lib/router/app_router.dart`**

```dart
// GoRouter v14 BREAKING CHANGES:
// 1. GoRouterState.location удалён → использовать .uri или .matchedLocation
// 2. StatefulShellBranch требует явного navigatorKey (обязательно!)

// Объявить ключи ВНЕ функций/классов (top-level):
// final _rootNavKey = GlobalKey<NavigatorState>();
// final _scheduleNavKey = GlobalKey<NavigatorState>(debugLabel: 'schedule');
// final _profileNavKey  = GlobalKey<NavigatorState>(debugLabel: 'profile');
// final _settingsNavKey = GlobalKey<NavigatorState>(debugLabel: 'settings');

// final appRouter = GoRouter(
//   navigatorKey: _rootNavKey,
//   initialLocation: '/schedule',  // должен совпадать с путём в первой ветке
//   routes: [
//     StatefulShellRoute.indexedStack(
//       builder: (ctx, state, shell) => _ScaffoldWithNavBar(shell: shell),
//       branches: [
//         StatefulShellBranch(
//           navigatorKey: _scheduleNavKey,  // ОБЯЗАТЕЛЬНО в v14
//           routes: [GoRoute(path: '/schedule', builder: (_, __) => const ScheduleScreen())],
//         ),
//         StatefulShellBranch(
//           navigatorKey: _profileNavKey,
//           routes: [GoRoute(path: '/profile',  builder: (_, __) => const ProfileScreen())],
//         ),
//         StatefulShellBranch(
//           navigatorKey: _settingsNavKey,
//           routes: [GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen())],
//         ),
//       ],
//     ),
//   ],
// );
```

**`_ScaffoldWithNavBar`** — приватный виджет в `app_router.dart` (не отдельный файл):

```dart
// class _ScaffoldWithNavBar extends StatelessWidget {
//   final StatefulNavigationShell shell;
//   const _ScaffoldWithNavBar({required this.shell});
//
//   @override
//   Widget build(BuildContext context) => Scaffold(
//     body: shell,
//     bottomNavigationBar: BottomNavigationBar(
//       currentIndex: shell.currentIndex,
//       onTap: (i) => shell.goBranch(
//         i,
//         // Нажатие на активную вкладку → возврат к корню ветки
//         initialLocation: i == shell.currentIndex,
//       ),
//       items: const [
//         BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Расписание'),
//         BottomNavigationBarItem(icon: Icon(Icons.person),          label: 'Профиль'),
//         BottomNavigationBarItem(icon: Icon(Icons.settings),        label: 'Настройки'),
//       ],
//     ),
//   );
// }
```

**`lib/app.dart`**

```dart
// App становится ConsumerWidget (для будущего чтения провайдеров: темы, лоkale)
// ProviderScope здесь НЕТ — он в main.dart
//
// class App extends ConsumerWidget {
//   const App({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return MaterialApp.router(
//       title: AppConstants.appName,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       routerConfig: appRouter,
//     );
//   }
// }
```

#### Research Insights: GoRouter v14

**StatefulShellRoute.indexedStack vs ShellRoute:**
- `indexedStack` — все ветки остаются смонтированными одновременно (Flutter `IndexedStack`). Мгновенное переключение вкладок, scroll-позиция сохраняется.
- `ShellRoute` — перемонтирует дочерний виджет при каждом переходе. Проще, но теряет состояние.
- Для university schedule app с 3 вкладками `indexedStack` — правильный выбор.

**`goBranch` canonical pattern:**
```dart
shell.goBranch(
  index,
  initialLocation: index == shell.currentIndex,
  // true → вернуться на корень ветки (если уже на этой вкладке)
  // false → восстановить предыдущий стек ветки
);
```

**Глубокие ссылки (deep links):**
- GoRouter автоматически обрабатывает `/schedule/detail/42`: активирует schedule-ветку, пушит детальный экран поверх `ScheduleScreen`.
- Для PWA deep links работают через URL. Дополнительной конфигурации GoRouter не требуется — маршруты определяют поведение.

---

### Phase 6 — Screens + API Stub

**`lib/features/schedule/presentation/screens/schedule_screen.dart`**
**`lib/features/profile/presentation/screens/profile_screen.dart`**
**`lib/features/settings/presentation/screens/settings_screen.dart`**

```dart
// class <Name>Screen extends ConsumerWidget {
//   const <Name>Screen({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('<Расписание | Профиль | Настройки>')),
//       body: const Center(child: Text('TODO')),
//     );
//   }
// }
```

**`lib/features/schedule/data/datasources/remote/api_client.dart`**

```dart
// Inline Dio прямо в ApiClient — DioClient класс не нужен на scaffold-этапе.
// class ApiClient {
//   final Dio _dio = Dio(BaseOptions(
//     connectTimeout: const Duration(seconds: 10),
//     receiveTimeout: const Duration(seconds: 10),
//   ));
//
//   Future<List<Lesson>> fetchSchedule(String groupId) async => []; // stub
// }
```

> `Parser` класс и `dio_client.dart` не создаются — YAGNI. Добавить когда появится реальный API.

**`lib/core/network/dio_client.dart`** — оставить как есть (placeholder), или удалить и создать заново в фазе реального API.

### CLAUDE.md Update

Добавить в раздел Commands:
```bash
dart run build_runner build --delete-conflicting-outputs  # регенерировать Drift код после изменений схемы
dart run build_runner watch --delete-conflicting-outputs  # watch-режим во время разработки
```

---

## Alternatives Considered

| Вариант | Почему отклонён |
|---|---|
| `ShellRoute` вместо `StatefulShellRoute` | Не сохраняет scroll/nav состояние вкладок — придётся заменять с ростом контента |
| `NavigationBar` (Material 3) | Пользователь явно выбрал `BottomNavigationBar` (см. origin) |
| `riverpod_annotation` для 2 провайдеров | YAGNI на scaffold-этапе: codegen добавляет build_runner overhead для 4 строк кода |
| `DioClient` wrapper class | YAGNI: нет реальных HTTP-вызовов, нет смысла в абстракции |
| `Parser` class | YAGNI: заглушка в `ApiClient` возвращает `[]` напрямую |
| `Lesson.id` в domain entity | Утечка persistence-детали в доменный слой; composite unique constraint на DAO-уровне чище |
| `insertOrReplace` | Удаляет строку (теряет rowid), ломает FK; `insertOnConflictUpdate` обновляет на месте |
| Global `StreamProvider<List<Lesson>>` без `keepAlive` | Стрим диспозится при уходе с экрана → мигание загрузки при возврате |
| `scheduleProvider` → прямой DAO | Нарушает Clean Architecture (presentation → data skip domain); добавление `watchSchedule()` в ScheduleRepository стоит 10 строк |

---

## Dependencies & Risks

- **Конфликты build_runner**: `drift` и `drift_dev` должны быть строго одной версии. Если возникнут конфликты — проверить совместимые версии на pub.dev.
- **drift_flutter web WASM**: `driftDatabase()` v0.2+ автоматически подключает WASM. При `flutter run -d chrome` убедиться, что OPFS доступен (современные Chrome/Edge). Если нет — Drift fallback в in-memory.
- **GoRouter v14 breaking changes**: `GoRouterState.location` удалён → `.uri.toString()` или `.matchedLocation`. Обязательно проверить при апгрейде с GoRouter 13.
- **`build_runner` после каждого изменения схемы Drift**: без регенерации код не компилируется. Включить `build_runner watch` во время разработки Drift-слоя.
- **UTC DateTime**: если API YSTU возвращает время без timezone-suffix, явно вызывать `.toUtc()` в `LessonModel.fromJson`.

---

## Outstanding Questions (Deferred to Planning/Implementation)

- **[Affects Phase 4]** `scheduleProvider` сейчас возвращает `Stream.empty()`. При реализации `ScheduleRepositoryImpl.watchSchedule()` нужно будет параметризовать по `groupId` (через `profileProvider`) и date range — это связано с фичей профиля.
- **[Affects R2][Needs research]** URL YSTU API и формат параметров запроса — нужен при реализации `ApiClient.fetchSchedule()`.
- **[Deferred]** Поля `isOddWeek`, `subgroup`, `lessonNumber` в `Lesson` — отложены до фичи отображения расписания; могут быть добавлены в `LessonsTable` через `schemaVersion = 2` migration.

---

## Sources & References

### Origin

- **Origin document:** [docs/brainstorms/2026-03-27-app-scaffold-requirements.md](docs/brainstorms/2026-03-27-app-scaffold-requirements.md)

  Ключевые решения из origin: GoRouter + StatefulShellRoute, BottomNavigationBar, placeholder-экраны, Drift с `drift_flutter`, `schemaVersion = 1`.

### Internal References

- `lib/features/schedule/domain/entities/lesson.dart` — остаётся без изменений (id НЕ добавляется)
- `lib/features/schedule/domain/repositories/schedule_repository.dart` — добавляется `watchSchedule()`
- `lib/features/schedule/data/models/lesson_model.dart` — добавляется `fromEntity()` + UTC normalization
- `lib/features/schedule/data/repositories/schedule_repository_impl.dart` — добавляется заглушка `watchSchedule()`
- `lib/main.dart` — `WidgetsFlutterBinding` + `ProviderScope`
- `lib/app.dart` — `ConsumerWidget` + `MaterialApp.router`
- `lib/features/schedule/data/datasources/local/` — Drift AppDatabase + ScheduleDao
- `lib/features/schedule/presentation/providers/schedule_provider.dart` — `databaseProvider` + `scheduleProvider`
