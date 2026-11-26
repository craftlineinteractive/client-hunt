import 'package:flutter/material.dart';

/// Corner radius scale for ClientHunt.
///
/// The mockups use four core radii (8, 12, 16 and pills) plus a 14 px tile
/// radius for initials tiles and detail action buttons.
abstract final class AppRadius {
  /// 8 px — small badges, inner segmented options, tiny tags.
  static const double sm = 8;

  /// 12 px — inputs, icon tiles, contact cards, inner rows.
  static const double md = 12;

  /// 14 px — initials tiles, 52 px action buttons on lead detail.
  static const double tile = 14;

  /// 16 px — cards, result cards, primary CTA, plan rows.
  static const double lg = 16;

  /// 20 px — bottom sheets and dialogs.
  static const double xl = 20;

  /// 999 px — chips, badges, pills, switches, navigation indicator.
  static const double pill = 999;

  /// 4 px — checkboxes only.
  static const double checkbox = 4;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius tileAll = BorderRadius.all(Radius.circular(tile));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));

  /// Top-only rounding used by bottom sheets.
  static const BorderRadius sheetTop = BorderRadius.vertical(
    top: Radius.circular(xl),
  );
}
