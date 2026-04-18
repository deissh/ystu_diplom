---
title: "refactor: Full Cupertino migration + adaptive layout"
type: refactor
status: active
date: 2026-04-18
origin: docs/brainstorms/2026-04-18-cupertino-adaptive-requirements.md
---

# refactor: Full Cupertino migration + adaptive layout

## Overview

Полный переход с `MaterialApp` на `CupertinoApp`, замена всех Material-виджетов на Cupertino-эквиваленты, и введение адаптивного layout для телефонов и iPad. Работа затрагивает корень приложения, систему тем, навигацию и все экраны.

## Problem Frame

Приложение iOS-only, но использует `MaterialApp` и Material 3-виджеты: `FilledButton`, `AlertDialog`, `CircularProgressIndicator`, `SegmentedButton`. Цветовая палитра уже iOS-системная, но ни один интерактивный элемент не является нативным iOS. Отступы захардкожены (16 dp везде), контент не ограничен по ширине — iPad выглядит растянуто.

(see origin: `docs/brainstorms/2026-04-18-cupertino-adaptive-requirements.md`)

## Requirements Trace

- R1. `CupertinoApp.router` как корень; тема через `CupertinoThemeData`; `AppTheme` → `Brightness` без `ThemeMode`
- R2. `AppColors.resolve` использует `CupertinoTheme.brightnessOf` — тёмная тема работает корректно
- R3. Все `GoRoute.builder` → `pageBuilder` с `CupertinoPage` → iOS slide-right переходы
- R4. Scaffold → `CupertinoPageScaffold`; `SliverAppBar` → `CupertinoSliverNavigationBar`; `TextButton` → `CupertinoButton`
- R5. `CircularProgressIndicator` → `CupertinoActivityIndicator` везде
- R6. Диалоги и ошибки: `showCupertinoDialog` + `CupertinoAlertDialog`; `ScaffoldMessenger` убран
- R7. Bottom sheets: короткие → `CupertinoActionSheet`; длинные (группы/преподаватели) → `showModalBottomSheet` с `Material` wrapper
- R8. `FilledButton` / `TextButton` → `CupertinoButton.filled` / `CupertinoButton`
- R9. `SegmentedButton` → `CupertinoSlidingSegmentedControl`
- R10. `TextField` → `CupertinoTextField`; поиск → `CupertinoSearchTextField`
- R11. Онбординг изолирован через `Theme(AppThemeData.light()) + Material` wrapper
- R12. `AppLayout` utility: адаптивный `hPad` и `maxContent` по ширине экрана

## Scope Boundaries

- `table_calendar` (CalendarScreen) — сторонний Material-виджет; оборачивается в `Material()` ancestor, не мигрирует
- Бизнес-логика, провайдеры, репозитории, доменный слой — не трогаются
- Иконки `Icons.*` — не заменяются массово на `CupertinoIcons.*`

### Deferred to Separate Tasks

- Полный Cupertino-рефакторинг онбординг-экранов — следующий спринт
- Двухколоночный iPad layout (Master-Detail) — отдельная задача
- Замена иконок на `CupertinoIcons` — отдельная задача

---

## Context & Research

### Relevant Code and Patterns

**Файлы с Material-виджетами (исчерпывающий список):**

| Виджет | Файлы |
|--------|-------|
| `Scaffold` | `app.dart`, `app_router.dart`, `onboarding_screen.dart`, `schedule_screen.dart`, `calendar_screen.dart`, `profile_screen.dart`, `settings_screen.dart` |
| `CircularProgressIndicator` | `app.dart`, `schedule_screen.dart`, `calendar_screen.dart`, `profile_screen.dart`, `settings_screen.dart`, `group_picker_page.dart`, `teacher_picker_page.dart`, `name_entry_page.dart` |
| `FilledButton` | `schedule_screen.dart`, `calendar_screen.dart`, `name_entry_page.dart`, `group_picker_page.dart`, `teacher_picker_page.dart` |
| `TextButton` | `profile_screen.dart`, `name_entry_page.dart` |
| `AlertDialog` / `showDialog` | `profile_screen.dart`, `settings_screen.dart` |
| `showModalBottomSheet` | `profile_screen.dart` (4 вызова) |
| `SegmentedButton` | `profile_screen.dart`, `settings_screen.dart` |
| `TextField` | `profile_screen.dart` (поле имени), `group_picker_page.dart`, `teacher_picker_page.dart`, `name_entry_page.dart` |
| `ListTile` | `profile_screen.dart`, `group_picker_page.dart`, `teacher_picker_page.dart` |
| `ScaffoldMessenger` + `SnackBar` | `profile_screen.dart`, `settings_screen.dart` |
| `kBottomNavigationBarHeight` | `schedule_screen.dart`, `calendar_screen.dart` |
| `SliverAppBar` | `profile_screen.dart` |
| `AppBar` | `onboarding_screen.dart` |

