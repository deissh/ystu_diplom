---
title: "feat: Profile management and onboarding flow"
type: feat
status: active
date: 2026-04-17
origin: docs/brainstorms/2026-04-17-profile-onboarding-requirements.md
---

# feat: Profile management and onboarding flow

## Overview

Реализовать онбординг для новых пользователей (выбор режима студент/преподаватель + группы или преподавателя) и экран редактирования профиля. Расписание должно реагировать на смену субъекта в профиле. Первый запуск → онбординг → расписание выбранной группы/преподавателя.

## Problem Statement / Motivation

Приложение показывает захардкоженную группу `'ЦИС-47'`. Пользователь не может выбрать свою группу. `Profile` сущность существует только в скелетном виде и не поддерживает режим преподавателя. SharedPreferences не подключён. GoRouter не имеет guard-а для перенаправления на онбординг. (see origin: docs/brainstorms/2026-04-17-profile-onboarding-requirements.md)

## Proposed Solution

Шесть последовательных фаз, каждая независимо собираемая:

1. **Foundation** — SharedPreferences + переработка `Profile` entity + персистентный datasource.
2. **Schedule bridge** — `SelectedSubject` sealed class заменяет `selectedGroupIdProvider`; `ScheduleRepository` получает teacher-mode путь.
3. **Explicit refresh** — `GroupsRepository` и `TeachersRepository` получают методы с propagation ошибок для онбординга.
4. **Startup bootstrap** — `AppStartupNotifier` читает флаг и профиль при запуске; GoRouter redirect guard.
5. **Onboarding feature** — мультишаговый `PageView` wizard под `/onboarding`.
6. **Profile screen** — полноценный экран просмотра и редактирования профиля.

## Technical Considerations

### Profile entity redesign

Текущая `Profile` (id, name, groupId, groupName) не поддерживает режим преподавателя.
Новая плоская структура (SharedPreferences-friendly):

```dart
// lib/features/profile/domain/entities/profile.dart
enum ProfileMode { student, teacher }

class Profile {
  final ProfileMode mode;
  final String? groupName;      // student only, e.g. 'ЦИС-47'
  final int?    subgroup;       // 1 or 2, student only
  final String? displayName;   // optional, student only
  final int?    teacherId;      // teacher only
  final String? teacherName;   // teacher only (cached for display)

  const Profile({
    required this.mode,
    this.groupName,
    this.subgroup,
    this.displayName,
    this.teacherId,
    this.teacherName,
  });
}
```

`ProfileModel` обновляется с теми же ключами в JSON. Сериализация в SharedPreferences под ключом `'profile'` как `jsonEncode(model.toJson())`.

### SelectedSubject sealed class

`selectedGroupIdProvider: StateProvider<String>` не универсален для учителей. Заменить на:

```dart
// lib/features/schedule/domain/entities/selected_subject.dart
sealed class SelectedSubject {
  const SelectedSubject();
}
class GroupSubject extends SelectedSubject {
  final String groupName;
  const GroupSubject(this.groupName);
}
class TeacherSubject extends SelectedSubject {
  final int teacherId;
  final String teacherName;
  const TeacherSubject(this.teacherId, this.teacherName);
}
```

```dart
// В schedule_provider.dart:
final selectedSubjectProvider = StateProvider<SelectedSubject?>((ref) => null);
```

`scheduleProvider` переключает вызов по типу `SelectedSubject`. Это решает C4 из SpecFlow.

### GroupsRepository / TeachersRepository — explicit refresh

Текущий `_sync()` — fire-and-forget. Для онбординга нужен метод с propagation ошибки:

```dart
abstract interface class GroupsRepository {
  Future<List<GroupInstitute>> getGroups();
  Future<Failure?> refreshGroups(); // null = success, Failure = error
}
```

Аналогично для `TeachersRepository`. Онбординг вызывает `refreshGroups()` и показывает Retry, если не null. Тёплый кэш (Drift не пустой) — показываем список даже без сети (offline-first, I1 из SpecFlow).

### Startup bootstrap

