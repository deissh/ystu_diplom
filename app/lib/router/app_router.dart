import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../features/calendar/presentation/screens/calendar_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/schedule/presentation/screens/schedule_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import 'router_notifier.dart';

// Navigator keys — top-level to avoid recreation.
// GoRouter v14: navigatorKey is required for each StatefulShellBranch.
final _rootNavKey = GlobalKey<NavigatorState>();
final _scheduleNavKey = GlobalKey<NavigatorState>(debugLabel: 'schedule');
final _calendarNavKey = GlobalKey<NavigatorState>(debugLabel: 'calendar');
final _profileNavKey = GlobalKey<NavigatorState>(debugLabel: 'profile');
final _settingsNavKey = GlobalKey<NavigatorState>(debugLabel: 'settings');

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
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _ScaffoldWithNavBar(shell: shell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _scheduleNavKey,
            routes: [
              GoRoute(
                path: '/schedule',
                builder: (context, state) => const ScheduleScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _calendarNavKey,
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (context, state) => const CalendarScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _profileNavKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _settingsNavKey,
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
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

class _ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell shell;

  const _ScaffoldWithNavBar({required this.shell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // extendBody: true lets the body render behind the bottom bar so
      // BackdropFilter in _IosTabBar can see and blur the content below.
      extendBody: true,
      body: shell,
      bottomNavigationBar: _IosTabBar(
        currentIndex: shell.currentIndex,
        onTap: (i) => shell.goBranch(
          i,
          initialLocation: i == shell.currentIndex,
        ),
      ),
    );
  }
}

/// iOS-style frosted-glass tab bar.
///
/// Uses [BackdropFilter] with [extendBody] on the parent [Scaffold] to achieve
/// a translucent blur effect. The bar is composed of:
///   - A hairline top separator (0.5 dp)
///   - A [BackdropFilter] blur layer (sigma 20)
///   - A semi-transparent surface container (85% opacity)
///   - A standard [BottomNavigationBar] with no elevation and iOS colours
class _IosTabBar extends StatelessWidget {
  const _IosTabBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

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
    final Color accent = AppColors.resolve(
      context,
      AppColors.accentLight,
      AppColors.accentDark,
    );

    // Semi-transparent surface: 85% in light, 90% in dark (dark needs less blur)
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
              BottomNavigationBar(
                currentIndex: currentIndex,
                onTap: onTap,
                elevation: 0,
                backgroundColor: Colors.transparent,
                selectedItemColor: accent,
                unselectedItemColor: AppColors.iconInactive,
                // Remove default selected item indicator animation
                type: BottomNavigationBarType.fixed,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_today),
                    label: 'Расписание',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_month),
                    label: 'Календарь',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: 'Профиль',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings_outlined),
                    label: 'Настройки',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
