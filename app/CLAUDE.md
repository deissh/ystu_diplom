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
dart run build_runner build --delete-conflicting-outputs  # regenerate Drift code after schema changes
dart run build_runner watch --delete-conflicting-outputs  # watch mode during Drift development
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
├── main.dart                         # ProviderScope + runApp
├── app.dart                          # ConsumerWidget MaterialApp.router root
├── core/
│   ├── constants/app_constants.dart
│   ├── errors/
│   │   ├── app_exception.dart        # sealed — thrown by datasources
│   │   └── failure.dart              # sealed — propagated through domain
│   ├── extensions/date_time_extensions.dart
│   ├── logger.dart                   # AppLogger (debug-only debugPrint wrapper)
│   ├── network/dio_client.dart       # Dio instance (stub)
│   └── theme/
│       ├── app_colors.dart           # iOS-style palette, light/dark + subject colors
│       ├── app_text_styles.dart
│       └── app_theme.dart            # AppThemeData.light() / .dark()
├── features/
│   ├── schedule/
│   │   ├── domain/
│   │   │   ├── entities/             # Lesson, ScheduleDay, LessonType
│   │   │   ├── repositories/schedule_repository.dart
│   │   │   └── use_cases/            # GetSchedule
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── local/            # drift_database.dart (+.g.dart), schedule_dao.dart (+.g.dart)
│   │   │   │   └── remote/           # api_client.dart, parser.dart (stubs)
│   │   │   ├── models/lesson_model.dart
│   │   │   └── repositories/schedule_repository_impl.dart
│   │   └── presentation/
│   │       ├── screens/schedule_screen.dart
│   │       ├── widgets/              # sync_status_bar, week_strip, timeline/*
│   │       └── providers/schedule_provider.dart
│   ├── profile/                      # storage not yet implemented
│   └── settings/                     # storage not yet implemented
├── router/app_router.dart            # GoRouter with StatefulShellRoute (3 tabs)
└── l10n/                             # stub
```

Each feature follows the same three-layer layout:

| Layer | What lives here |
|---|---|
| `domain/` | Entities, abstract repository interfaces (`abstract interface class`), use cases |
| `data/` | DTOs (`*Model`) with `fromJson/toJson/fromEntity/toEntity`, datasource stubs, repository implementations |
| `presentation/` | Screens, widgets, Riverpod providers |

### Key conventions

- Repository interfaces live in `domain/repositories/` and are `abstract interface class`.
- Implementations in `data/repositories/*_impl.dart` own the offline-first logic: serve cache, sync remote, write back.
- DTOs are named `*Model` and always expose `toEntity()` / `fromEntity()` — never pass models into the domain layer.
- Error types: `AppException` (thrown by datasources), `Failure` (returned up through domain) — both are sealed classes.
- `AppLogger` wraps `debugPrint` and is debug-only; use it instead of `print`.
- Theme colors: use `AppColors.resolve(context, light, dark)` for brightness-aware colors; subject-specific colors are in `app_colors.dart`.

### Dependencies

- **flutter_riverpod** — state management (`presentation/providers/`)
- **Drift + drift_flutter + drift_dev** — local SQLite ORM; `.g.dart` files are code-generated, run `build_runner` after schema changes
- **Dio** — HTTP client (configured in `core/network/dio_client.dart`)
- **GoRouter** — declarative navigation (`router/app_router.dart`)
- **path_provider** — resolves DB file path on device

### Known stubs / TODOs

- `schedule_repository_impl.dart` — `getSchedule()`/`watchSchedule()` return hardcoded mock data; real Drift + API integration is pending.
- `api_client.dart`, `parser.dart` — empty stubs; remote fetch not implemented.
- `dio_client.dart` — Dio instance not yet configured.
- `profile_provider.dart`, `settings_provider.dart` — empty files; persistence via SharedPreferences not yet wired.
- Settings tab in the bottom navigation bar is visually present but the GoRouter branch for `/settings` is not yet defined.
- `l10n/` — localisation stub only.
