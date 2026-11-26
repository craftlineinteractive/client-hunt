import 'package:flutter/material.dart';

/// The 4 px spacing scale used across ClientHunt.
///
/// Values come from the mockups (which follow the 4/8/12/16/20/24/32/48 steps
/// in `DESIGN.md`).
abstract final class AppSpacing {
  /// 4 px — icon-to-label micro gap.
  static const double xs = 4;

  /// 8 px — chip gaps, stacked label pairs.
  static const double sm = 8;

  /// 12 px — card inner gaps, related controls.
  static const double md = 12;

  /// 16 px — screen padding, card padding, section gaps.
  static const double lg = 16;

  /// 20 px — between form sections.
  static const double xl = 20;

  /// 24 px — major block separation.
  static const double xxl = 24;

  /// 32 px — empty states, large separation.
  static const double xxxl = 32;

  /// 48 px — screen-level separation.
  static const double huge = 48;

  /// Horizontal screen padding for every screen.
  static const double screenPadding = lg;

  /// Height of a tab/pushed app bar.
  static const double appBarHeight = 56;

  /// Height of the bottom navigation bar (excluding safe area).
  static const double bottomNavHeight = 64;

  /// Standard primary button height.
  static const double buttonHeight = 48;

  /// Large primary button height.
  static const double buttonHeightLarge = 56;

  /// Icon button visual size.
  static const double iconButtonSize = 48;

  /// Minimum touch target for every interactive element.
  static const double minTapTarget = 48;

  /// Standard card padding.
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);

  /// Dense card padding used by result and saved-lead cards.
  static const EdgeInsets denseCardPadding = EdgeInsets.all(md + 2);

  /// Screen body padding.
  static const EdgeInsets screenPaddingAll = EdgeInsets.all(screenPadding);
}
