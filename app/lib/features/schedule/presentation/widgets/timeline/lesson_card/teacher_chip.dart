import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';

/// A compact chip showing a teacher's avatar (initials) and full name.
///
/// Expects [teacher] in the format "Иванов А.В." — the avatar shows the
/// first letter of each of the first two space-separated words ("ИА").
class TeacherChip extends StatelessWidget {
  const TeacherChip({super.key, required this.teacher});

  final String teacher;

  @override
  Widget build(BuildContext context) {
    final Color accent =
        AppColors.resolve(context, AppColors.accentLight, AppColors.accentDark);
    final Color label3 =
        AppColors.resolve(context, AppColors.label3Light, AppColors.label3Dark);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Avatar ──────────────────────────────────────────────────────────
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: accent,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            _initials(teacher),
            style: AppTextStyles.teacherInitials,
          ),
        ),
        const SizedBox(width: 5),
        // ── Name ─────────────────────────────────────────────────────────────
        Text(
          teacher,
          style: AppTextStyles.teacherName.copyWith(color: label3),
        ),
      ],
    );
  }

  /// Returns up to two capital initials from [name].
  ///
  /// "Иванов А.В." → "ИА"
  static String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    final buf = StringBuffer();
    for (final w in words) {
      if (w.isEmpty) continue;
      buf.write(w[0].toUpperCase());
      if (buf.length >= 2) break;
    }
    return buf.toString();
  }
}