```dart
// lib/core/startup/app_startup_notifier.dart
class AppStartupData {
  final bool onboardingComplete;
  final Profile? profile;
}

class AppStartupNotifier extends AsyncNotifier<AppStartupData> {
  @override
  Future<AppStartupData> build() async {
    final prefs = await SharedPreferences.getInstance();
    final flag = prefs.getBool('onboarding_complete') ?? false;
    final profileJson = prefs.getString('profile');
    final profile = profileJson != null
        ? ProfileModel.fromJson(jsonDecode(profileJson)).toEntity()
        : null;
    return AppStartupData(onboardingComplete: flag, profile: profile);
  }
}

final appStartupProvider = AsyncNotifierProvider<AppStartupNotifier, AppStartupData>(
  AppStartupNotifier.new,
);
```

`app.dart` оборачивает `MaterialApp.router` в `AsyncValue.when` от `appStartupProvider` (splash пока данные загружаются). GoRouter `redirect` читает startup синхронно через `ref.read(appStartupProvider)`.

### GoRouter redirect guard

```dart
// lib/router/app_router.dart
GoRouter(
  navigatorKey: _rootNavKey,
  initialLocation: '/schedule',
  redirect: (context, state) {
    // Читаем напрямую из ProviderContainer через ref, переданного через GoRouterProvider
    final startup = ref.read(appStartupProvider);
    if (startup is AsyncLoading) return null; // сплэш ещё идёт
    final data = startup.valueOrNull;
    final done = data?.onboardingComplete ?? false;
    if (!done && state.matchedLocation != '/onboarding') return '/onboarding';
    if (done && state.matchedLocation == '/onboarding') return '/schedule';
    return null;
  },
  routes: [
    GoRoute(path: '/onboarding', builder: (ctx, state) => const OnboardingScreen()),
    StatefulShellRoute.indexedStack(...)  // существующий shell
  ],
)
```

`GoRouter` создаётся через `GoRouter.configure` с `ref`-доступом (паттерн: `ref` передаётся через `RouterNotifier`). Это решает C3 и C5.

### Onboarding wizard

Один `StatefulWidget` с `PageController`. Пять "страниц" (не GoRouter routes):

| Страница | Содержимое |
|---|---|
| 0 | Выбор режима: Студент / Преподаватель |
| 1a (student) | Поиск и выбор группы (секции по институтам) |
| 1b (teacher) | Поиск и выбор преподавателя (плоский список) |
| 2 (student) | Выбор подгруппы: 1 / 2 (hardcoded) |
| 3 (student) | Ввод имени (TextField + кнопка "Пропустить") |

Кнопка "Назад" на каждой странице — `pageController.previousPage()`. Кнопка "Продолжить/Готово" — переход вперёд или финальный save.

### Write order (atomic safety, I5 из SpecFlow)

```dart
// ВАЖНО: сначала профиль, потом флаг
await prefs.setString('profile', jsonEncode(ProfileModel.fromEntity(profile).toJson()));
await prefs.setBool('onboarding_complete', true);
```

Краш между записями → флаг false → повторный онбординг при следующем запуске (recoverable).

### Mode switch in Profile edit (I4)

При смене режима поля старого режима сбрасываются **на Save**, не немедленно:
- Локальное состояние редактора хранит оба набора полей.
- `Save` → зависит от выбранного `mode`: только нужные поля попадают в `Profile`.

## System-Wide Impact

### Interaction Graph

```
ProfileScreen.save()
  → ProfileNotifier.save(profile)
    → ProfileLocalDatasource.saveProfile()  // SharedPreferences write
    → ref.read(selectedSubjectProvider.notifier).state = subject  // из profile
      → scheduleProvider stream rebuilds (watches selectedSubjectProvider)
        → ScheduleRepositoryImpl._sync() запускается для нового субъекта
```

```
OnboardingScreen._finish()
  → prefs.setString('profile', ...)
  → prefs.setBool('onboarding_complete', true)
  → appStartupProvider.invalidate()  // пересчёт startup state
  → GoRouter redirect срабатывает → '/schedule'
  → selectedSubjectProvider инициализируется из profile
```

### Error Propagation

