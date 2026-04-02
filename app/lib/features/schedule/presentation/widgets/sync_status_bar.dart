import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/schedule_provider.dart';

/// Fixed status bar showing data freshness and network connectivity.
///
/// Three states derived from [scheduleProvider]:
///   • [AsyncData]    → green "Данные актуальны"
///   • [AsyncLoading] → accent "Синхронизация..."
///   • [AsyncError]   → orange "Нет подключения · данные из кэша"
class SyncStatusBar extends ConsumerWidget {
  const SyncStatusBar({super.key});

  @Preview(group: 'schedule', name: 'SyncStatusBar')
  static Widget preview() {
    return ProviderScope(child: SyncStatusBar());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(scheduleProvider);
    final now = ref.watch(nowProvider).valueOrNull ?? DateTime.now();

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final (
      Color dotColor,
      String label,
      bool isLoading,
    ) = switch (scheduleAsync) {
      AsyncData() => (
        isDark ? AppColors.greenDark : AppColors.greenLight,
        'Данные актуальны',
        false,
      ),
      AsyncLoading() => (
        isDark ? AppColors.accentDark : AppColors.accentLight,
        'Синхронизация...',
        true,
      ),
      AsyncError() => (
        isDark ? AppColors.orangeDark : AppColors.orangeLight,
        'Нет подключения · данные из кэша',
        false,
      ),
      _ => (
        isDark ? AppColors.greenDark : AppColors.greenLight,
        'Данные актуальны',
        false,
      ),
    };

    final Color surface = AppColors.resolve(
      context,
      AppColors.surfaceLight,
      AppColors.surfaceDark,
    );
    final Color label2 = AppColors.resolve(
      context,
      AppColors.label2Light,
      AppColors.label2Dark,
    );
    final Color label3 = AppColors.resolve(
      context,
      AppColors.label3Light,
      AppColors.label3Dark,
    );
    final Color surface3 = AppColors.resolve(
      context,
      AppColors.surface3Light,
      AppColors.surface3Dark,
    );
    final Color accent = AppColors.resolve(
      context,
      AppColors.accentLight,
      AppColors.accentDark,
    );

    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.cardShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── First row: dot + label + time ─────────────────────────────
          Row(
            children: [
              _PulsingDot(color: dotColor, isLoading: isLoading),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.syncStatus.copyWith(color: label2),
                ),
              ),
              Text(
                timeStr,
                style: AppTextStyles.syncTime.copyWith(color: label3),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // ── Second row: chips ─────────────────────────────────────────
          Row(
            children: [
              _StatusChip(
                icon: Icons.cloud_done_outlined,
                label: 'Сервер синхронизирован',
                backgroundColor: surface3,
                textColor: label3,
                iconColor: accent,
              ),
              const SizedBox(width: 6),
              _StatusChip(
                icon: Icons.phone_android_outlined,
                label: 'Сохранено на устройстве',
                backgroundColor: surface3,
                textColor: label3,
                iconColor: accent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Pulsing dot ─────────────────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color, required this.isLoading});

  final Color color;
  final bool isLoading;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _opacity = Tween<double>(
      begin: 1.0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Opacity(
        opacity: _opacity.value,
        child: Transform.scale(
          scale: _scale.value,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Status chip ──────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.syncChip.copyWith(color: textColor)),
        ],
      ),
    );
  }
}
