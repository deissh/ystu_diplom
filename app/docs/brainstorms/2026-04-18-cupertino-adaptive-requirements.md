---
date: 2026-04-18
topic: cupertino-adaptive-layout
---

# Полный переход на Cupertino + адаптивный layout

## Problem Frame

Приложение работает только на iOS, однако использует `MaterialApp` и Material 3-виджеты. Цвета уже iOS-системные (`AppColors`), но интерактивные элементы — `FilledButton`, `AlertDialog`, `CircularProgressIndicator`, `SegmentedButton` — чужеродны на iOS. Отступы захардкожены (16 dp везде), что на iPad даёт некрасивое раздутое пространство, а контент не ограничен по ширине.

Предыдущий scope (`2026-04-02-ios-visual-polish`) намеренно оставался на Material. Этот документ отменяет то ограничение и задаёт следующий шаг.

## Goals

- Заменить все Material-виджеты на Cupertino-эквиваленты — пользователь видит нативный iOS UI.
- Ввести адаптивный layout: телефоны не меняются заметно, на iPad контент центрирован и ограничен по ширине.

---

## Requirements

### R1 — Корень приложения: CupertinoApp

`MaterialApp.router` в `app.dart` заменяется на `CupertinoApp.router`.

`CupertinoApp` не принимает `ThemeMode`, поэтому переключение темы реализуется иначе:
- `AppThemeX.toThemeMode()` удаляется, заменяется на `AppThemeX.toBrightness(BuildContext)`.
- Системная тема читается из `MediaQuery.platformBrightnessOf(context)`.
- `CupertinoApp` получает `theme: CupertinoThemeData(brightness: resolvedBrightness, primaryColor: AppColors.accentLight)`.

`AppThemeData.light()` / `.dark()` сохраняются — они нужны для `Material`-виджетов внутри явных `Theme(data: ..., child: ...)` обёрток (онбординг, picker-шторки).

`_SplashScreen` в `app.dart` заменяется: убирается вложенный `MaterialApp`, остаётся чистый `CupertinoApp` с `CupertinoActivityIndicator`.

### R2 — AppColors.resolve: исправление совместимости

`AppColors.resolve(context, light, dark)` сейчас использует `Theme.of(context).brightness`, которое под `CupertinoApp` всегда возвращает `Brightness.light` (fallback ThemeData). Метод заменяется на `CupertinoTheme.brightnessOf(context)`. Изменение — одна строка в `lib/core/theme/app_colors.dart`, но затрагивает всё приложение.

### R3 — GoRouter: CupertinoPage переходы

GoRouter не переключается на `CupertinoPage` автоматически. Каждый `GoRoute.builder` в `router/app_router.dart` заменяется на `GoRoute.pageBuilder`, возвращающий `CupertinoPage(child: ...)`. Это затрагивает все маршруты: `/`, `/schedule`, `/calendar`, `/profile`, `/onboarding` и суб-маршруты.

### R4 — Scaffold и навигационные бары

| Было (Material) | Станет (Cupertino) |
|---|---|
| `Scaffold` | `CupertinoPageScaffold` |
| `SliverAppBar` (Profile) | `CupertinoSliverNavigationBar` |
| Заголовок `Text + AppTextStyles.screenTitle` | `largeTitle` в `CupertinoSliverNavigationBar` |
| `TextButton` «Изменить / Отмена / Сохранить» в `actions` | `CupertinoButton` в `trailing` / `leading` |

Нижняя вкладочная навигация (`_ScaffoldWithNavBar` в `app_router.dart`) **остаётся на `Scaffold.bottomNavigationBar`** — `StatefulShellRoute` GoRouter требует кастомного `navigationShell`, полный переход на `CupertinoTabScaffold` нецелесообразен. Кастомный `_IosTabBar` с BackdropFilter blur не меняет структуру; при необходимости иконки/лейблы переключаются на `CupertinoIcons` стиль.

Высота таб-бара: текущий `kBottomNavigationBarHeight` (56 dp) заменяется на `kMinInteractiveDimensionCupertino` (44 dp) + safe area — как в нативном iOS. Это затрагивает bottom padding в `schedule_screen.dart` и `calendar_screen.dart`.

### R5 — Индикаторы загрузки

`CircularProgressIndicator` → `CupertinoActivityIndicator` везде в приложении. Включая inline-индикатор в кнопке «Сохранить» на экране профиля.

### R6 — Диалоги и подтверждения

`showDialog` + `AlertDialog` → `showCupertinoDialog` + `CupertinoAlertDialog` + `CupertinoDialogAction`.

Конкретно — `ProfileScreen._confirmReset`:
- Диалог «Сбросить данные?» → `CupertinoAlertDialog`.
- Ошибка при сбросе (ранее `SnackBar`) → `CupertinoAlertDialog` с кнопкой «ОК». `ScaffoldMessenger` полностью убирается. Контекст для `showCupertinoDialog` проверяется через `mounted` после `await`.

### R7 — Bottom sheets и пикеры