- `GroupsRepositoryImpl.refreshGroups()` ловит `NetworkException` → возвращает `NetworkFailure` (не throw).
- `OnboardingNotifier` подписывается на `AsyncValue<List<GroupInstitute>>` — пустой список + наличие `NetworkFailure` → показывает error state.
- `ProfileLocalDatasource.saveProfile()` бросает `CacheException` при ошибке SharedPreferences write; `ProfileRepositoryImpl` конвертирует в `CacheFailure`; `ProfileNotifier` ловит и предоставляет `AsyncError`.

### State Lifecycle Risks

- `onboarding_complete = true` без записи профиля → guard пройден, но `selectedSubjectProvider = null` → schedule показывает пустой экран. Решение: write order (профиль первый).
- Повторное нажатие "Готово" при медленном save → двойная запись. Решение: кнопка `Finish` disabled в `AsyncLoading` состоянии `ProfileNotifier`.

### API Surface Parity

`ScheduleRepository` получает новую сигнатуру:
```dart
Stream<List<ScheduleDay>> watchSchedule(SelectedSubject subject, DateTime date);
```
Оба существующих call sites (schedule_provider.dart) обновляются одновременно.

## Acceptance Criteria

- [ ] Новый пользователь при первом запуске видит экран онбординга, не расписание
- [ ] Онбординг предлагает выбор: Студент или Преподаватель
- [ ] Студент проходит шаги: группа → подгруппа → имя (опционально)
- [ ] Преподаватель видит список преподавателей и выбирает одного
- [ ] Список групп/преподавателей загружается из YSTU API; пустой Drift + нет сети → error state с кнопкой Повторить
- [ ] Список групп/преподавателей с тёплым кэшем доступен оффлайн
- [ ] После завершения онбординга: флаг сохранён, профиль сохранён, экран расписания показывает данные выбранной группы/преподавателя
- [ ] Повторный запуск приложения → сразу расписание (флаг onboarding_complete = true)
- [ ] Вкладка Профиль показывает текущий режим, группу/преподавателя, подгруппу, имя
- [ ] Изменение группы во вкладке Профиль немедленно перезагружает расписание
- [ ] Смена режима (студент ↔ преподаватель) в профиле работает; старые поля сбрасываются при сохранении
- [ ] `AppLogger` используется вместо `print` во всех новых файлах
- [ ] Модели не передаются в domain-слой

## Dependencies & Risks

### Зависимости

- **Реализован план `2026-04-17-001`** (API client, Drift schema v2 с `GroupsTable` + `TeachersTable`). Без него список групп/преподавателей не загрузится из API.
- **SharedPreferences пакет** должен быть добавлен в `pubspec.yaml` до фазы 1.

### Риски

| Риск | Вероятность | Митигация |
|---|---|---|
| GoRouter ref-доступ в redirect усложняет инициализацию | Средняя | Использовать `RouterNotifier` + `ChangeNotifierProvider` паттерн из GoRouter docs |
| `watchSchedule` signature change ломает существующий schedule экран | Низкая | Обе фазы (schedule bridge + repository update) делать в одном коммите |
| SharedPreferences write fails на устройстве | Очень низкая | Wrap в try/catch, CacheException → CacheFailure в UI |

## Implementation Plan

### Phase 1 — Foundation: Profile entity + SharedPreferences persistence

**Files:**
- `pubspec.yaml` — добавить `shared_preferences: ^2.3.4`
- `lib/features/profile/domain/entities/profile.dart` — добавить `ProfileMode` enum; обновить `Profile` с новыми nullable полями; `displayName` → `String?`
- `lib/features/profile/data/models/profile_model.dart` — обновить `fromJson` / `toJson` / `fromEntity` / `toEntity` под новую структуру
- `lib/features/profile/data/datasources/local/profile_local_datasource.dart` — реализовать `getProfile()`, `saveProfile()`, `deleteProfile()` через `SharedPreferences`; key `'profile'` как JSON string; key `'onboarding_complete'` как bool
- `lib/features/profile/data/repositories/profile_repository_impl.dart` — обернуть datasource, конвертировать `CacheException` → `CacheFailure`
- `lib/features/profile/domain/use_cases/get_profile.dart` — уже есть, без изменений
- `lib/features/profile/domain/use_cases/save_profile.dart` — уже есть, без изменений

