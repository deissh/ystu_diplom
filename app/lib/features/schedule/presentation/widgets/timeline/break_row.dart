import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';

/// A horizontal row displaying the break duration between two lessons.
///
/// Renders: ──────── Перерыв N мин ────────
class BreakRow extends StatelessWidget {
  const BreakRow({super.key, required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    final Color separator =
        AppColors.resolve(context, AppColors.separatorLight, AppColors.separatorDark);
    final Color label3 =
        AppColors.resolve(context, AppColors.label3Light, AppColors.label3Dark);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: separator, thickness: 0.5, endIndent: 0),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Перерыв $minutes мин',
              style: AppTextStyles.breakLabel.copyWith(color: label3),
            ),
          ),
          Expanded(
            child: Divider(color: separator, thickness: 0.5, indent: 0),
          ),
        ],
      ),
    );
  }
}
