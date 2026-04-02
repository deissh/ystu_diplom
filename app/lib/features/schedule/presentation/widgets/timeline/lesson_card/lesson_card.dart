import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../domain/entities/lesson.dart';
import '../../../../domain/entities/lesson_type.dart';
import '../../../providers/schedule_provider.dart';
import 'active_badge.dart';
import 'lesson_progress_bar.dart';
import 'teacher_chip.dart';

/// A card displaying a single lesson.
///
/// Shows the lesson type badge, subject name, teacher, room, and — when
/// the lesson is currently active — an [ActiveBadge] and [LessonProgressBar].
/// Completed lessons are rendered at reduced opacity (0.48).
class LessonCard extends ConsumerWidget {
  const LessonCard({super.key, required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(nowProvider).valueOrNull ?? DateTime.now();
    final isActive =
        now.isAfter(lesson.startTime) && now.isBefore(lesson.endTime);
    final isPast = now.isAfter(lesson.endTime);

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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
    final Color stripColor = AppColors.subjectColor(lesson.subject);

    return Opacity(
      opacity: isPast ? 0.48 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Left colour strip ──────────────────────────────────────
                Container(width: 4, color: stripColor),
                // ── Content ───────────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row: type badge + subject name
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _TypeBadge(type: lesson.type),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                lesson.subject,
                                style: AppTextStyles.subjectName.copyWith(
                                  color: label2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Row: teacher + room
                        Row(
                          children: [
                            Expanded(
                              child: TeacherChip(teacher: lesson.teacher),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: label3,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              lesson.room,
                              style: AppTextStyles.meta.copyWith(color: label3),
                            ),
                          ],
                        ),
                        // Active lesson extras
                        if (isActive) ...[
                          const SizedBox(height: 8),
                          const ActiveBadge(),
                          const SizedBox(height: 6),
                          LessonProgressBar(
                            startTime: lesson.startTime,
                            endTime: lesson.endTime,
                            now: now,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Type badge ────────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final LessonType type;

  @override
  Widget build(BuildContext ctx) {
    final Color bg = _typeColor(ctx);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        type.label,
        style: AppTextStyles.badge.copyWith(color: Colors.white),
      ),
    );
  }

  Color _typeColor(BuildContext ctx) => AppColors.lessonTypeColor(ctx, type);
}