**Acceptance:** `ProfileLocalDatasource` сохраняет и читает профиль студента и преподавателя без потери данных.

---

### Phase 2 — Schedule bridge: SelectedSubject + teacher schedule path

**Files:**
- `lib/features/schedule/domain/entities/selected_subject.dart` — новый файл: `sealed class SelectedSubject`, `GroupSubject`, `TeacherSubject`
- `lib/features/schedule/domain/repositories/schedule_repository.dart` — обновить сигнатуру `watchSchedule(SelectedSubject subject, DateTime date)`
- `lib/features/schedule/data/repositories/schedule_repository_impl.dart` — `switch (subject)` на `GroupSubject` / `TeacherSubject`; для `TeacherSubject` вызывать `apiClient.fetchTeacherSchedule(id)`
- `lib/features/schedule/presentation/providers/schedule_provider.dart` — заменить `selectedGroupIdProvider` на `selectedSubjectProvider: StateProvider<SelectedSubject?>`; `scheduleProvider` watches `selectedSubjectProvider`

**Acceptance:** Schedule screen показывает расписание как для группы, так и для преподавателя в зависимости от `selectedSubjectProvider`.

---

### Phase 3 — Explicit refresh for onboarding

**Files:**
- `lib/features/schedule/domain/repositories/groups_repository.dart` — добавить `Future<Failure?> refreshGroups()`
- `lib/features/schedule/domain/repositories/teachers_repository.dart` — добавить `Future<Failure?> refreshTeachers()`
- `lib/features/schedule/data/repositories/groups_repository_impl.dart` — реализовать `refreshGroups()`: вызывает `apiClient.fetchGroups()` → `dao.upsertGroups()`, возвращает `null` или `NetworkFailure`; существующий `_sync()` остаётся для фоновых обновлений
- `lib/features/schedule/data/repositories/teachers_repository_impl.dart` — аналогично для учителей

**Acceptance:** `refreshGroups()` возвращает `NetworkFailure` при отсутствии сети и пустом кэше.

---

### Phase 4 — Startup bootstrap + GoRouter guard

**Files:**
- `lib/core/startup/app_startup_notifier.dart` — `AppStartupData`, `AppStartupNotifier extends AsyncNotifier<AppStartupData>`; читает SharedPreferences флаг + профиль
- `lib/app.dart` — оборачивает router в `ref.watch(appStartupProvider).when(...)` с `CircularProgressIndicator` пока загружается; после загрузки сидирует `selectedSubjectProvider` из профиля
- `lib/router/app_router.dart` — добавить `/onboarding` route (вне `StatefulShellRoute`); добавить `redirect` через `RouterNotifier` паттерн: не завершён → `/onboarding`, завершён + на `/onboarding` → `/schedule`

**Acceptance:** Первый запуск → `/onboarding`. Повторный запуск → `/schedule` с правильным субъектом.

---

### Phase 5 — Onboarding feature

**Directory structure:**
```
lib/features/onboarding/
└── presentation/
    ├── screens/onboarding_screen.dart      # PageView wizard root
    ├── providers/onboarding_provider.dart  # OnboardingNotifier (StateNotifier)
    └── widgets/
        ├── mode_selection_page.dart        # страница 0: Student / Teacher
        ├── group_picker_page.dart          # страница 1a: sectioned list + search
        ├── teacher_picker_page.dart        # страница 1b: flat list + search
        ├── subgroup_picker_page.dart       # страница 2: кнопки 1 / 2
        └── name_entry_page.dart            # страница 3: TextField + Skip
```

**Ключевые детали:**
- `OnboardingNotifier` хранит `OnboardingState { mode, selectedGroup, selectedSubgroup, displayName, selectedTeacher, isLoading, failure }`
- При переходе на шаг выбора группы/преподавателя → вызывает `groupsRepository.refreshGroups()` (или `teachersRepository.refreshTeachers()`); при `failure != null` и пустом кэше → shows error state
- Тёплый кэш (Drift не пустой) → список сразу доступен, refresh в фоне
- Группы отображаются в секционированном `ListView` (по `instituteName`); поиск фильтрует все секции
- Преподаватели — плоский `ListView` с поиском по имени
- Кнопка "Готово" → `prefs.setString('profile', ...)` затем `prefs.setBool('onboarding_complete', true)` затем `appStartupProvider.invalidate()`

