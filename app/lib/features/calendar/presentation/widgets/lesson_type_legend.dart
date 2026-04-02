import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../schedule/domain/entities/lesson_type.dart';

/// A compact horizontal row showing the color-to-lesson-type mapping.
///
/// Displays all four [LessonType] values with their corresponding dot colors
/// and short labels, so users can interpret calendar day-cell dots at a glance.
class LessonTypeLegend extends StatelessWidget {
  const LessonTypeLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final Color label3 = AppColors.resolve(
      context,
      AppColors.label3Light,
      AppColors.label3Dark,
    );
    final Color surface = AppColors.resolve(
      context,
      AppColors.surfaceLight,
      AppColors.surfaceDark,
    );
    final Color separator = AppColors.resolve(
      context,
      AppColors.separatorLight,
      AppColors.separatorDark,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: surface,
        border: Border(
          top: BorderSide(color: separator),
          bottom: BorderSide(color: separator),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: LessonType.values.map((type) {
          return _LegendItem(type: type, labelColor: label3);
        }).toList(),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.type, required this.labelColor});

  final LessonType type;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    final Color dotColor = AppColors.lessonTypeColor(context, type);
    final String label = switch (type) {
      LessonType.lecture => 'Лекция',
      LessonType.practice => 'Практика',
      LessonType.lab => 'Лаборат.',
      LessonType.other => 'Другое',
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.meta.copyWith(color: labelColor)),
      ],
    );
  }
}
