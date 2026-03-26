# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

All commands run from `/Users/kirilkudryavtsev/pet_project/ystu-diplom/app/`.

```bash
flutter pub get          # install dependencies
flutter run              # run on connected device/emulator
flutter build apk        # build Android APK
flutter analyze          # static analysis (flutter_lints)
flutter test             # run all tests
flutter test test/widget_test.dart  # run a single test file
```

## Architecture

Clean Architecture with feature-based modules. The dependency rule flows inward: `data` → `domain` ← `presentation`.

### Offline-first

The app is **offline-first**: the schedule is always read from the local Drift database first and shown to the user immediately. A background sync with the remote API updates the cache; the UI then reflects the new data reactively via Riverpod. Network errors never block the UI — they surface as non-fatal banners while cached data remains visible.

Data flow for `schedule`:
1. `ScheduleRepositoryImpl` reads from `ScheduleDao` (Drift) and returns cached rows.
2. In parallel it calls `ApiClient` → `Parser` to fetch fresh data.
3. On success the new rows are written back to Drift; Riverpod stream rebuilds the screen.
4. On network failure `NetworkFailure` is emitted alongside the cached result.

`profile` and `settings` are local-only (SharedPreferences / Drift), so they are always available offline.

### Project structure

```
lib/
├── main.dart                         # runApp only
├── app.dart                          # MaterialApp root widget
├── core/
│   ├── constants/app_constants.dart
│   ├── errors/
│   │   ├── app_exception.dart        # sealed — thrown by datasources
│   │   └── failure.dart              # sealed — propagated through domain
│   ├── extensions/date_time_extensions.dart
│   ├── logger.dart                   # AppLogger (debug-only debugPrint wrapper)
│   └── network/dio_client.dart       # Dio instance (stub)
├── features/
│   ├── schedule/
│   │   ├── domain/
│   │   │   ├── entities/             # Lesson, ScheduleDay
│   │   │   ├── repositories/schedule_repository.dart
│   │   │   └── use_cases/            # GetSchedule
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── local/            # drift_database.dart, schedule_dao.dart, migrations/
│   │   │   │   └── remote/           # api_client.dart, parser.dart
│   │   │   ├── models/lesson_model.dart
│   │   │   └── repositories/schedule_repository_impl.dart
│   │   └── presentation/
│   │       ├── screens/schedule_screen.dart
│   │       ├── widgets/
│   │       └── providers/schedule_provider.dart
│   ├── profile/
│   │   ├── domain/
│   │   │   ├── entities/profile.dart
│   │   │   ├── repositories/profile_repository.dart
│   │   │   └── use_cases/            # GetProfile, SaveProfile
│   │   ├── data/
│   │   │   ├── datasources/local/profile_local_datasource.dart
│   │   │   ├── models/profile_model.dart
│   │   │   └── repositories/profile_repository_impl.dart
│   │   └── presentation/
│   │       ├── screens/profile_screen.dart
│   │       ├── widgets/
│   │       └── providers/profile_provider.dart
│   └── settings/
│       ├── domain/
│       │   ├── entities/app_settings.dart  # AppSettings + AppTheme enum + defaults
│       │   ├── repositories/settings_repository.dart
│       │   └── use_cases/            # GetSettings, SaveSettings
│       ├── data/
│       │   ├── datasources/local/settings_local_datasource.dart
│       │   ├── models/app_settings_model.dart
│       │   └── repositories/settings_repository_impl.dart
│       └── presentation/
│           ├── screens/settings_screen.dart
│           ├── widgets/
│           └── providers/settings_provider.dart
├── router/app_router.dart            # navigation (stub)
└── l10n/                             # localisation (stub)
```

Each feature follows the same three-layer layout:

| Layer | What lives here |
|---|---|
| `domain/` | Entities, abstract repository interfaces (`abstract interface class`), use cases |
| `data/` | DTOs (`*Model`) with `fromJson/toJson/fromEntity/toEntity`, datasource stubs, repository implementations |
| `presentation/` | Screens, widgets, Riverpod providers (not yet added as a dependency) |

### Key conventions

- Repository interfaces live in `domain/repositories/` and are `abstract interface class`.
- Implementations in `data/repositories/*_impl.dart` own the offline-first logic: serve cache, sync remote, write back.
- DTOs are named `*Model` and always expose `toEntity()` / `fromEntity()` — never pass models into the domain layer.
- Error types: `AppException` (thrown by datasources), `Failure` (returned up through the domain) — both are sealed classes.
- `AppLogger` wraps `debugPrint` and is debug-only; use it instead of `print`.

### Planned dependencies (not yet in pubspec.yaml)

- **Riverpod** — state management (`presentation/providers/`)
- **Drift** — local SQLite cache for schedule (`data/datasources/local/drift_database.dart`)
- **Dio** — HTTP client (`core/network/dio_client.dart`, `data/datasources/remote/api_client.dart`)
- **GoRouter or AutoRoute** — navigation (`router/app_router.dart`)
