import 'package:flutter/material.dart';
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

    if (state.isLoadingList && state.teachers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
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
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: filtered.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: AppColors.resolve(
                context,
                AppColors.separatorLight,
                AppColors.separatorDark,
              ),
              indent: 16,
            ),
            itemBuilder: (context, i) {
              final teacher = filtered[i];
              final isSelected = state.selectedTeacherId == teacher.id;
              return ListTile(
                tileColor: surface,
                shape: i == 0
                    ? const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(12)))
                    : i == filtered.length - 1
                        ? const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(12)))
                        : null,
                title: Text(
                  teacher.name,
                  style: AppTextStyles.subjectName.copyWith(color: label),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_rounded, color: accent, size: 20)
                    : null,
                onTap: () {
                  ref
                      .read(onboardingProvider.notifier)
                      .selectTeacher(teacher.id, teacher.name);
                  widget.onTeacherSelected();
                },
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
