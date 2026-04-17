import 'package:flutter/material.dart';
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
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
      return const Center(child: CircularProgressIndicator());
    }

    if (state.listFailure != null && state.groups.isEmpty) {
      return _ErrorState(
        label3: label3,
        accent: accent,
        onRetry: () => ref.read(onboardingProvider.notifier).retryLoadList(),
      );
    }

    // Filter groups by search query
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
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Поиск...',
              hintStyle: AppTextStyles.meta.copyWith(color: label3),
              prefixIcon: Icon(Icons.search_rounded, color: label3, size: 20),
              filled: true,
              fillColor: surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
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
                      style: AppTextStyles.sectionHeader.copyWith(color: label3),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        for (int j = 0; j < institute.groups.length; j++) ...[
                          if (j > 0)
                            Divider(
                              height: 1,
                              color: AppColors.resolve(
                                context,
                                AppColors.separatorLight,
                                AppColors.separatorDark,
                              ),
                              indent: 16,
                            ),
                          ListTile(
                            title: Text(
                              institute.groups[j],
                              style:
                                  AppTextStyles.subjectName.copyWith(color: label),
                            ),
                            trailing: state.selectedGroupName ==
                                    institute.groups[j]
                                ? Icon(Icons.check_rounded,
                                    color: accent, size: 20)
                                : null,
                            onTap: () {
                              ref
                                  .read(onboardingProvider.notifier)
                                  .selectGroup(institute.groups[j]);
                              widget.onGroupSelected();
                            },
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
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: accent),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}
