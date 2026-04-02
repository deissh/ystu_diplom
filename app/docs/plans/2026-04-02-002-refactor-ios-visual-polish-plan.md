---
title: "refactor: iOS Visual Polish — blur tab bar, unified shadows, HIG spacing"
type: refactor
status: active
date: 2026-04-02
origin: docs/brainstorms/2026-04-02-ios-visual-polish-requirements.md
---

# refactor: iOS Visual Polish — blur tab bar, unified shadows, HIG spacing

## Overview

Material 3 приложение выглядит функционально, но остаётся узнаваемо Material по ощущению. Цвета уже iOS-системные; не хватает frosted-glass tab bar, согласованных теней и чистых отступов. Этот рефактор полирует визуальный слой без изменения бизнес-логики.

## Problem Statement / Motivation

- Нижняя навигация — плоская Material 3 без blur, без separator'а сверху, с Material ripple
- Тени на карточках: `blurRadius: 3` — резкие для iOS-стиля (нужно `blurRadius: 6`)
- Тень задана inline в каждом виджете — нет единого токена
- Контент ListView обрезается за нижней навигацией (не хватает bottom padding)

(see origin: docs/brainstorms/2026-04-02-ios-visual-polish-requirements.md)

## Proposed Solution

1. **Blur tab bar (R1):** `Scaffold(extendBody: true)` + обёртка `BottomNavigationBar` в `ClipRect → BackdropFilter(sigma: 20) → Container(semi-transparent surface)`. Сверху — hairline `Divider`. Ripple убран через `splashFactory: NoSplash` (уже задан в теме).
2. **Bottom padding (R2):** `ListView` в `ScheduleScreen` и `CalendarScreen` получают `padding.bottom = kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom`.
3. **Единый токен тени (R3):** `AppColors.cardShadow(isDark)` — `List<BoxShadow>` с `blurRadius: 6`, `alpha: 0.06`, `offset: Offset(0, 1)`. Все три виджета (WeekStrip, SyncStatusBar, LessonCard) переключаются на него.
4. **Spacing audit (R4):** Верхний `SizedBox(height: 8)` в обоих экранах → `SizedBox(height: 12)`. Горизонтальные отступы уже 16 dp везде — подтверждаем.
5. **R5 (уже выполнен):** Material divider'ов нет — зафиксировать как стандарт в комментарии к `schedule_ui_helpers.dart`.

## Technical Considerations

### Blur tab bar: `extendBody` подход

```dart
// lib/router/app_router.dart
Scaffold(
  extendBody: true,   // body extends behind bottom bar
  body: shell,
  bottomNavigationBar: _IosTabBar(shell: shell),
)

// _IosTabBar widget:
ClipRect(
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
    child: Container(
      color: surfaceColor.withValues(alpha: 0.85),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Divider(height: 0.5, thickness: 0.5, color: separator),
        BottomNavigationBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          selectedItemColor: accent,
          unselectedItemColor: AppColors.iconInactive,
          ...
        ),
      ]),
    ),
  ),
)
```

`extendBody: true` позволяет контенту scaffold заходить под tab bar — именно в этом слое `BackdropFilter` видит его и размывает. Без `extendBody` blur будет видеть только пустоту.

### Токен тени

```dart
// lib/core/theme/app_colors.dart
static List<BoxShadow> cardShadow(bool isDark) => isDark
    ? const []
    : [
        BoxShadow(
          color: Color(0x0F000000), // black 6% = 0x0F ≈ 15/255
          blurRadius: 6,
          offset: Offset(0, 1),
        ),
      ];
```

Три виджета заменяют inline `boxShadow:` → `AppColors.cardShadow(isDark)`:
- `lib/features/schedule/presentation/widgets/week_strip.dart:61`
- `lib/features/schedule/presentation/widgets/sync_status_bar.dart:92`
- `lib/features/schedule/presentation/widgets/timeline/lesson_card/lesson_card.dart:54`

### Bottom padding расчёт

```dart
// В ScheduleScreen и CalendarScreen
final bottomPad = kBottomNavigationBarHeight
    + MediaQuery.of(context).padding.bottom;

ListView(
  padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad),
  ...
)
```