**Ключевые точки:**
- `AppColors.resolve` (в `lib/core/theme/app_colors.dart`) вызывается в 29 местах; одна строка исправляет всё
- `AppThemeX.toThemeMode()` используется только в `app.dart:40` — удаляется
- `Theme.of(context).brightness` используется напрямую в `_IosTabBar` (`app_router.dart:122`) — дополнительное место для исправления
- `GoRoute.builder` → `GoRoute.pageBuilder` нужен для 4 маршрутов: `/onboarding`, `/schedule`, `/calendar`, `/profile`
- `StatefulShellRoute.indexedStack(builder:...)` остаётся `builder:` — shell-route продолжает возвращать Widget, а не Page
- `settings_screen.dart` — **мертвый код** (в роутере нет маршрута `/settings` после merge в profile); файл нужно удалить

### Institutional Learnings

- `docs/solutions/` не существует в этом проекте — нет предыдущего опыта

### External References

- Flutter docs: `CupertinoApp` + `CupertinoThemeData` не принимает `ThemeMode`; brightness выставляется через `CupertinoThemeData(brightness: Brightness?)` где `null` = следовать системе
- GoRouter: `builder:` создаёт `MaterialPage` под капотом; `pageBuilder:` даёт контроль над типом Page
- `CupertinoTheme.brightnessOf(context)` — правильный способ читать brightness под `CupertinoApp`
- `kTabBarHeight` = 49.0 (Cupertino); `kBottomNavigationBarHeight` = 56.0 (Material)
- `showCupertinoModalPopup` не поддерживает `DraggableScrollableSheet` как root child — высота должна быть фиксированной или через `SizedBox`; для drag-to-resize шторок нужно оставить `showModalBottomSheet` с `Material` wrapper

---

## Key Technical Decisions

- **`CupertinoTheme.brightnessOf(context)` в `AppColors.resolve`**: Единственная строка, от которой зависит корректность всех цветов под `CupertinoApp`. Выполняется первым делом — до любых изменений экранов.
- **`AppTheme` → `Brightness?` напрямую**: `system` → `null` (CupertinoApp берёт из системы сам), `light` → `Brightness.light`, `dark` → `Brightness.dark`. Метод `toThemeMode()` удаляется, `AppThemeData` остаётся для Material-обёрток.
- **`StatefulShellRoute.builder` не меняется**: Shell-route возвращает Widget (обёртку с tab bar), а не Page — `builder:` здесь корректен. Только branch `GoRoute` переходят на `pageBuilder`.
- **`_IosTabBar` остаётся на `Scaffold.bottomNavigationBar`**: `StatefulShellRoute` с GoRouter требует кастомного navigationShell; переход на `CupertinoTabScaffold` сломает shell-логику. Внутри `_IosTabBar` заменяем `BottomNavigationBar` на кастомный Cupertino-style виджет (три `GestureDetector`+`Column` ячейки) для нативного вида.
- **Длинные picker-шторки остаются на `showModalBottomSheet`**: `showCupertinoModalPopup` не поддерживает `DraggableScrollableSheet`. Добавляем явный `Material(child: DraggableScrollableSheet(...))` внутри шторки.
- **Онбординг изолируется через `Theme + Material`**: Маршрут `/onboarding` оборачивает `OnboardingScreen` в `Theme(data: AppThemeData.light(), child: Material(child: ...))` на уровне `pageBuilder`. Полный рефакторинг онбординга — отдельный спринт.
- **`settings_screen.dart` удаляется**: Файл — мертвый код после merge settings → profile; оставлять его нет смысла.

---

## Open Questions

### Resolved During Planning

