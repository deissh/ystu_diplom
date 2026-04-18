import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';

/// A compact chip showing a teacher's avatar (initials) and full name.
///
/// Expects [teacher] in one of two formats:
/// - Abbreviated: «Иванов А.В.» → avatar shows «ИВ» (фамилия + отчество).
/// - Full name:   «Иванов Александр Владимирович» → avatar shows «ИВ».
///
/// In both cases the algorithm splits on spaces and dots, filters empty tokens,
/// and takes token[0][0] (фамилия) + token[2][0] (отчество) when available.
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
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: accent,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            _initials(teacher),
            style: AppTextStyles.teacherInitials.copyWith(fontSize: 10),
          ),
        ),
        const SizedBox(width: 6),
        // ── Name ─────────────────────────────────────────────────────────────
        Flexible(
          child: Text(
            teacher,
            style: AppTextStyles.teacherName.copyWith(color: label3),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Returns up to two initials: first letter of фамилия + first letter of отчество.
  ///
  /// Splits [name] on spaces and dots, filters empty segments, then:
  /// - tokens[0][0] → фамилия
  /// - tokens[2][0] → отчество (if available); falls back to tokens[1][0] (имя)
  ///
  /// Examples:
  /// - «Иванов А.В.»               → tokens: [Иванов, А, В] → «ИВ»
  /// - «Иванов Александр Владимирович» → tokens: [Иванов, Александр, Владимирович] → «ИВ»
  /// - «Иванов»                    → tokens: [Иванов]        → «И»
  /// - «»                          → tokens: []              → «»
  static String _initials(String name) {
    final tokens = name
        .trim()
        .split(RegExp(r'[ .]'))
        .where((s) => s.isNotEmpty)
        .toList();

    if (tokens.isEmpty) return '';

    final buf = StringBuffer(tokens[0][0].toUpperCase());
    if (tokens.length >= 3) {
      buf.write(tokens[2][0].toUpperCase());
    } else if (tokens.length >= 2) {
      buf.write(tokens[1][0].toUpperCase());
    }
    return buf.toString();
  }
}
