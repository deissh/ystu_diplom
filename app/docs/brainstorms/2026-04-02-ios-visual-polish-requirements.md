---
date: 2026-04-02
topic: ios-visual-polish
---

# iOS Visual Polish

## Problem Frame

Приложение использует iOS-системные цвета, но общий вид остаётся Material 3 по ощущению: нижняя навигация без blur-эффекта, неравномерные отступы, тени не везде согласованы. Пользователь видит знакомые цвета, но не чувствует iOS-атмосферы.

## Requirements

- **R1. Нижняя навигация с blur/frosted-glass.** Tab bar имеет полупрозрачный фон с blur-эффектом (эффект матового стекла, как CupertinoTabBar), тонкий разделитель сверху, без Material-индикатора выбора. Активная иконка — accent, неактивная — `iconInactive (#8E8E93)`. Высота bar учитывает safe-area (динамический Island / notch).
- **R2. Контент скролируется под tab bar.** Поскольку tab bar становится overlay поверх контента, все `ListView` и прокручиваемые зоны получают нижний padding, равный высоте tab bar + safe-area, чтобы контент не обрезался.
- **R3. Согласованные iOS-тени на «карточных» поверхностях.** Все Card-подобные контейнеры (SyncStatusBar, LessonCard) используют единый токен тени: `BoxShadow(color: black 6%, blurRadius: 6, offset: Offset(0, 1))` в light-теме, без тени в dark-теме.
- **R4. Пространство и отступы в стиле Apple HIG.** Горизонтальные поля контента — 16 dp. Вертикальные промежутки между секциями — минимум 12 dp. WeekStrip и MonthGrid получают явный отступ от верхней safe-area.
- **R5. Список расписания без лишних разделителей.** Между карточками `TimelineItem` нет Material-style divider'ов — только `SizedBox(height: 8)` и `BreakRow` (уже реализованы). Подтвердить и зафиксировать как стандарт.

## Success Criteria

- Нижняя навигация визуально неотличима от iOS tab bar при беглом взгляде.
- Контент виден под tab bar при скролле (frosted effect) и не обрезается в нижней точке.
- Тени на карточках согласованы во всех экранах (Schedule / Calendar / Profile).
- Отступы соответствуют Apple HIG (16 dp боковые поля).

## Scope Boundaries

- Остаёмся на Material 3 виджетах — Cupertino-виджеты (CupertinoTabBar, CupertinoButton) не используются.
- Шрифт не меняем — SF Pro автоматически используется Flutter на iOS; на Android системный шрифт.
- Не трогаем логику или данные — только визуальный слой.
- Экран Profile не обновляется детально (заглушка), только получает корректные отступы за счёт R4/R2.

## Key Decisions

- **Material стилизованный под iOS, не Cupertino:** Меньше риска, быстрее, не ломает Android-сборку.
- **Blur через BackdropFilter + Stack overlay:** Единственный способ добиться frosted-glass в Material-приложении без смены ScaffoldMessenger.
- **Единый токен тени (R3):** Сейчас SyncStatusBar и LessonCard используют разные параметры — унифицируем.

## Outstanding Questions

### Deferred to Planning

- **[Affects R1][Technical]** Как именно встроить `BackdropFilter`-bar в `GoRouter StatefulShellRoute`? Нужно ли заменить `Scaffold.bottomNavigationBar` на `Stack` или возможен другой подход.
- **[Affects R1][Technical]** Уточнить значение `sigmaX/sigmaY` для blur (рекомендация Apple — ~20, нужно подобрать визуально).
- **[Affects R2][Technical]** Как передать высоту tab bar вниз в `ListView` (MediaQuery, InheritedWidget, константа)?

## Next Steps

→ `/ce:plan` для структурированного планирования реализации
