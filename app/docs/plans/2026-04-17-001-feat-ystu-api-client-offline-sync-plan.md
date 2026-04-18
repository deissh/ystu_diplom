---
title: "feat: Implement YSTU API client and offline-first schedule sync"
type: feat
status: completed
date: 2026-04-17
origin: docs/brainstorms/2026-04-17-api-client-requirements.md
---

# feat: Implement YSTU API client and offline-first schedule sync

## Overview

Replace hardcoded mock data with real YSTU REST API integration. Implement a configured Dio client, remote datasource (`ApiClient` + `Parser`), new data models for groups/teachers/schedule, an extended Drift schema (v2 with `GroupsTable` + `TeachersTable`), and wire offline-first logic in `ScheduleRepositoryImpl`. After this work the app shows live schedule data; groups and teachers are cached in Drift for the future settings picker.

## Problem Statement / Motivation

`ScheduleRepositoryImpl` returns hardcoded mock data. `ApiClient` and `Parser` are empty stubs. Several existing files carry known bugs (`groupId: ''` hardcoded in `ScheduleDao._toCompanion`, `watchAllLessons()` is unparameterised, `LessonModel` has no `groupId`). Connecting to the real API requires fixing these gaps end-to-end across all four architecture layers and extending the Drift schema.

## Proposed Solution

Four sequential phases, each independently buildable:

1. **Network layer** — Configure `DioClient`; rewrite `ApiClient` with injected Dio returning models; implement `Parser` for all four response shapes.
2. **Data models** — New `GroupInstituteModel`, `TeacherModel`, `ScheduleWeekModel`/`ScheduleDayModel`; add `groupId` to `LessonModel` and `Lesson` entity.
3. **Local persistence** — Add `GroupsTable` + `TeachersTable` to Drift (schema v2 migration); new `GroupsDao`, `TeachersDao`; fix `ScheduleDao` bugs.
4. **Repository wiring** — Implement offline-first `ScheduleRepositoryImpl`; add `GroupsRepositoryImpl`, `TeachersRepositoryImpl`; update Riverpod providers.

## Technical Considerations

### API Endpoints and Response Shapes

Base URL: `https://gg-api.ystuty.ru`

| Endpoint | Root structure |
|---|---|
| `GET /s/schedule/v1/schedule/actual_groups` | `{ isCache, name, items: [{name: instituteName, groups: String[]}] }` |
| `GET /s/schedule/v1/schedule/actual_teachers` | `{ isCache, count, items: [{id: int, name: String}] }` |
| `GET /s/schedule/v1/schedule/group/{groupName}` | `{ isCache, items: Week[] }` |
| `GET /s/schedule/v1/schedule/teacher/{teacherId}` | `{ teacher: {id, name}, items: Week[] }` — no `isCache`; lessons add `groups: String[]` |

**Week structure**: `{ number: int, days: Day[] }`
**Day structure**: `{ info: { type: int, weekNumber: int, date: ISO8601 }, lessons: Lesson[] }`
**Lesson fields**: `lessonName`, `teacherName`, `teacherId`, `auditoryName`, `startAt` (ISO 8601 UTC), `endAt` (ISO 8601 UTC), `type` (bitmask int), `isLecture` (bool), `parity` (0/1/2), `number`, `timeRange`, `isDistant`, `isStream`, `isDivision`

### LessonType mapping (see origin: R6)

```
isLecture == true  →  LessonType.lecture
type == 4          →  LessonType.practice
type == 8          →  LessonType.lab
otherwise          →  LessonType.other
```

Note: `type` is a bitmask; real API data includes values 16, 64, 128, 256, 4096 for group schedules. All unknown values must map to `other` without throwing.

### Parity filtering (see origin: R5)

Filtering is done inside `Parser` during response parsing — each `Day` carries `day.info.weekNumber`. Filter each lesson:

```
include if parity == 0 (every week)
include if parity == 1 AND weekNumber is odd
include if parity == 2 AND weekNumber is even
```