**Files:**
- `lib/features/onboarding/presentation/screens/onboarding_screen.dart`
- `lib/features/onboarding/presentation/providers/onboarding_provider.dart`
- `lib/features/onboarding/presentation/widgets/mode_selection_page.dart`
- `lib/features/onboarding/presentation/widgets/group_picker_page.dart`
- `lib/features/onboarding/presentation/widgets/teacher_picker_page.dart`
- `lib/features/onboarding/presentation/widgets/subgroup_picker_page.dart`
- `lib/features/onboarding/presentation/widgets/name_entry_page.dart`

**Acceptance:** Пользователь проходит все шаги онбординга; после завершения попадает на расписание своей группы/преподавателя.

---

### Phase 6 — Profile screen

**Files:**
- `lib/features/profile/presentation/providers/profile_provider.dart` — `ProfileNotifier extends AsyncNotifier<Profile?>`; `build()` вызывает `GetProfile`; `save(profile)` вызывает `SaveProfile` + обновляет `selectedSubjectProvider`
- `lib/features/profile/presentation/screens/profile_screen.dart` — показывает текущий профиль; кнопка Edit открывает inline edit mode или модальный sheet (iOS-стиль); при смене режима — показывает соответствующий список (группы или преподаватели); Save обновляет профиль и закрывает edit mode

**UI структура:**
```
ProfileScreen
  ├── ProfileHeaderWidget    — имя (если студент), режим (иконка)
  ├── ProfileFieldTile "Режим"        — Student / Teacher, tappable
  ├── ProfileFieldTile "Группа"       — только студент, tappable
  ├── ProfileFieldTile "Подгруппа"    — только студент, tappable
  ├── ProfileFieldTile "Имя"          — только студент, editable text
  └── ProfileFieldTile "Преподаватель" — только teacher, tappable
```

**Acceptance:** Изменение группы в Profile → расписание обновляется. Смена режима → старые поля очищаются при Save.

---

## Deferred Questions Resolved

| Вопрос | Решение |
|---|---|
| Подгруппы из API или фиксированные? | Фиксированные [1, 2] |
| Эндпоинт преподавателей? | `GET /s/schedule/v1/schedule/actual_teachers` (уже в ApiClient) |
| Сброс полей при смене режима — немедленно или по Save? | По Save; локальный state редактора хранит оба набора |
| Форма Profile entity | Плоский struct с `ProfileMode mode` + nullable поля |
| Offline в онбординге: тёплый кэш проходит? | Да — тёплый кэш достаточен; Retry только при пустом Drift + нет сети |
| Порядок записи при завершении онбординга | Profile первый, флаг вторым |

## Sources & References

### Origin

- **Origin document:** [docs/brainstorms/2026-04-17-profile-onboarding-requirements.md](../brainstorms/2026-04-17-profile-onboarding-requirements.md)
  - Key decisions carried forward: dual-mode profile (student/teacher), SharedPreferences storage, blocking onboarding without network+cache, profile editable from Profile tab

### Internal References

- Schedule providers: `lib/features/schedule/presentation/providers/schedule_provider.dart:81` — hardcoded `'ЦИС-47'` → заменить
- Existing profile entity: `lib/features/profile/domain/entities/profile.dart` — redesign in Phase 1
- API endpoints: `docs/plans/2026-04-17-001-feat-ystu-api-client-offline-sync-plan.md` — groups/teachers endpoints
- GoRouter setup: `lib/router/app_router.dart` — add redirect + onboarding route
- Sealed error classes: `lib/core/errors/app_exception.dart`, `lib/core/errors/failure.dart` — follow same pattern for new failures
- AppLogger: `lib/core/logger.dart` — use in all new files

### Related Work

- Plan #001: `docs/plans/2026-04-17-001-feat-ystu-api-client-offline-sync-plan.md` — prerequisite (GroupsTable, TeachersTable, ApiClient)
