import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/app_settings.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsNotifierProvider);

    final Color bg =
        AppColors.resolve(context, AppColors.bgLight, AppColors.bgDark);
    final Color surface =
        AppColors.resolve(context, AppColors.surfaceLight, AppColors.surfaceDark);
    final Color label =
        AppColors.resolve(context, AppColors.labelLight, AppColors.labelDark);
    final Color label2 =
        AppColors.resolve(context, AppColors.label2Light, AppColors.label2Dark);
    final Color separator =
        AppColors.resolve(context, AppColors.separatorLight, AppColors.separatorDark);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: settingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(
              'Ошибка загрузки настроек',
              style: AppTextStyles.meta.copyWith(color: label),
            ),
          ),
          data: (settings) => _SettingsContent(
            settings: settings,
            bg: AppColors.resolve(context, AppColors.bgLight, AppColors.bgDark),
            surface: surface,
            label: label,
            label2: label2,
            separator: separator,
          ),
        ),
      ),
    );
  }
}

class _SettingsContent extends ConsumerStatefulWidget {
  const _SettingsContent({
    required this.settings,
    required this.bg,
    required this.surface,
    required this.label,
    required this.label2,
    required this.separator,
  });

  final AppSettings settings;
  final Color bg;
  final Color surface;
  final Color label;
  final Color label2;
  final Color separator;

  @override
  ConsumerState<_SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends ConsumerState<_SettingsContent> {
  bool _isResetting = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      children: [
        // ── Заголовок ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Text(
            'Настройки',
            style: AppTextStyles.screenTitle.copyWith(color: widget.label),
          ),
        ),

        // ── Секция: Тема ───────────────────────────────────────────────────
        _SectionHeader(label: 'Внешний вид', labelColor: widget.label2),
        const SizedBox(height: 8),
        _SettingsCard(
          surface: widget.surface,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Тема оформления',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: widget.label,
                  ),
                ),
                const SizedBox(height: 12),
                _ThemeSegmentedButton(
                  selected: widget.settings.theme,
                  onChanged: (theme) {
                    ref.read(settingsNotifierProvider.notifier).setTheme(theme);
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),

        // ── Секция: Данные ─────────────────────────────────────────────────
        _SectionHeader(label: 'Данные', labelColor: widget.label2),
        const SizedBox(height: 8),
        _SettingsCard(
          surface: widget.surface,
          child: _ResetButton(
            isLoading: _isResetting,
            separator: widget.separator,
            onTap: _confirmReset,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmReset() async {
    // Захватываем до первого await
    final messenger = ScaffoldMessenger.of(context);
    final redColor = AppColors.resolve(
      context,
      AppColors.redLight,
      AppColors.redDark,
    );

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Сбросить данные?'),
        content: const Text(
          'Все данные профиля и кэш расписания будут удалены. '
          'Отменить действие невозможно.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: redColor),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _isResetting = true);
    try {
      await ref.read(settingsNotifierProvider.notifier).resetAllData();
    } catch (e, st) {
      AppLogger.error('SettingsScreen._confirmReset: $e\n$st');
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Не удалось сбросить данные. Попробуйте снова.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isResetting = false);
    }
  }
}

// ── Вспомогательные виджеты ───────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.labelColor});

  final String label;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.meta.copyWith(color: labelColor, fontSize: 12),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.surface, required this.child});

  final Color surface;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _ThemeSegmentedButton extends StatelessWidget {
  const _ThemeSegmentedButton({
    required this.selected,
    required this.onChanged,
  });

  final AppTheme selected;
  final ValueChanged<AppTheme> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<AppTheme>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: AppTheme.system,
          label: Text('Системная'),
          icon: Icon(Icons.brightness_auto_outlined),
        ),
        ButtonSegment(
          value: AppTheme.light,
          label: Text('Светлая'),
          icon: Icon(Icons.light_mode_outlined),
        ),
        ButtonSegment(
          value: AppTheme.dark,
          label: Text('Тёмная'),
          icon: Icon(Icons.dark_mode_outlined),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (set) {
        if (set.isNotEmpty) onChanged(set.first);
      },
    );
  }
}

class _ResetButton extends StatelessWidget {
  const _ResetButton({
    required this.isLoading,
    required this.separator,
    required this.onTap,
  });

  final bool isLoading;
  final Color separator;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color red = AppColors.resolve(
      context,
      AppColors.redLight,
      AppColors.redDark,
    );

    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Сбросить данные и настройки',
                style: TextStyle(
                  color: isLoading ? red.withValues(alpha: 0.4) : red,
                  fontSize: 16,
                ),
              ),
            ),
            if (isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: red.withValues(alpha: 0.4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