- **Нужен ли `pageBuilder` для `StatefulShellRoute`?** — Нет. Shell возвращает Widget через `builder:`. Branch `GoRoute` нужен `pageBuilder`.
- **Как `CupertinoApp` обрабатывает `ThemeMode.system`?** — `CupertinoThemeData(brightness: null)` → автоматически следует системе через `MediaQuery`.
- **`showCupertinoModalPopup` + `DraggableScrollableSheet`?** — Несовместимо. Оставляем `showModalBottomSheet` для длинных списков с `Material` wrapper.
- **Совместима ли `BottomNavigationBar` с `CupertinoApp`?** — Да, но выглядит Material. Заменяем на кастомный Cupertino-style widget внутри `BackdropFilter`.

### Deferred to Implementation

- **Точный размер текста в `CupertinoSlidingSegmentedControl`**: Подбирается визуально во время реализации.
- **Нужна ли `Material` обёртка для `table_calendar`?** — Проверяется при запуске; добавляется если виджет падает под `CupertinoApp`.
- **Поведение `CupertinoSliverNavigationBar` с large title**: Точный порог скролла, при котором title схлопывается — видно только при запуске.

---

## High-Level Technical Design

> *Это иллюстрация намеченного подхода — directional guidance для ревью, не спецификация для копирования.*

### Поток темы: было → стало

```
// Было:
AppTheme → toThemeMode() → ThemeMode → MaterialApp(themeMode:)
  → Theme.of(context).brightness → AppColors.resolve → виджет

// Стало:
AppTheme → toBrightness() → Brightness? → CupertinoApp(theme: CupertinoThemeData(brightness:))
  → CupertinoTheme.brightnessOf(context) → AppColors.resolve → виджет
```

### Что меняется в `AppColors.resolve` (одна строка)

```
// Было:
Theme.of(context).brightness == Brightness.dark ? dark : light

// Станет:
CupertinoTheme.brightnessOf(context) == Brightness.dark ? dark : light
```

### Структура shell — `_ScaffoldWithNavBar`

```
Scaffold(extendBody: true)           // остаётся
  body: StatefulNavigationShell      // остаётся
  bottomNavigationBar:
    ClipRect > BackdropFilter        // остаётся
      _CupertinoTabRow               // НОВЫЙ: три ячейки GestureDetector+CupertinoIcons стиль
        (вместо BottomNavigationBar) // удаляется
```

### Адаптивный layout — `AppLayout`

```
AppLayout.hPad(context)       → 16 (narrow) | 24 (regular) | 32 (wide)
AppLayout.maxContent(context) → ∞  (narrow) | 680 (regular) | 720 (wide)

// Применяется в каждом экране:
Center(child: ConstrainedBox(maxWidth: AppLayout.maxContent(context),
  child: ListView(padding: EdgeInsets.symmetric(horizontal: AppLayout.hPad(context)))))
```

---

## Implementation Units

### Phase 1: Фундамент

- [ ] **Unit 1: AppColors.resolve → CupertinoTheme.brightnessOf**

**Goal:** Исправить единственный метод, от которого зависит корректность всех цветов под `CupertinoApp`. Без этого шага тёмная тема не будет работать ни в одном виджете.

**Requirements:** R2

**Dependencies:** Нет

**Files:**
- Modify: `lib/core/theme/app_colors.dart` (тело `resolve()`)
- Modify: `lib/router/app_router.dart` (строка `Theme.of(context).brightness` в `_IosTabBar.build`)

**Approach:**
- В `AppColors.resolve`: заменить `Theme.of(context).brightness` на `CupertinoTheme.brightnessOf(context)`
- В `_IosTabBar.build`: `final bool isDark = Theme.of(context).brightness == Brightness.dark` → `final bool isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark`
- Добавить `import 'package:flutter/cupertino.dart'` в `app_colors.dart`

**Patterns to follow:**
- `lib/core/theme/app_colors.dart` — существующая сигнатура `resolve` не меняется

**Test scenarios:**
- Happy path: под `CupertinoApp` с `brightness: Brightness.dark` → `AppColors.resolve` возвращает `dark` вариант
- Happy path: `brightness: Brightness.light` → возвращает `light` вариант
- Edge case: `CupertinoThemeData(brightness: null)` + системная тема dark → `CupertinoTheme.brightnessOf` возвращает `Brightness.dark`

**Verification:**
- `flutter analyze` без ошибок; `flutter run` — тёмная тема корректно меняет цвета всех виджетов

---

- [ ] **Unit 2: AppTheme → Brightness; CupertinoThemeData builder**

**Goal:** Убрать зависимость от `ThemeMode` (Material-concept), добавить `Brightness?` как bridge между `AppTheme` и `CupertinoApp`. Создать `CupertinoThemeData` builder.

