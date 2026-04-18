import 'package:flutter/cupertino.dart';

/// Breakpoint-based layout helper for adaptive phone + iPad layouts.
///
/// Usage:
/// ```dart
/// padding: EdgeInsets.symmetric(horizontal: AppLayout.hPad(context)),
/// child: ConstrainedBox(
///   constraints: BoxConstraints(maxWidth: AppLayout.maxContent(context)),
///   child: ...,
/// )
/// ```
class AppLayout {
  const AppLayout._();

  /// Minimum width (exclusive) for the regular breakpoint.
  static const double kNarrowBreakpoint = 600;

  /// Minimum width (exclusive) for the wide breakpoint.
  static const double kRegularBreakpoint = 900;

  /// Horizontal padding for content areas.
  ///
  /// - narrow  (< 600 dp):  16 dp
  /// - regular (600–899 dp): 24 dp
  /// - wide    (≥ 900 dp):  32 dp
  static double hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= kRegularBreakpoint) return 32;
    if (width >= kNarrowBreakpoint) return 24;
    return 16;
  }

  /// Maximum content width to keep readability on large screens.
  ///
  /// - narrow  (< 600 dp):  unconstrained
  /// - regular (600–899 dp): 680 dp
  /// - wide    (≥ 900 dp):  720 dp
  static double maxContent(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= kRegularBreakpoint) return 720;
    if (width >= kNarrowBreakpoint) return 680;
    return double.infinity;
  }
}
