---
date: 2026-04-17
topic: cross-platform-db
---

# Cross-Platform Drift Database (Web + iOS/Android)

## Problem Frame
Приложение использует Drift (SQLite ORM). На iOS/Android база работает через нативный sqlite. На вебе `driftDatabase()` бросает исключение, потому что требует параметр `web`. Нужно настроить инициализацию базы под обе платформы без поломки существующей мобильной логики.

## Requirements
- R1. На iOS/Android база данных инициализируется через `driftDatabase(name: ...)` — поведение не меняется.
- R2. На вебе база работает через WASM sqlite3 (`WasmSqlite3.loadFromUrl` + `openInMemory()`). Данные существуют только в рамках сессии браузера.
- R3. В `web/` должен лежать файл `sqlite3.wasm` (копируется из pub-кеша).
- R4. Воркер `drift_worker.dart.js` не нужен — используется inline WASM без Worker API.
- R5. Всё остальное (провайдеры, репозитории, UI) продолжает работать без изменений.

## Success Criteria
- `flutter run -d chrome` запускается без исключений, экраны расписания и онбординга открываются.
- `flutter run -d ios` / `-d android` продолжает работать как раньше.

## Scope Boundaries
- Персистентность на вебе — вне скоупа (in-memory достаточно).
- `drift_worker.dart.js` и связанный с ним воркер — не нужны, удалить.

## Key Decisions
- **WASM inline вместо Worker**: не требует компиляции отдельного Dart-файла в JS и устраняет сложность с `driftWorkerMain`.
- **In-memory для веба**: явный выбор пользователя; упрощает setup до одного файла-ассета.

## Next Steps
→ `/ce:work` — реализация готова к выполнению
