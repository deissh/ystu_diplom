import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../profile/domain/entities/profile.dart';
import '../providers/onboarding_provider.dart';

class ModeSelectionPage extends ConsumerWidget {
  const ModeSelectionPage({super.key, required this.onModeSelected});

  final VoidCallback onModeSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color accent = AppColors.resolve(
        context, AppColors.accentLight, AppColors.accentDark);
    final Color label = AppColors.resolve(
        context, AppColors.labelLight, AppColors.labelDark);
    final Color label3 = AppColors.resolve(
        context, AppColors.label3Light, AppColors.label3Dark);
    final Color surface = AppColors.resolve(
        context, AppColors.surfaceLight, AppColors.surfaceDark);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 2),
          Icon(CupertinoIcons.book_solid, size: 64, color: accent),
          const SizedBox(height: 24),
          Text(
            'Добро пожаловать',
            style: AppTextStyles.screenTitle.copyWith(color: label),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите, чьё расписание вы хотите смотреть',
            style: AppTextStyles.meta.copyWith(color: label3),
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 2),
          _ModeCard(
            icon: CupertinoIcons.person_2,
            title: 'Студент',
            subtitle: 'Расписание по группе',
            color: accent,
            surface: surface,
            label: label,
            label3: label3,
            onTap: () async {
              await ref
                  .read(onboardingProvider.notifier)
                  .selectMode(ProfileMode.student);
              onModeSelected();
            },
          ),
          const SizedBox(height: 12),
          _ModeCard(
            icon: CupertinoIcons.person,
            title: 'Преподаватель',
            subtitle: 'Расписание по преподавателю',
            color: accent,
            surface: surface,
            label: label,
            label3: label3,
            onTap: () async {
              await ref
                  .read(onboardingProvider.notifier)
                  .selectMode(ProfileMode.teacher);
              onModeSelected();
            },
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.surface,
    required this.label,
    required this.label3,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color surface;
  final Color label;
  final Color label3;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        CupertinoTheme.brightnessOf(context) == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow(isDark),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                          AppTextStyles.subjectName.copyWith(color: label)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTextStyles.meta.copyWith(color: label3)),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right, color: label3, size: 20),
          ],
        ),
      ),
    );
  }
}
