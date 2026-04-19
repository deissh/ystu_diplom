import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../../../../core/layout/app_layout.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/lesson.dart';
import '../../../domain/entities/lesson_type.dart';
import 'lesson_card/lesson_card.dart';

/// A single row in the schedule timeline.
///
/// Renders a [LessonCard] constrained to [AppLayout.maxContent] on wide
/// screens (≥ 600 dp). On narrow screens the card fills the available width.
/// The outer [ListView] in the schedule screen already applies horizontal
/// padding via [AppLayout.hPad] — no additional padding is added here.
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
          startTime: DateTime(now.year, now.month, now.day, 9, 50),
          endTime: DateTime(now.year, now.month, now.day, 11, 25),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppLayout.maxContent(context),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TimeColumn(lesson: lesson),
              const SizedBox(width: 8),
              Expanded(child: LessonCard(lesson: lesson)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Time column ───────────────────────────────────────────────────────────────

class _TimeColumn extends StatelessWidget {
  const _TimeColumn({required this.lesson});

  final Lesson lesson;

  static String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

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

    return SizedBox(
      width: 52,
      child: Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _fmt(lesson.startTime),
              style: AppTextStyles.timeStart.copyWith(color: label2),
            ),
            const SizedBox(height: 2),
            Text(
              _fmt(lesson.endTime),
              style: AppTextStyles.timeEnd.copyWith(color: label3),
            ),
          ],
        ),
      ),
    );
  }
}
