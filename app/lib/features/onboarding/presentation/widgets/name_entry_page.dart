import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/onboarding_provider.dart';

class NameEntryPage extends ConsumerStatefulWidget {
  const NameEntryPage({
    super.key,
    required this.onFinish,
  });

  final VoidCallback onFinish;

  @override
  ConsumerState<NameEntryPage> createState() => _NameEntryPageState();
}

class _NameEntryPageState extends ConsumerState<NameEntryPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 2),
          Text(
            'Ваше имя',
            style: AppTextStyles.screenTitle.copyWith(color: label),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Необязательно — поможет персонализировать интерфейс',
            style: AppTextStyles.meta.copyWith(color: label3),
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 2),
          TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.words,
            style: AppTextStyles.subjectName.copyWith(color: label),
            decoration: InputDecoration(
              hintText: 'Имя Фамилия',
              hintStyle: AppTextStyles.meta.copyWith(color: label3),
              filled: true,
              fillColor: surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) =>
                ref.read(onboardingProvider.notifier).setDisplayName(v),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: state.isSaving
                ? null
                : () {
                    widget.onFinish();
                  },
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: state.isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Готово'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: state.isSaving ? null : widget.onFinish,
            child: Text(
              'Пропустить',
              style: AppTextStyles.meta.copyWith(color: label3),
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