`ScheduleDay` entity does **not** need a `weekNumber` field — filtering happens before assembling domain entities.

### Teacher schedule `groups` field

Teacher lesson objects carry `groups: String[]` (which groups attend). This field is **explicitly discarded** in this implementation. If it becomes needed later, a `LessonsTable` schema migration will be required. (see origin: Deferred to Planning — Q4)

### Drift schema changes (v1 → v2)

Current v1: `LessonsTable` only.
v2 adds: `GroupsTable` (instituteName + groupName composite PK), `TeachersTable` (id PK + name).
Migration: additive only — `CREATE TABLE IF NOT EXISTS` in `onUpgrade(1, 2)`. No data loss.
**Known v1 data issue**: existing cached lesson rows have `groupId = ''` due to the `_toCompanion` bug. A one-time clear of the `LessonsTable` in the v1→v2 migration handles this cleanly.

### groupId propagation

`LessonsTable` already has a `groupId` column, but `Lesson` entity and `LessonModel` are missing this field. Must be added end-to-end:
`Lesson entity` → `LessonModel` → `LessonsTableCompanion` → `ScheduleDao._toCompanion`

### DioClient design

```dart
class DioClient {
  static Dio create() => Dio(BaseOptions(
    baseUrl: 'https://gg-api.ystuty.ru',
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 30),
    headers: {'Accept': 'application/json'},
  ))
  ..interceptors.add(/* error → NetworkException mapping */);
}

// Riverpod
final dioProvider = Provider<Dio>((ref) => DioClient.create());
```

Error interceptor converts `DioException` (non-2xx, timeout, no connection) into `NetworkException` before it reaches `ApiClient`.

### No group selected (first-run state)

When `groupId` is empty (first launch, settings not yet configured), `ScheduleRepositoryImpl` must **not** call the API. It returns an empty result. The schedule screen already has a placeholder path — it should show "Выберите группу в Настройках" instead of loading or calling `fetchGroupSchedule('')`.

### SyncStatusBar / NetworkFailure surfacing (see origin: R8)

`ScheduleRepositoryImpl` emits errors via `AsyncValue.error` on the Riverpod stream. `SyncStatusBar` reads from `scheduleProvider` and displays a non-fatal banner when `scheduleProvider.hasError`. Cached data is shown simultaneously via `scheduleProvider.valueOrNull`.

## Acceptance Criteria

- [ ] **R1** `ApiClient.fetchGroups()`, `fetchTeachers()`, `fetchGroupSchedule(String)`, `fetchTeacherSchedule(int)` make real HTTP calls and return typed models
- [ ] **R2** `Parser` converts all four response shapes into typed data models without throwing on valid input
- [ ] **R3** `GroupsRepositoryImpl` fetches from API and persists to `GroupsTable`; groups available offline after first load
- [ ] **R4** `TeachersRepositoryImpl` fetches from API and persists to `TeachersTable`
- [ ] **R5** Parity filtering applied in `Parser`; schedule screen shows only lessons applicable to the current week
- [ ] **R6** `LessonType` mapped correctly; unknown `type` bitmask values produce `other` without exception
- [ ] **R7** `ScheduleRepositoryImpl` serves Drift cache immediately, background-syncs from API, Drift write triggers Riverpod stream rebuild
- [ ] **R8** On network failure: cached data shown, `NetworkFailure` surfaced via `AsyncValue.error`, `SyncStatusBar` displays banner
- [ ] Empty `groupId` shows "select group" placeholder — API is never called with an empty group name
- [ ] `flutter analyze` passes with no new warnings
- [ ] `dart run build_runner build --delete-conflicting-outputs` runs cleanly after all Drift changes

## Implementation Plan

### Phase 1: Network layer

**`lib/core/network/dio_client.dart`**
- Implement `DioClient.create()` static factory (or top-level function) returning configured `Dio`
- Add error interceptor: `DioException` → `throw NetworkException(message)`
- Add `dioProvider = Provider<Dio>((ref) => DioClient.create())`