**Requirements:** R1

**Dependencies:** Unit 1

**Files:**
- Modify: `lib/features/settings/domain/entities/app_settings.dart` (убрать `toThemeMode()`, добавить `toBrightness()`)
- Modify: `lib/core/theme/app_theme.dart` (добавить `AppCupertinoTheme.build(Brightness?)`)

**Approach:**
- `AppThemeX.toThemeMode()` удаляется (единственный потребитель — `app.dart`)
- Новый метод `AppThemeX.toBrightness()` → `Brightness?`: `system` → `null`, `light` → `Brightness.light`, `dark` → `Brightness.dark`
- Новый класс `AppCupertinoTheme` в `app_theme.dart` с методом `build(Brightness? brightness)` → `CupertinoThemeData` с `primaryColor: AppColors.accentLight`, текстовыми стилями из `AppTextStyles`, `brightness: brightness`
- `AppThemeData.light()` / `.dark()` не удаляются — нужны для Material wrapper'ов

**Patterns to follow:**
- Существующий `AppThemeData` в `lib/core/theme/app_theme.dart` как образец структуры builder'а

**Test scenarios:**
- Happy path: `AppTheme.system.toBrightness()` → `null`
- Happy path: `AppTheme.dark.toBrightness()` → `Brightness.dark`
- Happy path: `AppCupertinoTheme.build(Brightness.dark).brightness` → `Brightness.dark`
- Test expectation: none для удаления `toThemeMode()` — это удаление неиспользуемого API

**Verification:**
- `flutter analyze` без ошибок после удаления `toThemeMode()`

---

- [ ] **Unit 3: AppLayout — адаптивный layout utility**

**Goal:** Централизовать логику breakpoints — избежать дублирования `MediaQuery` в каждом экране.

**Requirements:** R12

**Dependencies:** Нет

**Files:**
- Create: `lib/core/layout/app_layout.dart`

**Approach:**
- Статический helper класс `AppLayout` с методами `hPad(BuildContext)` и `maxContent(BuildContext)`
- Breakpoints: `width < 600` → narrow (hPad=16, maxContent=infinity), `600 ≤ w < 900` → regular (hPad=24, maxContent=680), `w ≥ 900` → wide (hPad=32, maxContent=720)
- Читает `MediaQuery.sizeOf(context).width`
- Breakpoint-константы (`kNarrowBreakpoint`, `kRegularBreakpoint`) — публичные, чтобы их можно было использовать в тестах

**Patterns to follow:**
- Аналогично `lib/core/theme/app_colors.dart` — pure static class без инстанцирования

**Test scenarios:**
- Happy path: width=375 → hPad=16, maxContent=double.infinity
- Happy path: width=768 → hPad=24, maxContent=680
- Happy path: width=1024 → hPad=32, maxContent=720
- Edge case: width=600 ровно → regular (граница включается в regular)

**Verification:**
- Unit-тест для каждого breakpoint проходит

---

### Phase 2: Корень и навигация

- [ ] **Unit 4: app.dart — CupertinoApp.router**

**Goal:** Заменить `MaterialApp.router` на `CupertinoApp.router`; обновить тему и splash-экран.

**Requirements:** R1, R5

**Dependencies:** Unit 1, Unit 2

**Files:**
- Modify: `lib/app.dart`

**Approach:**
- `MaterialApp.router(...)` → `CupertinoApp.router(theme: AppCupertinoTheme.build(brightness), routerConfig: ...)`
- Brightness вычисляется: `ref.watch(settingsNotifierProvider).valueOrNull?.theme.toBrightness() ?? null` (`null` = system)
- `_SplashScreen`: убрать вложенный `MaterialApp`; вернуть `CupertinoApp(home: CupertinoPageScaffold(child: Center(child: CupertinoActivityIndicator())))`
- Все `import 'package:flutter/material.dart'` в `app.dart` заменяются на `flutter/cupertino.dart` где возможно; `ThemeMode` import убирается
- Убедиться: `appRouterProvider` остаётся без изменений (GoRouter-агностичен к типу App)

**Patterns to follow:**
- `lib/core/theme/app_theme.dart` — `AppCupertinoTheme.build`

**Test scenarios:**
- Integration: приложение запускается без exception под `CupertinoApp`
- Happy path: изменение темы в настройках обновляет `CupertinoApp.theme` и перестраивает дерево
- Edge case: `settingsNotifierProvider` в состоянии loading → используется `brightness: null` (system default)

