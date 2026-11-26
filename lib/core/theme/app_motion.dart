import 'package:flutter/animation.dart';

/// Motion tokens for ClientHunt.
///
/// Durations and curves match the mockups' CSS transitions.
abstract final class AppMotion {
  /// 100 ms — hover/press, toggle thumb, chip select.
  static const Duration micro = Duration(milliseconds: 100);

  /// 200 ms — expand/collapse, tab change, snackbar.
  static const Duration standard = Duration(milliseconds: 200);

  /// 300 ms — page push, bottom sheet, dialog.
  static const Duration structural = Duration(milliseconds: 300);

  /// `cubic-bezier(0.4, 0, 0.2, 1)` — micro interactions.
  static const Cubic microCurve = Cubic(0.4, 0, 0.2, 1);

  /// `cubic-bezier(0.16, 1, 0.3, 1)` — standard transitions.
  static const Cubic standardCurve = Cubic(0.16, 1, 0.3, 1);

  /// `cubic-bezier(0.16, 1, 0.3, 1)` — structural transitions.
  static const Cubic structuralCurve = Cubic(0.16, 1, 0.3, 1);
}
