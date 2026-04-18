import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/onboarding_provider.dart';

class TeacherPickerPage extends ConsumerStatefulWidget {
  const TeacherPickerPage({super.key, required this.onTeacherSelected});

  final VoidCallback onTeacherSelected;

  @override
  ConsumerState<TeacherPickerPage> createState() => _TeacherPickerPageState();
}

class _TeacherPickerPageState extends ConsumerState<TeacherPickerPage> {
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

    if (state.isLoadingList && state.teachers.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (state.listFailure != null && state.teachers.isEmpty) {
      return _ErrorState(
        label3: label3,
        accent: accent,
        onRetry: () => ref.read(onboardingProvider.notifier).retryLoadList(),
      );
    }

    final filtered = state.teachers
        .where((t) =>
            _query.isEmpty ||
            t.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Выберите преподавателя',
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
              final teacher = filtered[i];
              final isSelected = state.selectedTeacherId == teacher.id;
              final isFirst = i == 0;
              final isLast = i == filtered.length - 1;
              return Column(
                children: [
                  if (!isFirst)
                    Container(
                      height: 0.5,
                      margin: const EdgeInsets.only(left: 16),
                      color: AppColors.resolve(
                        context,
                        AppColors.separatorLight,
                        AppColors.separatorDark,
                      ),
                    ),
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: isFirst
                          ? const Radius.circular(12)
                          : Radius.zero,
                      bottom: isLast
                          ? const Radius.circular(12)
                          : Radius.zero,
                    ),
                    child: ColoredBox(
                      color: surface,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          ref
                              .read(onboardingProvider.notifier)
                              .selectTeacher(teacher.id, teacher.name);
                          widget.onTeacherSelected();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  teacher.name,
                                  style: AppTextStyles.subjectName
                                      .copyWith(color: label),
                                ),
                              ),
                              if (isSelected)
                                Icon(CupertinoIcons.check_mark,
                                    color: accent, size: 18),
                            ],
                          ),
                        ),
                      ),
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
              'Не удалось загрузить список преподавателей.\nПроверьте подключение к сети.',
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