**Verification:**
- Приложение запускается на iOS симуляторе; тема переключается между Авто/Светлая/Тёмная

---

- [ ] **Unit 5: app_router.dart — CupertinoPage + Material shell wrapper + кастомный tab row**

**Goal:** Добавить iOS slide-right переходы через `CupertinoPage`; предоставить `Material` ancestor для `Scaffold` в shell; заменить `BottomNavigationBar` на кастомный Cupertino-style tab row.

**Requirements:** R3, R4

**Dependencies:** Unit 4

**Files:**
- Modify: `lib/router/app_router.dart`

**Approach:**

*Shell — критический блокер P0:* `Scaffold` требует `Material` ancestor; `CupertinoApp` его не предоставляет. `_ScaffoldWithNavBar.build` должен вернуть `Material(child: Scaffold(...))`. `Material` здесь используется только как ancestor-провайдер (без собственного цвета/elevation) — указать `color: Colors.transparent` или `type: MaterialType.transparency`, чтобы фон задавался самим `Scaffold`/экраном.

*GoRoute.pageBuilder:*
- `/onboarding` → `CupertinoPage(child: Theme(data: AppThemeData.light(), child: Material(child: OnboardingScreen())))`
- `/schedule` → `CupertinoPage(child: ScheduleScreen())`
- `/calendar` → `CupertinoPage(child: CalendarScreen())`
- `/profile` → `CupertinoPage(child: ProfileScreen())`
- `StatefulShellRoute.indexedStack(builder:...)` — остаётся `builder:` (shell возвращает Widget, не Page)

*Новый `_CupertinoTabRow`* — заменяет `BottomNavigationBar` внутри `BackdropFilter`:
  - Три ячейки (`_TabItem`) — `GestureDetector` + `Column(icon + label)`
  - Иконки: `CupertinoIcons.calendar` / `CupertinoIcons.calendar_badge_plus` / `CupertinoIcons.person`
  - Активный цвет: `AppColors.resolve(context, AppColors.accentLight, AppColors.accentDark)`
  - Неактивный: `AppColors.iconInactive`
  - Высота: `kTabBarHeight` (49 dp) + `MediaQuery.of(context).padding.bottom` для safe area

**Patterns to follow:**
- Существующая структура `ClipRect > BackdropFilter > Container > Column` в `_IosTabBar` — сохраняется

**Test scenarios:**
- Integration: навигация между тремя вкладками работает без `No Material widget found` exception
- Happy path: переход /schedule → /profile имеет slide-right анимацию (CupertinoPage)
- Happy path: `/onboarding` открывается без purple Material артефактов (защищён Theme+Material wrapper)
- Edge case: возврат с онбординга на `/schedule` — переход корректен
- Edge case: `Material(type: MaterialType.transparency)` не добавляет белый фон поверх контента

**Verification:**
- На симуляторе нет `No Material widget found` exception; переходы между экранами — iOS slide; вкладки переключаются без ошибок

---

### Phase 3: Основные экраны

- [ ] **Unit 6: schedule_screen.dart — Cupertino**

**Goal:** Мигрировать экран расписания на Cupertino-виджеты и адаптивный layout.

**Requirements:** R4, R5, R8, R12

**Dependencies:** Unit 3, Unit 5

**Files:**
- Modify: `lib/features/schedule/presentation/screens/schedule_screen.dart`

**Approach:**
- `Scaffold(backgroundColor: bg, body: SafeArea(...))` → `CupertinoPageScaffold(child: SafeArea(...))`
  - У `CupertinoPageScaffold` нет `backgroundColor` в конструкторе; цвет фона задаётся через `CupertinoTheme` или через `Material(color: bg, child: ...)`; проще — добавить `Container(color: bg)` как обёртку
- `CircularProgressIndicator()` → `CupertinoActivityIndicator()`
- `FilledButton` (кнопка «Повторить») → `CupertinoButton.filled(child: Text('Повторить'), onPressed: ...)`
- `kBottomNavigationBarHeight` → `kTabBarHeight` (49.0) в вычислении `bottomPad`
- Горизонтальный padding `ListView`: `EdgeInsets.fromLTRB(16, 0, 16, bottomPad)` → `EdgeInsets.fromLTRB(AppLayout.hPad(context), 0, AppLayout.hPad(context), bottomPad)`
- Экран не имеет собственного navigation bar (он внутри shell) — `CupertinoPageScaffold` без `navigationBar`

