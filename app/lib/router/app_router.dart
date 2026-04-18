import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, MaterialType, Scaffold, Theme;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../features/calendar/presentation/screens/calendar_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/schedule/presentation/screens/schedule_screen.dart';
import 'router_notifier.dart';

// Navigator keys — top-level to avoid recreation.
// GoRouter v14: navigatorKey is required for each StatefulShellBranch.
final _rootNavKey = GlobalKey<NavigatorState>();
final _scheduleNavKey = GlobalKey<NavigatorState>(debugLabel: 'schedule');
final _calendarNavKey = GlobalKey<NavigatorState>(debugLabel: 'calendar');
final _profileNavKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

/// Height of the iOS-style custom tab bar (matches CupertinoTabBar).
const double _kTabBarHeight = 49.0;

/// GoRouter провайдер с redirect guard для онбординга.
///
/// Использует [RouterNotifier] как [refreshListenable] — GoRouter
/// повторно вычисляет redirect при каждом изменении startup state.
final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  final router = GoRouter(
    navigatorKey: _rootNavKey,
    initialLocation: '/schedule',
    refreshListenable: notifier,
    redirect: (context, state) {
      final done = notifier.onboardingComplete;
      final onOnboarding = state.matchedLocation == '/onboarding';
      if (!done && !onOnboarding) return '/onboarding';
      if (done && onOnboarding) return '/schedule';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => CupertinoPage(
          key: state.pageKey,
          // Wrap in Theme+Material so Material widgets inside
          // OnboardingScreen have the correct ancestors under CupertinoApp.
          child: Theme(
            data: AppThemeData.light(),
            child: Material(
              color: AppColors.bgLight,
              child: const OnboardingScreen(),
            ),
          ),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _ScaffoldWithNavBar(shell: shell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _scheduleNavKey,
            routes: [
              GoRoute(
                path: '/schedule',
                pageBuilder: (context, state) => CupertinoPage(
                  key: state.pageKey,
                  child: const ScheduleScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _calendarNavKey,
            routes: [
              GoRoute(
                path: '/calendar',
                pageBuilder: (context, state) => CupertinoPage(
                  key: state.pageKey,
                  child: const CalendarScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _profileNavKey,
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) => CupertinoPage(
                  key: state.pageKey,
                  child: const ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});

/// Shell scaffold wrapping the three tab branches.
///
/// Uses a [Material] ancestor (transparency type) so that [Scaffold] — which
/// requires a Material ancestor — works correctly under [CupertinoApp].
class _ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell shell;

  const _ScaffoldWithNavBar({required this.shell});

  @override
  Widget build(BuildContext context) {
    // Material(transparency) provides the required Material ancestor for
    // Scaffold without adding any visual background of its own.
    return Material(
      type: MaterialType.transparency,
      child: Scaffold(
        // extendBody lets the body render behind the frosted tab bar so
        // BackdropFilter in _IosTabBar can blur the content below.
        extendBody: true,
        body: shell,
        bottomNavigationBar: _IosTabBar(
          currentIndex: shell.currentIndex,
          onTap: (i) => shell.goBranch(
            i,
            initialLocation: i == shell.currentIndex,
          ),
        ),
      ),
    );
  }
}

/// iOS-style frosted-glass tab bar with Cupertino icons.
///
/// Uses [BackdropFilter] with [extendBody] on the parent [Scaffold] to achieve
/// a translucent blur effect. The bar uses a custom [_CupertinoTabRow] instead
/// of [BottomNavigationBar] for a native iOS appearance.
class _IosTabBar extends StatelessWidget {
  const _IosTabBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    final Color surface = AppColors.resolve(
      context,
      AppColors.surfaceLight,
      AppColors.surfaceDark,
    );
    final Color separator = AppColors.resolve(
      context,
      AppColors.separatorLight,
      AppColors.separatorDark,
    );

    // Semi-transparent surface: 85% in light, 90% in dark
    final Color barBg = surface.withValues(alpha: isDark ? 0.9 : 0.85);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: barBg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hairline top separator — mimics iOS tab bar border
              Container(height: 0.5, color: separator),
              _CupertinoTabRow(
                currentIndex: currentIndex,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cupertino-style tab row with three items.
class _CupertinoTabRow extends StatelessWidget {
  const _CupertinoTabRow({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (icon: CupertinoIcons.calendar, label: 'Расписание'),
    (icon: CupertinoIcons.calendar_badge_plus, label: 'Календарь'),
    (icon: CupertinoIcons.person, label: 'Профиль'),
  ];

  @override
  Widget build(BuildContext context) {
    final Color accent = AppColors.resolve(
      context,
      AppColors.accentLight,
      AppColors.accentDark,
    );
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPad),
      child: SizedBox(
        height: _kTabBarHeight,
        child: Row(
          children: List.generate(_items.length, (i) {
            final item = _items[i];
            final isActive = i == currentIndex;
            final color = isActive ? accent : AppColors.iconInactive;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, color: color, size: 22),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
