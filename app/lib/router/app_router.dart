import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/calendar/presentation/screens/calendar_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/schedule/presentation/screens/schedule_screen.dart';

// Navigator keys — top-level to avoid recreation.
// GoRouter v14: navigatorKey is required for each StatefulShellBranch.
final _rootNavKey = GlobalKey<NavigatorState>();
final _scheduleNavKey = GlobalKey<NavigatorState>(debugLabel: 'schedule');
final _calendarNavKey = GlobalKey<NavigatorState>(debugLabel: 'calendar');
final _profileNavKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

final appRouter = GoRouter(
  navigatorKey: _rootNavKey,
  initialLocation: '/schedule',
  routes: [
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
      ],
    ),
  ],
);

class _ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell shell;

  const _ScaffoldWithNavBar({required this.shell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: shell.currentIndex,
        onTap: (i) => shell.goBranch(
          i,
          // Tapping the active tab navigates back to the branch root.
          initialLocation: i == shell.currentIndex,
        ),
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
        ],
      ),
    );
  }
}