**Patterns to follow:**
- `lib/core/layout/app_layout.dart` (Unit 3) для hPad

**Test scenarios:**
- Happy path: экран расписания рендерится без exception под `CupertinoApp`
- Happy path: кнопка «Повторить» в состоянии ошибки вызывает `ref.invalidate`
- Edge case: на iPad (width=768) → `AppLayout.hPad` = 24, контент ограничен по ширине
- Edge case: выходной день / нет пар / нет группы — все пустые состояния рендерятся

**Verification:**
- Экран расписания выглядит корректно на iPhone SE и iPad симуляторе; нет `CircularProgressIndicator`

---

- [ ] **Unit 7: calendar_screen.dart — Cupertino**

**Goal:** Мигрировать экран календаря на Cupertino-виджеты; изолировать `table_calendar`.

**Requirements:** R4, R5, R8, R12

**Dependencies:** Unit 3, Unit 5

**Files:**
- Modify: `lib/features/calendar/presentation/screens/calendar_screen.dart`

**Approach:**
- `Scaffold` → `CupertinoPageScaffold` (аналогично Unit 6)
- `CircularProgressIndicator` → `CupertinoActivityIndicator`
- `FilledButton` → `CupertinoButton.filled`
- `kBottomNavigationBarHeight` → `kTabBarHeight`
- `table_calendar` widget оборачивается в `Material(child: TableCalendar(...))` если при запуске выбрасывает ошибку о недостающем Material ancestor
- `AppLayout` для горизонтальных отступов

**Patterns to follow:**
- Unit 6 как образец подхода к screen-level Cupertino migration

**Test scenarios:**
- Happy path: экран календаря рендерится без exception
- Happy path: `table_calendar` отображает месяц корректно (Material ancestor не вызывает ошибок)
- Edge case: на iPad контент не выходит за `maxContent` 680 dp

**Verification:**
- Экран календаря работает на симуляторе; `table_calendar` отображается без артефактов

---

- [ ] **Unit 8: profile_screen.dart — Cupertino (большой файл)**

**Goal:** Полная Cupertino-миграция экрана профиля — самый сложный экран с наибольшим числом Material-зависимостей.

**Requirements:** R4, R5, R6, R7, R8, R9, R10, R12

**Dependencies:** Unit 3, Unit 5

**Files:**
- Modify: `lib/features/profile/presentation/screens/profile_screen.dart`

**Approach:**

*Scaffold / Navigation bar:*
- `Scaffold` → `CupertinoPageScaffold`
- `CustomScrollView` + `SliverAppBar(floating: true, title: ...)` → `CustomScrollView` + `CupertinoSliverNavigationBar(largeTitle: Text('Профиль'), trailing: ..., leading: ...)`
- Кнопки «Изменить» / «Отмена» / «Сохранить» из `actions:` → `trailing:` / `leading:` через `CupertinoButton`

*Loading:*
- Все `CircularProgressIndicator` → `CupertinoActivityIndicator`
- Inline-индикатор в кнопке «Сохранить» → `CupertinoActivityIndicator(radius: 8)`

*Диалог сброса (`_confirmReset`):*
- `ScaffoldMessenger.of(context)` убирается (захват до await → больше не нужен)
- `showDialog + AlertDialog` → `showCupertinoDialog + CupertinoAlertDialog + CupertinoDialogAction`
- `CupertinoDialogAction(isDestructiveAction: true, child: Text('Сбросить'))` заменяет красный `TextButton`
- Ошибка при сбросе: вместо `messenger.showSnackBar` — `showCupertinoDialog` с `CupertinoAlertDialog(title: Text('Ошибка'), content: Text('...'), actions: [CupertinoDialogAction(...)])`
- Проверка `mounted` перед `showCupertinoDialog` после `await`

*Bottom sheets — короткие:*
- `_ModePickerSheet` (Студент/Преподаватель) → `showCupertinoModalPopup` + `CupertinoActionSheet(actions: [CupertinoActionSheetAction(...)])`
- `_SubgroupPickerSheet` (1/2) → аналогично через `CupertinoActionSheet`