**`lib/features/schedule/data/datasources/remote/api_client.dart`**
- Accept `Dio` via constructor: `ApiClient(this._dio)`
- Remove inline `Dio` construction
- Implement four methods (return raw response maps, not domain entities):
  - `Future<Map<String, dynamic>> fetchGroups()`
  - `Future<Map<String, dynamic>> fetchTeachers()`
  - `Future<Map<String, dynamic>> fetchGroupSchedule(String groupName)` — URL-encode groupName
  - `Future<Map<String, dynamic>> fetchTeacherSchedule(int teacherId)`
- Wrap each `_dio.get(...)` in try/catch; rethrow `DioException` as `NetworkException`

**`lib/features/schedule/data/datasources/remote/parser.dart`**
- Implement `ScheduleParser` class with four methods:
  - `List<GroupInstituteModel> parseGroups(Map<String, dynamic> json)`
  - `List<TeacherModel> parseTeachers(Map<String, dynamic> json)`
  - `List<ScheduleDayModel> parseGroupSchedule(Map<String, dynamic> json, String groupId)`
    - Iterates `items` (weeks) → `days` → `lessons`
    - Applies parity filter per lesson using `day.info.weekNumber`
    - Maps `startAt`/`endAt` ISO strings via `DateTime.parse(...).toLocal()`
    - Maps `isLecture`/`type` → `LessonType`
  - `List<ScheduleDayModel> parseTeacherSchedule(Map<String, dynamic> json)`
    - Same as above but `groupId` taken from `json['teacher']['id'].toString()`
    - Discards `lesson['groups']` field
- All methods wrap body in try/catch; throw `ParseException` on malformed data

### Phase 2: Data models

**`lib/features/schedule/domain/entities/lesson.dart`**
- Add `final String groupId` field (required, positional or named)
- Update `const` constructor

**`lib/features/schedule/data/models/lesson_model.dart`**
- Add `final String groupId` field
- Update `fromJson`: `groupId` is passed as a parameter (not in lesson JSON), e.g. `LessonModel.fromJson(json, {required String groupId})`
- Update `fromEntity`: `groupId: lesson.groupId`
- Update `toEntity()`: passes `groupId` to `Lesson`

**NEW `lib/features/schedule/data/models/group_institute_model.dart`**
```dart
class GroupInstituteModel {
  final String instituteName;
  final List<String> groups;
  factory GroupInstituteModel.fromJson(Map<String, dynamic> json) =>
    GroupInstituteModel(
      instituteName: json['name'] as String,
      groups: List<String>.from(json['groups'] as List),
    );
}
```

**NEW `lib/features/schedule/data/models/teacher_model.dart`**
```dart
class TeacherModel {
  final int id;
  final String name;
  factory TeacherModel.fromJson(Map<String, dynamic> json) =>
    TeacherModel(id: json['id'] as int, name: json['name'] as String);
}
```

**NEW `lib/features/schedule/data/models/schedule_week_model.dart`**
```dart
class ScheduleWeekModel {
  final int number;
  final List<ScheduleDayModel> days;
}

class ScheduleDayModel {
  final DateTime date;
  final List<LessonModel> lessons; // already parity-filtered
}
```
These are internal Parser models, not exposed beyond the data layer.

### Phase 3: Local persistence

**`lib/features/schedule/data/datasources/local/drift_database.dart`**
- Add `GroupsTable`:
  ```dart
  class Groups extends Table {
    TextColumn get instituteName => text()();
    TextColumn get groupName => text()();
    @override
    Set<Column> get primaryKey => {instituteName, groupName};
  }
  ```
- Add `TeachersTable`:
  ```dart
  class Teachers extends Table {
    IntColumn get id => integer()();
    TextColumn get name => text()();
    @override
    Set<Column> get primaryKey => {id};
  }
  ```
- Add both tables to `@DriftDatabase(tables: [Lessons, Groups, Teachers])`
- Add `GroupsDao` and `TeachersDao` to `@DriftDatabase(daos: [...])`
- Increment `schemaVersion` to `2`
- Add migration:
  ```dart
  MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(groups);
        await m.createTable(teachers);
        await customStatement('DELETE FROM lessons'); // clear corrupt groupId='' rows
      }
    },
  )
  ```
