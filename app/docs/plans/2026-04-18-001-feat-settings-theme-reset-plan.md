---
title: "feat: Settings screen — theme switching and data reset"
type: feat
status: active
date: 2026-04-18
origin: docs/brainstorms/2026-04-18-settings-theme-reset-requirements.md
---

# feat: Settings screen — theme switching and data reset

## Overview

Реализовать экран настроек с двумя функциями: (1) переключение темы оформления (Системная / Светлая / Тёмная) с немедленным применением и сохранением между запусками; (2) кнопка «Сбросить данные», которая очищает все данные и возвращает пользователя на онбординг.

## Problem Statement / Motivation

- `SettingsScreen` — заглушка (`Center(child: Text('Settings'))`).
- `themeMode: ThemeMode.dark` в `app.dart:37` захардкожен — пользователь не может выбрать тему.
- Маршрут `/settings` отсутствует в GoRouter; вкладка настроек существует визуально, но недоступна.
- `AppSettings` entity и `AppSettingsModel` уже определены, но `SettingsLocalDatasource`, `SettingsRepositoryImpl` и `SettingsNotifier` — пустые заглушки.

(see origin: docs/brainstorms/2026-04-18-settings-theme-reset-requirements.md)

## Proposed Solution

Дорастить слой `settings` снизу вверх: datasource → repository → provider → UI. Параллельно добавить `/settings` маршрут и вкладку в `_IosTabBar`. Сброс реализовать как метод `SettingsNotifier.resetAllData()`, который атомарно очищает SharedPreferences, Drift и инвалидирует провайдеры.

## Technical Considerations

### Архитектурные решения

- **`SettingsNotifier`** — `AsyncNotifier<AppSettings>` (соответствует паттерну `ProfileNotifier` в `profile_provider.dart:38`).
- **ThemeMode в `app.dart`** — `App` уже `ConsumerWidget`; заменить хардкод на `ref.watch(settingsNotifierProvider).valueOrNull?.theme.toThemeMode() ?? ThemeMode.system`.
- **SharedPreferences ключ** — `const _kAppSettings = 'app_settings'` объявить в `settings_local_datasource.dart`; сброс читает этот ключ оттуда (не дублировать строку).
- **`AppSettingsModel.toEntity()` баг** — `AppTheme.values.byName(theme)` бросает `ArgumentError` при повреждённых данных. Добавить `try/catch` с возвратом `AppSettings.defaults`, как сделано для профиля в `app_startup_notifier.dart:37`.
- **`notificationsEnabled`** — поле остаётся в модели, но UI переключатель не рендерится в этом скоупе (деферред).

### Порядок сброса (атомарность)

Шаги выполняются в фиксированном порядке. Если любой шаг падает — показывается `SnackBar` с ошибкой, редиректа не происходит, частично удалённые данные не опасны (следующий сброс дочистит).

1. `prefs.remove('profile')`
2. `prefs.remove('onboarding_complete')`
3. `prefs.remove('app_settings')`
4. `ref.read(databaseProvider).clearAllData()` — `DELETE` по всем трём таблицам (`lessons`, `groups`, `teachers`) в одной транзакции
5. `ref.read(selectedSubjectProvider.notifier).state = null`
6. `ref.invalidate(profileNotifierProvider)`
7. `ref.invalidate(settingsNotifierProvider)` _(опционально, провайдер пересоздастся сам через GoRouter)_
8. `ref.invalidate(appStartupProvider)` — последним; тригерит `RouterNotifier.notifyListeners()` → GoRouter → `/onboarding`

### Добавление маршрута `/settings`

- Новый `StatefulShellBranch` с `GoRoute(path: '/settings', builder: SettingsScreen)` — четвёртым после `/profile`.
- Добавить иконку `Icons.settings_outlined` / `Icons.settings` в `_IosTabBar`.
- Redirect guard не требует изменений: он уже блокирует все маршруты кроме `/onboarding` когда `!done`.

## System-Wide Impact

- **`app.dart`** — смена `themeMode` с константы на `ref.watch(...)`. `App` уже `ConsumerWidget`, rebuild безопасен.
- **`AppDatabase`** — новый метод `clearAllData()`; ломает только `ScheduleDao` / `GroupsDao` если их кэш не инвалидируется (покрывается шагом 6 выше через `appStartupProvider`).
- **`appStartupProvider`** — не трогается; он сам читает только `onboarding_complete` и `profile`, не настройки.
- **GoRouter redirect** — после инвалидации `appStartupProvider` редирект сработает без изменений в `app_router.dart` (guard уже проверяет флаг).
- **Stale providers** — `scheduleProvider` использует `ref.keepAlive()` (schedule_provider.dart:91); после сброса Drift таблиц stream пересоздаётся автоматически при следующем запросе, дополнительная инвалидация не нужна.

## Acceptance Criteria

- [ ] R1: Экран настроек содержит сегментированный переключатель с тремя вариантами: Системная / Светлая / Тёмная.
- [ ] R2: Смена темы применяется немедленно (без перезапуска), `themeMode` в `MaterialApp` обновляется реактивно.
- [ ] R3: После перезапуска приложения тема восстанавливается из SharedPreferences.
- [ ] R4: Кнопка «Сбросить данные и настройки» показывает диалог подтверждения перед действием.
- [ ] R5: После подтверждения очищаются: `profile`, `onboarding_complete`, `app_settings` в SharedPreferences; таблицы `lessons`, `groups`, `teachers` в Drift.
- [ ] R6: После сброса GoRouter перенаправляет на `/onboarding`.
- [ ] `/settings` доступен через навигационную вкладку.
- [ ] `AppSettingsModel.toEntity()` не крашит при повреждённом значении темы (возвращает `AppSettings.defaults`).
- [ ] Кнопка сброса заблокирована (`isLoading` state) во время выполнения операции.