*Bottom sheets — длинные (DraggableScrollableSheet):*
- `_GroupPickerSheet`, `_TeacherPickerSheet` → оставить `showModalBottomSheet`; `Material` wrapper добавляется **внутри `builder:` лямбды**, не на call-site — т.е. `builder: (context) => Material(color: surface, child: DraggableScrollableSheet(...))`. `showModalBottomSheet` создаёт маршрут, но не предоставляет `Material` ancestor для содержимого; без этого `ListTile`, `Divider`, `TextField` внутри шторки бросают `No Material widget found`.
- `TextField` (поиск) внутри шторок → `CupertinoSearchTextField` (работает без Material ancestor)

*Поле имени (`_NameTile`):*
- `TextField` → `CupertinoTextField` с `placeholder: 'Необязательно'`, `textAlign: TextAlign.right`

*Список полей (`_FieldTile`, `_NameTile`):*
- `ListTile` → кастомный row: `GestureDetector > Padding > Row(leading icon, title, trailing value+chevron)`
- Существующий `_FieldTile` уже близок к нужному стилю — рефакторить без `ListTile`

*Segmented control (тема):*
- `SegmentedButton<AppTheme>` → `CupertinoSlidingSegmentedControl<AppTheme>` с `children: {AppTheme.system: Text('Авто'), ...}`

*Adaptive layout:*
- `SliverPadding(padding: EdgeInsets.fromLTRB(16, ...))` → `EdgeInsets.fromLTRB(AppLayout.hPad(context), ...)`
- Весь контент в `ConstrainedBox(maxWidth: AppLayout.maxContent(context))`

*InkWell (кнопка сброса):*
- `InkWell` → `GestureDetector` (уже нет ripple-эффекта, просто `onTap`)

**Patterns to follow:**
- Существующий `_Section` виджет (Container + BorderRadius) — оставить как есть
- Существующий стиль `_FieldTile` — основа для кастомного row без `ListTile`

**Test scenarios:**
- Happy path: профиль отображается в режиме студента и преподавателя без ошибок
- Happy path: кнопка «Изменить» → режим редактирования; «Отмена» → откат; «Сохранить» → persist
- Happy path: пикер группы открывается, поиск фильтрует список, выбор сохраняется
- Happy path: `CupertinoActionSheet` для выбора режима — Студент/Преподаватель
- Happy path: диалог сброса данных подтверждается → `resetAllData()` вызывается
- Error path: `resetAllData()` бросает exception → `CupertinoAlertDialog` с ошибкой отображается
- Edge case: `mounted` = false после await → диалог ошибки не показывается (crash prevention)
- Edge case: iPad (width=768) → контент ограничен `maxContent=680`

**Verification:**
- Весь экран профиля работает без `Material`-специфичных виджетов (кроме picker-шторок с `Material` wrapper); нет `ScaffoldMessenger`, `AlertDialog`, `SegmentedButton`

---

### Phase 4: Вспомогательные экраны

- [ ] **Unit 9: Удаление settings_screen.dart (мёртвый код)**

**Goal:** Убрать мёртвый код — файл, который больше не подключён к роутеру после merge settings → profile.

**Requirements:** (неявное — чистота кодовой базы)

**Dependencies:** Unit 8

**Files:**
- Delete: `lib/features/settings/presentation/screens/settings_screen.dart`
- Delete: `lib/features/settings/presentation/` (если директория пустеет полностью — проверить)

**Approach:**
- Проверить все `import` в проекте на наличие `settings_screen.dart` через grep — убедиться, что нет потребителей
- Если `lib/features/settings/presentation/` содержит только `providers/settings_provider.dart` — директорию не трогать, только удалить screen
- Удалить файл

**Test scenarios:**
- Test expectation: none — удаление файла; `flutter analyze` проходит без ошибок

**Verification:**
- `flutter analyze` чист; `grep -r 'settings_screen' lib/` ничего не находит

---

- [ ] **Unit 10: Онбординг — изоляция под CupertinoApp**

**Goal:** Защитить Material-виджеты онбординга от рендеринга с дефолтным Material purple под `CupertinoApp`; без изменения самих онбординг-виджетов.

**Requirements:** R11

**Dependencies:** Unit 5

**Files:**
- Modify: `lib/router/app_router.dart` (уже изменён в Unit 5 — `/onboarding` pageBuilder)

**Approach:**
- В `pageBuilder` для `/onboarding`: `CupertinoPage(child: Theme(data: AppThemeData.light(), child: Material(child: OnboardingScreen())))`
- `Theme` обёртка предоставляет корректный `ThemeData` для Material-виджетов внутри
- `Material` обёртка обеспечивает `Material` ancestor, который требуют Material-виджеты (`FilledButton`, `AppBar`, `TextField`)
- Явно проверить: `Colors.white` фон `Material` может конфликтовать с `AppColors.bgLight` — указать `color: AppColors.bgLight`

