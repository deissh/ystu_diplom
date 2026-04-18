import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';

/// A horizontal red line with a bullet dot that marks the current time on the
/// schedule timeline.
///
/// Positioned in the lesson list by [buildScheduleItems] — appears before the
/// first lesson that has not yet ended (i.e., between the last completed lesson
/// and the active / next upcoming one).
///
/// ```
/// ●──────────────────────────────────── 14:30
/// ```
class CurrentTimeIndicator extends StatelessWidget {
  const CurrentTimeIndicator({super.key, required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final Color red =
        AppColors.resolve(context, AppColors.redLight, AppColors.redDark);

    final String timeLabel =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // ── Dot ───────────────────────────────────────────────────────────
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: red, shape: BoxShape.circle),
          ),
          // ── Line ──────────────────────────────────────────────────────────
          Expanded(
            child: Container(height: 1.5, color: red),
          ),
          const SizedBox(width: 6),
          // ── Time label ────────────────────────────────────────────────────
          Text(
            timeLabel,
            style: AppTextStyles.timeStart.copyWith(color: red),
          ),
        ],
      ),
    );
  }
}