- **After changes**: `dart run build_runner build --delete-conflicting-outputs`

**`lib/features/schedule/data/datasources/local/schedule_dao.dart`**
- Fix `_toCompanion`: `groupId: Value(lesson.groupId)` (was `Value('')`)
- Replace `watchAllLessons()` with:
  ```dart
  Stream<List<Lesson>> watchLessons({
    required String groupId,
    required DateTime from,
    required DateTime to,
  })
  ```
- Add `Future<List<Lesson>> getLessons({required String groupId, required DateTime from, required DateTime to})`
- Update `insertLessons` to accept `List<LessonModel>` (not `List<Lesson>`) and call `_toCompanionFromModel`

**NEW `lib/features/schedule/data/datasources/local/groups_dao.dart`**
```dart
@DriftAccessor(tables: [Groups])
class GroupsDao extends DatabaseAccessor<AppDatabase> with _$GroupsDaoMixin {
  Future<List<GroupData>> getAllGroups();
  Future<void> upsertGroups(List<GroupInstituteModel> institutes);
  Stream<List<GroupData>> watchAllGroups();
}
```

**NEW `lib/features/schedule/data/datasources/local/teachers_dao.dart`**
```dart
@DriftAccessor(tables: [Teachers])
class TeachersDao extends DatabaseAccessor<AppDatabase> with _$TeachersDaoMixin {
  Future<List<TeacherData>> getAllTeachers();
  Future<void> upsertTeachers(List<TeacherModel> teachers);
}
```

### Phase 4: Repository wiring

**`lib/features/schedule/data/repositories/schedule_repository_impl.dart`**
- Constructor: `ScheduleRepositoryImpl(this._dao, this._apiClient, this._parser)`
- Remove mock data entirely
- `watchSchedule({groupId, from, to})`:
  1. If `groupId.isEmpty` → return `Stream.value([])` immediately
  2. Yield `_dao.watchLessons(groupId, from, to)` immediately
  3. Trigger background fetch: `_sync(groupId)` (unawaited)
  4. `_sync`: calls `_apiClient.fetchGroupSchedule(groupId)` → `_parser.parseGroupSchedule(...)` → `_dao.insertLessons(...)`; on `NetworkException` → log via `AppLogger`
- `getSchedule({groupId, from, to})`: same logic but `Future` (one-shot)

**NEW `lib/features/schedule/domain/repositories/groups_repository.dart`**
```dart
abstract interface class GroupsRepository {
  Future<List<GroupInstituteModel>> getGroups();
  Stream<List<GroupInstituteModel>> watchGroups();
}
```

**NEW `lib/features/schedule/data/repositories/groups_repository_impl.dart`**
```dart
class GroupsRepositoryImpl implements GroupsRepository {
  GroupsRepositoryImpl(this._dao, this._apiClient, this._parser);
  // getGroups: read Drift → launch background API sync → return cached
  // watchGroups: stream from Drift, fire-and-forget API refresh
}
```

**NEW `lib/features/schedule/domain/repositories/teachers_repository.dart`** + **`data/repositories/teachers_repository_impl.dart`** — same pattern.

**`lib/features/schedule/presentation/providers/schedule_provider.dart`**
- Add `dioProvider` (from core/network)
- Add `apiClientProvider = Provider((ref) => ApiClient(ref.watch(dioProvider)))`
- Add `parserProvider = Provider((_) => ScheduleParser())`
- Update `scheduleRepositoryProvider` to inject all three:
  ```dart
  final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) =>
    ScheduleRepositoryImpl(
      ref.watch(scheduleDaoProvider),
      ref.watch(apiClientProvider),
      ref.watch(parserProvider),
    ));
  ```
- Add `groupsRepositoryProvider`, `teachersRepositoryProvider`
- Add `scheduleDaoProvider` if not already extracted

## System-Wide Impact

