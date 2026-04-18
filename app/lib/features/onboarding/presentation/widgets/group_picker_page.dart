import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/onboarding_provider.dart';

class GroupPickerPage extends ConsumerStatefulWidget {
  const GroupPickerPage({super.key, required this.onGroupSelected});

  final VoidCallback onGroupSelected;

  @override
  ConsumerState<GroupPickerPage> createState() => _GroupPickerPageState();
}

class _GroupPickerPageState extends ConsumerState<GroupPickerPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);

    final Color accent =
        AppColors.resolve(context, AppColors.accentLight, AppColors.accentDark);
    final Color label =
        AppColors.resolve(context, AppColors.labelLight, AppColors.labelDark);
    final Color label3 = AppColors.resolve(
        context, AppColors.label3Light, AppColors.label3Dark);
    final Color surface = AppColors.resolve(
        context, AppColors.surfaceLight, AppColors.surfaceDark);

    if (state.isLoadingList && state.groups.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (state.listFailure != null && state.groups.isEmpty) {
      return _ErrorState(
        label3: label3,
        accent: accent,
        onRetry: () => ref.read(onboardingProvider.notifier).retryLoadList(),
      );
    }

    final filtered = state.groups
        .map((institute) => (
              instituteName: institute.instituteName,
              groups: institute.groups
                  .where((g) =>
                      _query.isEmpty ||
                      g.toLowerCase().contains(_query.toLowerCase()))
                  .toList(),
            ))
        .where((i) => i.groups.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Выберите группу',
            style: AppTextStyles.screenTitle.copyWith(color: label),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CupertinoSearchTextField(
            onChanged: (v) => setState(() => _query = v),
            placeholder: 'Поиск...',
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final institute = filtered[i];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Text(
                      institute.instituteName.toUpperCase(),
                      style: AppTextStyles.sectionHeader
                          .copyWith(color: label3),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        for (int j = 0;
                            j < institute.groups.length;
                            j++) ...[
                          if (j > 0)
                            Container(
                              height: 0.5,
                              margin: const EdgeInsets.only(left: 16),
                              color: AppColors.resolve(
                                context,
                                AppColors.separatorLight,
                                AppColors.separatorDark,
                              ),
                            ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              ref
                                  .read(onboardingProvider.notifier)
                                  .selectGroup(institute.groups[j]);
                              widget.onGroupSelected();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      institute.groups[j],
                                      style: AppTextStyles.subjectName
                                          .copyWith(color: label),
                                    ),
                                  ),
                                  if (state.selectedGroupName ==
                                      institute.groups[j])
                                    Icon(CupertinoIcons.check_mark,
                                        color: accent, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.label3,
    required this.accent,
    required this.onRetry,
  });

  final Color label3;
  final Color accent;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Не удалось загрузить список групп.\nПроверьте подключение к сети.',
              style: AppTextStyles.meta.copyWith(color: label3),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              onPressed: onRetry,
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}
