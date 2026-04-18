import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/onboarding_provider.dart';

class SubgroupPickerPage extends ConsumerWidget {
  const SubgroupPickerPage({super.key, required this.onSubgroupSelected});

  final VoidCallback onSubgroupSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);

    final Color accent =
        AppColors.resolve(context, AppColors.accentLight, AppColors.accentDark);
    final Color label =
        AppColors.resolve(context, AppColors.labelLight, AppColors.labelDark);
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
          Text(
            'Подгруппа',
            style: AppTextStyles.screenTitle.copyWith(color: label),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (state.selectedGroupName != null)
            Text(
              state.selectedGroupName!,
              style: AppTextStyles.meta.copyWith(color: label3),
              textAlign: TextAlign.center,
            ),
          const Spacer(flex: 2),
          Row(
            children: [
              Expanded(
                child: _SubgroupButton(
                  number: 1,
                  isSelected: state.selectedSubgroup == 1,
                  accent: accent,
                  label: label,
                  surface: surface,
                  onTap: () {
                    ref.read(onboardingProvider.notifier).selectSubgroup(1);
                    onSubgroupSelected();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SubgroupButton(
                  number: 2,
                  isSelected: state.selectedSubgroup == 2,
                  accent: accent,
                  label: label,
                  surface: surface,
                  onTap: () {
                    ref.read(onboardingProvider.notifier).selectSubgroup(2);
                    onSubgroupSelected();
                  },
                ),
              ),
            ],
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

class _SubgroupButton extends StatelessWidget {
  const _SubgroupButton({
    required this.number,
    required this.isSelected,
    required this.accent,
    required this.label,
    required this.surface,
    required this.onTap,
  });

  final int number;
  final bool isSelected;
  final Color accent;
  final Color label;
  final Color surface;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        CupertinoTheme.brightnessOf(context) == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 80,
        decoration: BoxDecoration(
          color: isSelected ? accent : surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow(isDark),
        ),
        child: Center(
          child: Text(
            '$number',
            style: AppTextStyles.statValue.copyWith(
              color: isSelected ? CupertinoColors.white : label,
            ),
          ),
        ),
      ),
    );
  }
}
