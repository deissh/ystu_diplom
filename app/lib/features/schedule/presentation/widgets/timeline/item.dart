import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../../../../core/layout/app_layout.dart';
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
        child: LessonCard(lesson: lesson),
      ),
    );
  }
}
