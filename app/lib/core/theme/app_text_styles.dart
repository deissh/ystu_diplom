import 'package:flutter/material.dart';

/// All text styles for UniSched following the iOS SF Pro design spec.
///
/// Sizes, weights, and letter-spacings are taken verbatim from the design
/// system document. Colors are intentionally omitted here — apply them at
/// the call site using [AppColors].
class AppTextStyles {
  const AppTextStyles._();

  /// Screen title: 26 sp, weight 700, letterSpacing −0.5
  static const TextStyle screenTitle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  /// Section header: 13 sp, weight 600, UPPERCASE, letterSpacing 0.6
  static const TextStyle sectionHeader = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
  );

  /// Subject name on lesson card: 14 sp, weight 600
  static const TextStyle subjectName = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  /// Badge / type pill: 10 sp, weight 600, UPPERCASE, letterSpacing 0.3
  static const TextStyle badge = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  /// Meta info (room, teacher): 12 sp, weight 400
  static const TextStyle meta = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  /// Lesson start time: 12 sp, weight 500
  static const TextStyle timeStart = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  /// Lesson end time: 11 sp, weight 400
  static const TextStyle timeEnd = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
  );

  /// Statistics value: 22 sp, weight 700, letterSpacing −0.5
  static const TextStyle statValue = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  /// Statistics caption: 11 sp, weight 400
  static const TextStyle statLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
  );

  /// Day chip — day-of-week abbreviation: 10 sp, weight 500, letterSpacing 0.3
  static const TextStyle dayChipLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  );

  /// Day chip — date number: 17 sp, weight 600
  static const TextStyle dayChipNumber = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
  );

  /// Break row label: 11 sp, weight 400
  static const TextStyle breakLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
  );

  /// Teacher chip name: 12 sp, weight 400
  static const TextStyle teacherName = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  /// Teacher chip avatar initials: 8 sp, weight 700, white
  static const TextStyle teacherInitials = TextStyle(
    fontSize: 8,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  /// Active badge text: 10 sp, weight 600
  static const TextStyle activeBadge = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
  );

  /// Progress bar sub-label: 11 sp, weight 400
  static const TextStyle progressLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
  );

  /// SyncStatusBar main label: 13 sp, weight 600
  static const TextStyle syncStatus = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  /// SyncStatusBar timestamp: 12 sp, weight 400
  static const TextStyle syncTime = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  /// SyncStatusBar chip text: 11 sp, weight 500
  static const TextStyle syncChip = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );
}