**Patterns to follow:**
- `lib/core/theme/app_theme.dart` — `AppThemeData.light()`

**Test scenarios:**
- Happy path: онбординг открывается без exception под `CupertinoApp`
- Happy path: `FilledButton` в онбординге рендерится с корректным accent-цветом (не дефолтный Material purple)
- Integration: прохождение онбординга завершается корректным редиректом на `/schedule`

**Verification:**
- Онбординг на симуляторе: нет фиолетовых кнопок, нет fallback Material стилей

---

## System-Wide Impact

- **Interaction graph:** `AppColors.resolve` — меняется реализация, вызывается в 29 местах; все 29 мест автоматически получают исправленный brightness после Unit 1 без правок call-sites
- **Error propagation:** `ScaffoldMessenger` удаляется из двух файлов; ошибки теперь через `showCupertinoDialog` — контекст должен быть `mounted` после async
- **State lifecycle risks:** `CupertinoSliverNavigationBar` перестраивается при скролле — убедиться, что `ConsumerStatefulWidget` state не теряется при collapse/expand
- **API surface parity:** `AppThemeX.toThemeMode()` удаляется — если есть внешние потребители (тесты, другие виджеты), они сломаются; grep должен показать только `app.dart` как потребителя
- **Integration coverage:** После Unit 4 + 5 нужно запустить всё приложение end-to-end (онбординг → профиль → расписание) прежде чем двигаться в Phase 3
- **Unchanged invariants:** Бизнес-логика, Riverpod-провайдеры, Drift-слой, GoRouter redirect guard — не изменяются

---

## Risks & Dependencies

| Risk | Mitigation |
|------|------------|
| **`Scaffold` в shell требует `Material` ancestor — `CupertinoApp` его не предоставляет (P0)** | Unit 5: `_ScaffoldWithNavBar.build` возвращает `Material(type: MaterialType.transparency, child: Scaffold(...))` |
| **`DraggableScrollableSheet` в `showModalBottomSheet` без `Material` ancestor (P1)** | Unit 8: `builder: (ctx) => Material(color: surface, child: DraggableScrollableSheet(...))` — wrapper внутри builder-лямбды, не на call-site |
| `CupertinoPageScaffold` не имеет `backgroundColor` — фон может быть белым вместо iOS серого | Обернуть содержимое в `ColoredBox(color: AppColors.bgLight/Dark)` или использовать `CupertinoTheme` |
| `table_calendar` падает без `Material` ancestor | Добавить `Material(child: TableCalendar(...))` при запуске — зафиксировано как деferred |
| `CupertinoSliverNavigationBar` требует `CustomScrollView` — layout может поломаться | Тестировать на симуляторе сразу после Unit 8; откат к `SliverAppBar` + кастомный стиль если нужно |
| `AppThemeX.toThemeMode()` может использоваться в тестах | `grep -r 'toThemeMode'` перед удалением |

---

## Documentation / Operational Notes

- После миграции: добавить запись в `docs/solutions/` (создать директорию) — «Flutter: Cupertino + GoRouter — использовать `pageBuilder`, `AppColors.resolve` → `CupertinoTheme.brightnessOf`»
- `CLAUDE.md` обновить: убрать упоминание `MaterialApp`, добавить `CupertinoApp`, обновить структуру `app.dart`

---

## Sources & References

- **Origin document:** [docs/brainstorms/2026-04-18-cupertino-adaptive-requirements.md](docs/brainstorms/2026-04-18-cupertino-adaptive-requirements.md)
- **Feasibility review findings:** P0-1 (`AppColors.resolve`), P0-2 (ThemeMode), P0-3 (GoRouter pageBuilder), P0-4 (shell structure), P1-1 (DraggableScrollableSheet), P1-2 (splash), P1-3 (kBottomNavigationBarHeight), P1-4 (ScaffoldMessenger async), P1-5 (onboarding isolation) — все учтены в плане
- Related plans: `docs/plans/2026-04-02-002-refactor-ios-visual-polish-plan.md` (предшественник)
- Related code: `lib/core/theme/app_colors.dart`, `lib/app.dart`, `lib/router/app_router.dart`