| Было | Станет |
|---|---|
| `showModalBottomSheet` + `Column(mainSize.min)` для режима/подгруппы | `showCupertinoModalPopup` + `CupertinoActionSheet` |
| `DraggableScrollableSheet` для списка групп/преподавателей | `showModalBottomSheet` с `Material` ancestor + `CupertinoPopupSurface` стиль |

`CupertinoActionSheet` — для коротких списков (режим: Студент/Преподаватель; подгруппа: 1/2).

Для длинных picker-шторок (группы, преподаватели): `showModalBottomSheet` сохраняется, потому что `showCupertinoModalPopup` не поддерживает `DraggableScrollableSheet`. Внутри шторки добавляется явный `Material(child: ...)` ancestor, чтобы `CupertinoTextField` (поиск) и список работали корректно. Внешний вид стилизуется под iOS вручную.

### R8 — Кнопки

`FilledButton` → `CupertinoButton.filled`.  
`TextButton` → `CupertinoButton`.  
Цвет берётся из `CupertinoThemeData.primaryColor` (= `AppColors.accentLight`).

### R9 — Segmented Control

`SegmentedButton<AppTheme>` на экране профиля → `CupertinoSlidingSegmentedControl<AppTheme>`.  
Три сегмента: «Авто» / «Светлая» / «Тёмная». Иконки убираются (Cupertino-стандарт — только текст).

### R10 — Текстовые поля

`TextField` → `CupertinoTextField`.  
Поля поиска → `CupertinoSearchTextField`.  
Декорация: фон — `AppColors.surface2Light/Dark`, скругление — 10 dp, без Material `OutlineInputBorder`.

### R11 — Онбординг: изоляция Material

Онбординг-экраны (`lib/features/onboarding/`) из основного scope исключены, но они находятся в той же GoRouter-иерархии под `CupertinoApp`. Material-виджеты в онбординге (`FilledButton`, `AppBar`, `TextField`) без `Material` ancestor под `CupertinoApp` могут рендериться с дефолтным Material purple. Решение: маршрут `/onboarding` оборачивается в `Theme(data: AppThemeData.light(), child: Material(child: ...))`. Полный Cupertino-рефакторинг онбординга — в отдельном спринте.

### R12 — Адаптивный layout (телефон + iPad)

Вводится утилита `AppLayout` (static helper в `lib/core/layout/app_layout.dart`):

```
narrow  (width < 600):  hPad = 16, maxContent = double.infinity
regular (600 ≤ w < 900): hPad = 24, maxContent = 680
wide    (w ≥ 900):       hPad = 32, maxContent = 720
```

Все ключевые экраны (`ScheduleScreen`, `ProfileScreen`, `CalendarScreen`) оборачивают контент в `Center(child: ConstrainedBox(maxWidth: maxContent))`, горизонтальный padding берётся из `AppLayout.hPad(context)`.

`WeekStrip` убирает хардкод `margin: symmetric(horizontal: 16)` и использует `AppLayout.hPad(context)`.

Раскладка профиля на iPad остаётся однокомнатной — двухколоночный master-detail не входит в этот спринт.

---

## Success Criteria

- Приложение запускается через `CupertinoApp.router`; вся навигация работает корректно.
- Ни одного `CircularProgressIndicator`, `AlertDialog`, `FilledButton`, `SegmentedButton` — все заменены.
- `AppColors.resolve` использует `CupertinoTheme.brightnessOf`; тёмная тема отображается корректно.
- Переходы между экранами — iOS slide-right (`CupertinoPage`).
- На iPhone SE (375pt) и iPhone Pro Max (430pt) layout не отличается от текущего визуально.
- На iPad симуляторе (768pt+) контент центрируется и не превышает 680–720 pt.
- `flutter analyze` проходит без ошибок.

## Scope Boundaries

- Двухколоночный iPad layout (Master-Detail) — не реализуем.
- Онбординг — изолируем через `Theme` обёртку, полный рефакторинг в следующем спринте.
- `table_calendar` (CalendarScreen) — сторонний Material-виджет, оборачивается в `Material` ancestor.
- Бизнес-логика, провайдеры, репозитории, доменный слой — не меняем.
- Иконки (`Icons.*`) — не заменяем массово; точечная замена на `CupertinoIcons` по необходимости.

## Key Decisions

- **CupertinoApp вместо MaterialApp**: iOS-only таргет, нативный стиль важнее кросс-платформенности.
- **AppColors.resolve → CupertinoTheme.brightnessOf**: Одна строка, исправляет цвета во всём приложении.
- **GoRoute.pageBuilder везде**: Единственный способ получить iOS slide-right переходы через GoRouter.
- **SnackBar → CupertinoAlertDialog**: Нативного Cupertino toast нет; диалог — наиболее нативный вариант.
- **DraggableScrollableSheet в showModalBottomSheet**: `showCupertinoModalPopup` не поддерживает динамическую высоту — сохраняем Material-шторку для длинных списков, изолируя её через `Material` wrapper.
- **AppLayout-утилита**: Centralizes breakpoint logic — не дублируем `MediaQuery` в каждом виджете.

## Next Steps

→ `/ce:plan` для пошагового плана реализации
