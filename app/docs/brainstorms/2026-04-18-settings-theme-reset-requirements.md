---
date: 2026-04-18
topic: settings-theme-reset
---

# Настройки: переключение темы и сброс данных

## Problem Frame

Экран настроек — заглушка (`Center(child: Text('Settings'))`), а `ThemeMode` в `app.dart` захардкожен как `ThemeMode.dark`. Нужно реализовать два базовых пункта настроек: выбор темы оформления и сброс всех данных приложения.

## Requirements

- R1. Экран настроек содержит переключатель темы с тремя вариантами: **Системная**, **Светлая**, **Тёмная** (соответствуют `AppTheme.system/light/dark`, которые уже определены в `app_settings.dart`).
- R2. Выбранная тема сохраняется в SharedPreferences и применяется к `MaterialApp.router` через `ThemeMode` (без перезапуска приложения).
- R3. При следующем запуске приложения тема восстанавливается из SharedPreferences.
- R4. Экран настроек содержит кнопку **«Сбросить данные и настройки»**, защищённую диалогом подтверждения.
- R5. При подтверждении сброса очищаются:
  - профиль пользователя и флаг `onboarding_complete` (SharedPreferences)
  - кэш расписания (Drift SQLite)
  - настройки приложения (SharedPreferences)
- R6. После сброса GoRouter автоматически перенаправляет пользователя на онбординг — как при первом запуске.

## Success Criteria

- Смена темы отражается на UI немедленно, без перезапуска.
- После сброса приложение ведёт себя идентично первому запуску: показывает онбординг.
- Настройки темы переживают перезапуск приложения.

## Scope Boundaries

- Настройка уведомлений (`notificationsEnabled` в `AppSettings`) — **не входит** в этот scope; поле остаётся в модели как заготовка.
- Экспорт / резервное копирование данных перед сбросом — не входит.
- Анимированный переход при смене темы — не входит.

## Key Decisions

- **Тема хранится в SharedPreferences**: конфигурационные данные, а не бизнес-данные — SharedPreferences предпочтительнее Drift.
- **После сброса — онбординг**: GoRouter уже имеет redirect guard по флагу `onboarding_complete`; сброс флага достаточен для редиректа без явной навигации.
- **Диалог подтверждения**: деструктивное действие требует явного подтверждения, чтобы избежать случайного сброса.

## Dependencies / Assumptions

- `shared_preferences` уже подключён (используется в `profile_local_datasource.dart` и `app_startup_notifier.dart`).
- Drift база данных доступна через провайдер; для очистки расписания достаточно вызвать `DELETE` по таблице `lesson_entries`.
- `AppStartupNotifier` необходимо инвалидировать после сброса, чтобы GoRouter заново прочитал состояние.

## Outstanding Questions

### Deferred to Planning

- [Affects R2][Technical] Как именно передать `ThemeMode` из `settingsProvider` в `MaterialApp.router` в `app.dart` — через `ref.watch` в `ConsumerWidget` или через отдельный `themeModeProvider`.
- [Affects R5][Technical] Нужно ли явно вызывать `SharedPreferences.clear()` или точечно удалять ключи (`onboarding_complete`, `profile`, настройки) — зависит от того, есть ли в SharedPreferences другие ключи, которые трогать не нужно.

## Next Steps

→ `/ce:plan` для структурированного планирования реализации