### Interaction Graph
`scheduleProvider` → `ScheduleRepositoryImpl` → `ScheduleDao.watchLessons` (Drift stream emits cached rows immediately) + async `_sync` → `ApiClient.fetchGroupSchedule` → HTTP response → `Parser.parseGroupSchedule` (parity filtered) → `ScheduleDao.insertLessons` → Drift stream emits updated rows → Riverpod rebuilds `scheduleProvider` → schedule screen redraws.

### Error Propagation
`Dio` throws `DioException` → `DioClient` interceptor catches → `throw NetworkException` → `ApiClient` rethrows → `ScheduleRepositoryImpl._sync` catches → `AppLogger.w(...)` + stream exposes `AsyncValue.error(NetworkFailure(...))` alongside last data → `scheduleProvider.hasError` is true → `SyncStatusBar` shows banner.

### State Lifecycle Risks
- `insertLessons` uses `insertAllOnConflictUpdate` — atomic per call, no partial corruption.
- v1→v2 Drift migration clears `lessons` table to remove corrupt `groupId=''` rows. Users lose their v1 cache on upgrade (one-time, acceptable — data will re-sync on next launch).
- If `_sync` is called while another `_sync` is in progress (e.g., pull-to-refresh while background sync running), concurrent `insertLessons` calls are safe due to `onConflictUpdate`.

### API Surface Parity
- `ScheduleRepository.watchSchedule` signature unchanged — no callers break.
- `GroupsRepository`, `TeachersRepository` are new, no existing callers.
- `ScheduleDao.watchAllLessons()` renamed to `watchLessons(...)` — only caller is `ScheduleRepositoryImpl` (currently mock, being replaced).

### Integration Test Scenarios
1. Empty cache + API returns 200 → schedule screen shows lessons after async delay
2. Non-empty cache + API returns network error → schedule shows cached data + SyncStatusBar banner
3. `groupId = ''` → no API call, schedule shows "select group" placeholder
4. API returns lesson with `type = 256` (unknown bitmask) → `LessonType.other`, no exception
5. `_sync` called twice concurrently (rapid screen re-enter) → no duplicate lessons in Drift

## Dependencies & Risks

| Risk | Mitigation |
|---|---|
| Drift code-gen not run after schema change | Phase 3 ends with explicit `build_runner` step in acceptance criteria |
| v1 cached rows have `groupId=''` | One-time table clear in `onUpgrade(1, 2)` |
| Teacher endpoint not confirmed in brainstorm | Verified during planning research: `GET /schedule/teacher/{id}` confirmed working |
| Unknown `type` bitmask values crash Parser | `else → LessonType.other` default catches all unknown values |
| `groupId` propagation touches many files | Phase 2 is self-contained; compile errors catch any missed site |
| `dio_client.dart` is currently a one-line comment | Phase 1 starts here — no dependencies on other phases |

## Sources & References

### Origin
- **Origin document:** [docs/brainstorms/2026-04-17-api-client-requirements.md](docs/brainstorms/2026-04-17-api-client-requirements.md)
  Key decisions carried forward: (1) cache groups + teachers in Drift, (2) parity filtering client-side in Parser, (3) teacher mode in scope, (4) pull-to-refresh cache invalidation strategy

### Internal References
- Drift database: `lib/features/schedule/data/datasources/local/drift_database.dart`
- Schedule DAO: `lib/features/schedule/data/datasources/local/schedule_dao.dart`
- ApiClient stub: `lib/features/schedule/data/datasources/remote/api_client.dart`
- Error types: `lib/core/errors/app_exception.dart`, `lib/core/errors/failure.dart`
- Riverpod providers: `lib/features/schedule/presentation/providers/schedule_provider.dart`
- AppLogger: `lib/core/logger.dart`

### External References
- Dio v5.7.0 interceptors: https://pub.dev/packages/dio
- Drift v2.24.0 migrations: https://drift.simonbinder.eu/docs/advanced-features/migrations/
- Drift DAOs: https://drift.simonbinder.eu/docs/getting-started/advanced_dart_tables/
