import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';

/// Gradient progress bar for an active lesson.
///
/// Shows how much time has elapsed and how much remains.
/// Progress is computed from [startTime] and [endTime] relative to [DateTime.now()].
class LessonProgressBar extends StatelessWidget {
  const LessonProgressBar({
    super.key,
    required this.startTime,
    required this.endTime,
  });

  final DateTime startTime;
  final DateTime endTime;

  @override
  Widget build(BuildContext context) {
    final Color accent =
        AppColors.resolve(context, AppColors.accentLight, AppColors.accentDark);
    final Color teal =
        AppColors.resolve(context, AppColors.tealLight, AppColors.tealDark);
    final Color surface3 =
        AppColors.resolve(context, AppColors.surface3Light, AppColors.surface3Dark);
    final Color label3 =
        AppColors.resolve(context, AppColors.label3Light, AppColors.label3Dark);

    final now = DateTime.now();
    final totalSec = endTime.difference(startTime).inSeconds;
    final elapsedSec =
        now.difference(startTime).inSeconds.clamp(0, totalSec);
    final progress = totalSec > 0 ? elapsedSec / totalSec : 0.0;
    final elapsedMin = (elapsedSec / 60).round();
    final remainingMin = ((totalSec - elapsedSec) / 60).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Track ─────────────────────────────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Container(
            height: 4,
            color: surface3,
            child: FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              alignment: Alignment.centerLeft,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [accent, teal]),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        // ── Labels ────────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Прошло $elapsedMin мин',
              style: AppTextStyles.progressLabel.copyWith(color: label3),
            ),
            Text(
              'Осталось $remainingMin мин',
              style: AppTextStyles.progressLabel.copyWith(color: label3),
            ),
          ],
        ),
      ],
    );
  }
}
