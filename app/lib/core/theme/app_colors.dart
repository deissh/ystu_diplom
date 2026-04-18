import 'package:flutter/cupertino.dart';

import '../../features/schedule/domain/entities/lesson_type.dart';

/// iOS-style color palette for UniSched.
///
/// All colors are static constants.
/// Use [AppColors.resolve] to pick the right variant for the current
/// theme brightness: `AppColors.resolve(context, AppColors.surfaceLight, AppColors.surfaceDark)`.
class AppColors {
  const AppColors._();

  // ── Light theme ──────────────────────────────────────────────────────────

  static const Color bgLight = Color(0xFFF2F2F7);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surface2Light = Color(0xFFF9F9FB);
  static const Color surface3Light = Color(0xFFEFEFF4);
  // rgba(60,60,67,0.12) → alpha = round(0.12 * 255) = 31 = 0x1F
  static const Color separatorLight = Color(0x1F3C3C43);

  static const Color labelLight = Color(0xFF1C1C1E);
  static const Color label2Light = Color(0xFF3C3C43);
  // rgba(60,60,67,0.60) → alpha = round(0.60 * 255) = 153 = 0x99
  static const Color label3Light = Color(0x993C3C43);
  // rgba(60,60,67,0.30) → alpha = round(0.30 * 255) = 77 = 0x4D
  static const Color label4Light = Color(0x4D3C3C43);

  static const Color accentLight = Color(0xFF007AFF);
  static const Color greenLight = Color(0xFF34C759);
  static const Color orangeLight = Color(0xFFFF9500);
  static const Color redLight = Color(0xFFFF3B30);
  static const Color tealLight = Color(0xFF5AC8FA);
  static const Color purpleLight = Color(0xFFAF52DE);

  // ── Dark theme ───────────────────────────────────────────────────────────

  static const Color bgDark = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF1C1C1E);
  static const Color surface2Dark = Color(0xFF2C2C2E);
  static const Color surface3Dark = Color(0xFF3A3A3C);
  // rgba(84,84,88,0.65) → alpha = round(0.65 * 255) = 166 = 0xA6
  static const Color separatorDark = Color(0xA6545458);

  static const Color labelDark = Color(0xFFFFFFFF);
  static const Color label2Dark = Color(0xFFEBEBF5);
  // rgba(235,235,245,0.60) → alpha = 153 = 0x99
  static const Color label3Dark = Color(0x99EBEBF5);
  // rgba(235,235,245,0.30) → alpha = 77 = 0x4D
  static const Color label4Dark = Color(0x4DEBEBF5);

  static const Color accentDark = Color(0xFF0A84FF);
  static const Color greenDark = Color(0xFF30D158);
  static const Color orangeDark = Color(0xFFFF9F0A);
  static const Color redDark = Color(0xFFFF453A);
  static const Color tealDark = Color(0xFF64D2FF);
  static const Color purpleDark = Color(0xFFBF5AF2);

  // ── Semantic (brightness-independent) ────────────────────────────────────

  /// Inactive tab-bar icon and subject fallback color.
  static const Color iconInactive = Color(0xFF8E8E93);

  // ── Subject strip colors (always the light-mode variant) ─────────────────

  static const Color subjectMath = purpleLight;
  static const Color subjectPhysics = tealLight;
  static const Color subjectProgramming = greenLight;
  static const Color subjectLanguage = orangeLight;
  static const Color subjectHumanities = redLight;
  static const Color subjectFallback = iconInactive;

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns [light] when the scaffold is in light mode, [dark] otherwise.
  static Color resolve(BuildContext context, Color light, Color dark) =>
      CupertinoTheme.brightnessOf(context) == Brightness.dark ? dark : light;

  /// Standard iOS-style card shadow token.
  ///
  /// Returns a subtle, diffuse shadow in light mode and an empty list in dark
  /// mode (dark surfaces use elevation rather than shadows on iOS).
  ///
  /// Usage: `boxShadow: AppColors.cardShadow(isDark)`
  static List<BoxShadow> cardShadow(bool isDark) => isDark
      ? const []
      : const [
          BoxShadow(
            // black at ~6% opacity: 0x0F / 255 ≈ 0.059
            color: Color(0x0F000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ];

  /// Returns the color associated with a [LessonType] for the current theme.
  ///
  /// Used by calendar day-cell dots and [_TypeBadge] in the timeline.
  static Color lessonTypeColor(BuildContext context, LessonType type) =>
      switch (type) {
        LessonType.lecture => resolve(context, accentLight, accentDark),
        LessonType.practice => resolve(context, greenLight, greenDark),
        LessonType.lab => resolve(context, orangeLight, orangeDark),
        LessonType.other => resolve(context, label3Light, label3Dark),
      };

  /// Returns the strip color for a lesson card based on the subject name.
  ///
  /// Uses case-insensitive keyword matching against Russian and English terms.
  /// Falls back to [subjectFallback] when no keyword matches.
  static Color subjectColor(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('матем') || s.contains('алгебр')) return subjectMath;
    if (s.contains('физик') || s.contains('хими')) return subjectPhysics;
    if (s.contains('програм') ||
        s.contains('информ') ||
        s.contains('cs') ||
        s.contains('вычисл')) {
      return subjectProgramming;
    }
    if (s.contains('англий') ||
        s.contains('язык') ||
        s.contains('english') ||
        s.contains('иностр')) {
      return subjectLanguage;
    }
    if (s.contains('истор') ||
        s.contains('философ') ||
        s.contains('социол') ||
        s.contains('эконом')) {
      return subjectHumanities;
    }
    return subjectFallback;
  }
}