Подходит для любого устройства: iPhone SE (нет notch) и iPhone с Dynamic Island.

### `dart:ui` import для `ImageFilter`

`BackdropFilter` использует `dart:ui.ImageFilter`. Не нужно добавлять зависимости — это часть Flutter core.

## System-Wide Impact

- **Interaction graph:** Чисто визуальный слой. Провайдеры, репозитории и доменный код не затронуты.
- **extendBody side-effect:** `Scaffold` с `extendBody: true` передаёт дополнительный bottom `MediaQuery.padding` в дочерние виджеты. `SafeArea` внутри экранов уже корректно это обрабатывает — проверить, что SafeArea не конфликтует с новым tab bar overlay.
- **BottomNavigationBar elevation:** `elevation: 0` убирает Material drop shadow — заменяется нашим hairline separator'ом. Это единственное поведение, которое меняется для пользователя.

## Acceptance Criteria

- [ ] Tab bar имеет blur-эффект: контент, прокручивающийся за ним, виден размытым
- [ ] Над tab bar — hairline separator (0.5 dp), цвет `separatorLight/Dark`
- [ ] Активная иконка — accent (`#007AFF`), неактивная — `#8E8E93`
- [ ] Material ripple/highlight на tab bar отсутствует
- [ ] Контент в `ScheduleScreen` и `CalendarScreen` не обрезается за tab bar в нижней точке прокрутки
- [ ] `AppColors.cardShadow(isDark)` определён и используется в WeekStrip, SyncStatusBar, LessonCard
- [ ] Тень: `blurRadius: 6`, `color: black 6%`, `offset: (0, 1)` в light; пусто в dark
- [ ] Верхний отступ на обоих экранах — 12 dp (был 8)
- [ ] `flutter analyze` — 0 предупреждений

## Dependencies & Risks

| Риск | Вероятность | Митигация |
|------|-------------|-----------|
| `extendBody` меняет поведение `SafeArea` | Низкая | Тест на iPhone SE + iPhone 16 Pro |
| `BackdropFilter` на старых Android падает с производительностью | Средняя | Scope Boundary: только iOS-таргет; на Android blur работает нормально начиная с API 21 |
| `alpha: 0.85` может быть слишком прозрачным или непрозрачным | Низкая | Визуальная настройка при реализации: диапазон 0.75–0.92 |
| `kBottomNavigationBarHeight` (56 dp) не совпадает с реальной высотой бара | Низкая | Использовать `LayoutBuilder` или `MediaQuery` если нужно |

## File Checklist

```
lib/core/theme/app_colors.dart                                  [modify] add cardShadow()
lib/router/app_router.dart                                      [modify] extendBody + _IosTabBar
lib/features/schedule/presentation/widgets/week_strip.dart      [modify] cardShadow token
lib/features/schedule/presentation/widgets/sync_status_bar.dart [modify] cardShadow token
lib/features/schedule/presentation/widgets/timeline/
  lesson_card/lesson_card.dart                                  [modify] cardShadow token
lib/features/schedule/presentation/screens/schedule_screen.dart [modify] bottom padding
lib/features/calendar/presentation/screens/calendar_screen.dart [modify] bottom padding
lib/features/schedule/presentation/utils/schedule_ui_helpers.dart [modify] R5 comment
```

---

## Sources & References

### Origin
- **Origin document:** [docs/brainstorms/2026-04-02-ios-visual-polish-requirements.md](../brainstorms/2026-04-02-ios-visual-polish-requirements.md)
  - Ключевые решения: Material 3, не Cupertino; blur через BackdropFilter+extendBody; единый токен тени; шрифт не трогаем.

### Internal References
- Router и Scaffold: `lib/router/app_router.dart`
- Текущие тени WeekStrip: `lib/features/schedule/presentation/widgets/week_strip.dart:61`
- Текущие тени SyncStatusBar: `lib/features/schedule/presentation/widgets/sync_status_bar.dart:92`
- Текущие тени LessonCard: `lib/features/schedule/presentation/widgets/timeline/lesson_card/lesson_card.dart:54`
- Цвет `iconInactive` уже в AppColors: `lib/core/theme/app_colors.dart:60`
