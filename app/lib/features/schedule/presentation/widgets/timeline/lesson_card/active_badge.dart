import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';

/// Animated badge shown when a lesson is currently in progress.
///
/// Displays a pulsing green dot followed by the label "Сейчас идёт".
/// Uses the same animation pattern as `_PulsingDot` in `sync_status_bar.dart`.
class ActiveBadge extends StatefulWidget {
  const ActiveBadge({super.key});

  @override
  State<ActiveBadge> createState() => _ActiveBadgeState();
}

class _ActiveBadgeState extends State<ActiveBadge>
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

    _opacity = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color green =
        AppColors.resolve(context, AppColors.greenLight, AppColors.greenDark);
    final Color accent =
        AppColors.resolve(context, AppColors.accentLight, AppColors.accentDark);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, _) => Opacity(
            opacity: _opacity.value,
            child: Transform.scale(
              scale: _scale.value,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: green,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          'Сейчас идёт',
          style: AppTextStyles.activeBadge.copyWith(color: accent),
        ),
      ],
    );
  }
}
