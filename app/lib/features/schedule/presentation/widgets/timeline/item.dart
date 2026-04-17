import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/lesson.dart';
import '../../../domain/entities/lesson_type.dart';
import 'lesson_card/lesson_card.dart';

/// A single row in the schedule timeline.
///
/// Renders a time column (start + end) on the left and a [LessonCard] on the right.
///
/// ```
/// 09:50  ┃  [LessonCard]
/// 11:25  ┃
/// ```
class TimelineItem extends StatelessWidget {
  const TimelineItem({super.key, required this.lesson});

  final Lesson lesson;

  @Preview(group: 'schedule', name: 'TimelineItem – lecture')
  static Widget previewLecture() {
    final now = DateTime.now();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TimelineItem(
        lesson: Lesson(
          groupId: '',
          subject: 'Математический анализ',
          teacher: 'Иванов А.В.',
          room: '301',
          type: LessonType.lecture,
          startTime: DateTime(now.year, now.month, now.day, 8, 0),
          endTime: DateTime(now.year, now.month, now.day, 9, 35),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Time column ──────────────────────────────────────────────────
        SizedBox(
          width: 48,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmt(lesson.startTime),
                style: AppTextStyles.timeStart.copyWith(color: label2),
              ),
              const SizedBox(height: 3),
              Text(
                _fmt(lesson.endTime),
                style: AppTextStyles.timeEnd.copyWith(color: label3),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // ── Lesson card ──────────────────────────────────────────────────
        Expanded(child: LessonCard(lesson: lesson)),
      ],
    );
  }

  static String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
