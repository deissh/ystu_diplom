import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/startup/app_startup_notifier.dart';
import 'core/theme/app_theme.dart';
import 'features/profile/domain/entities/profile.dart';
import 'features/schedule/domain/entities/selected_subject.dart';
import 'features/schedule/presentation/providers/schedule_provider.dart';
import 'features/settings/domain/entities/app_settings.dart';
import 'features/settings/presentation/providers/settings_provider.dart';
import 'router/app_router.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startupAsync = ref.watch(appStartupProvider);

    return startupAsync.when(
      loading: () => const _SplashScreen(),
      error: (e, _) => const _SplashScreen(),
      data: (startup) {
        if (startup.profile != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final subject = _subjectFromProfile(startup.profile!);
            ref.read(selectedSubjectProvider.notifier).state = subject;
          });
        }

        final brightness = ref
                .watch(settingsNotifierProvider)
                .valueOrNull
                ?.theme
                .toBrightness();

        return CupertinoApp.router(
          title: AppConstants.appName,
          theme: AppCupertinoTheme.build(brightness),
          routerConfig: ref.watch(appRouterProvider),
        );
      },
    );
  }

  SelectedSubject? _subjectFromProfile(Profile profile) {
    return switch (profile.mode) {
      ProfileMode.student => profile.groupName != null
          ? GroupSubject(profile.groupName!)
          : null,
      ProfileMode.teacher =>
        profile.teacherId != null && profile.teacherName != null
            ? TeacherSubject(profile.teacherId!, profile.teacherName!)
            : null,
    };
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      home: CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      ),
    );
  }
}