## Success Metrics

- Тема сохраняется между сессиями (ручная проверка: выбрать «Светлая» → перезапустить → тема светлая).
- После сброса онбординг показывается заново (ручная проверка).
- Приложение не крашит при повреждённом `app_settings` ключе (можно сэмулировать через `flutter run` + `prefs.setString('app_settings', 'INVALID')`).

## Dependencies & Risks

- **Зависимостей нет** — `shared_preferences`, `drift`, `flutter_riverpod`, `go_router` уже в `pubspec.yaml`.
- **Риск**: Если `scheduleProvider` (`keepAlive`) держит stream на старой группе после сброса — пользователь увидит чужие данные до перехода на онбординг. Митигация: шаг 5 сброса (`selectedSubjectProvider = null`) гарантирует, что stream вернёт пустой результат для `null` subject.
- **Риск**: Четвёртая вкладка изменяет layout `_IosTabBar` — проверить визуал на разных размерах экрана.

## Implementation Checklist

### 1. Fix `AppSettingsModel.toEntity()` (defensive)
- [ ] `lib/features/settings/data/models/app_settings_model.dart` — обернуть `byName` в `try/catch ArgumentError`

### 2. Settings datasource
- [ ] `lib/features/settings/data/datasources/local/settings_local_datasource.dart`
  - `const _kAppSettings = 'app_settings'`
  - `Future<AppSettings> getSettings()` — читает JSON из prefs, десериализует через `AppSettingsModel.fromJson`, fallback `AppSettings.defaults`
  - `Future<void> saveSettings(AppSettings settings)` — сериализует через `AppSettingsModel.fromEntity`, пишет JSON в prefs
  - `Future<void> clearSettings()` — `prefs.remove(_kAppSettings)`

### 3. Settings repository
- [ ] `lib/features/settings/data/repositories/settings_repository_impl.dart` — прокинуть вызовы к datasource

### 4. Drift: clearAllData
- [ ] `lib/features/schedule/data/datasources/local/drift_database.dart`
  - Метод `Future<void> clearAllData()` — удаляет строки из `lessonsTable`, `groups`, `teachers` в транзакции

### 5. SettingsNotifier (Riverpod)
- [ ] `lib/features/settings/presentation/providers/settings_provider.dart`
  - `SettingsNotifier extends AsyncNotifier<AppSettings>` — `build()` загружает из репозитория
  - `Future<void> setTheme(AppTheme theme)` — сохраняет и обновляет state
  - `Future<void> resetAllData(WidgetRef ref)` — атомарный сброс (8 шагов из раздела Technical Considerations)
    - Принимает `Ref` или читает зависимости через поле; держит `_isResetting` guard против двойного тапа

### 6. GoRouter: добавить /settings
- [ ] `lib/router/app_router.dart`
  - Новый `StatefulShellBranch` для `/settings`
  - Четвёртый элемент `BottomNavigationBarItem` в `_IosTabBar` (`Icons.settings_outlined` / `Icons.settings`)

### 7. app.dart: wiring ThemeMode
- [ ] `lib/app.dart:37` — заменить `themeMode: ThemeMode.dark` на `themeMode: ref.watch(settingsNotifierProvider).valueOrNull?.theme.toThemeMode() ?? ThemeMode.system`
- [ ] Добавить extension или helper `AppTheme.toThemeMode()`:
  ```dart
  // В app_settings.dart или отдельном extension file
  extension AppThemeX on AppTheme {
    ThemeMode toThemeMode() => switch (this) {
      AppTheme.system => ThemeMode.system,
      AppTheme.light  => ThemeMode.light,
      AppTheme.dark   => ThemeMode.dark,
    };
  }
  ```

### 8. SettingsScreen UI
- [ ] `lib/features/settings/presentation/screens/settings_screen.dart`
  - `ConsumerWidget` читает `settingsNotifierProvider`
  - `SegmentedButton<AppTheme>` с тремя вариантами (Material 3) — при выборе вызывает `setTheme`
  - Кнопка «Сбросить данные и настройки» (стиль `TextButton` с красным цветом)
  - `showDialog` с подтверждением перед сбросом:
    - Заголовок: «Сбросить данные?»
    - Тело: «Все данные профиля и кэш расписания будут удалены. Отменить действие невозможно.»
    - Кнопка подтверждения: «Сбросить» (красный), `barrierDismissible: true`
    - Кнопка отмены: «Отмена»
  - Disable кнопки сброса во время `isLoading` state

## Sources & References

- **Origin document:** [docs/brainstorms/2026-04-18-settings-theme-reset-requirements.md](../brainstorms/2026-04-18-settings-theme-reset-requirements.md) — ключевые решения: тема в SharedPreferences, после сброса → онбординг, диалог подтверждения
- Паттерн `AsyncNotifier`: `lib/features/profile/presentation/providers/profile_provider.dart:38`
- Паттерн инвалидации `appStartupProvider`: `lib/features/profile/presentation/providers/profile_provider.dart:52`
- Паттерн `completeOnboarding` (порядок записи): `lib/features/profile/data/datasources/local/profile_local_datasource.dart:54`
- `AppDatabase` / таблицы: `lib/features/schedule/data/datasources/local/drift_database.dart`
- GoRouter redirect guard: `lib/router/app_router.dart:32`
- `RouterNotifier` refresh: `lib/router/router_notifier.dart:11`
- `selectedSubjectProvider` seed pattern: `lib/app.dart:27`
