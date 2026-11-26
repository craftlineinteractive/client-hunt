import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography scale for ClientHunt.
///
/// Three families, loaded through `google_fonts`:
/// * **Plus Jakarta Sans** — headings and numerals in headings.
/// * **Inter** — body copy, labels and controls.
/// * **JetBrains Mono** — emails, phone numbers, domains, codes and counts.
///
/// Mono styles enable tabular figures so numeric columns line up. No UI text is
/// smaller than 13 px; the mockups' 10–12 px labels are raised here.
abstract final class AppTypography {
  static const String headingFamily = 'Plus Jakarta Sans';
  static const String bodyFamily = 'Inter';
  static const String monoFamily = 'JetBrains Mono';

  static const List<FontFeature> _tabularFigures = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  /// 26 / 32, w700 — home question.
  static final TextStyle headlineLg = GoogleFonts.plusJakartaSans(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 32 / 26,
    letterSpacing: -0.26,
  );

  /// 24 / 32, w700 — paywall title.
  static final TextStyle headlineMd = GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 32 / 24,
    letterSpacing: -0.48,
  );

  /// 22 / 28, w700 — settings title.
  static final TextStyle headlineSm = GoogleFonts.plusJakartaSans(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 28 / 22,
    letterSpacing: -0.44,
  );

  /// 20 / 28, w700 — tab titles, wordmark.
  static final TextStyle titleLg = GoogleFonts.plusJakartaSans(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 28 / 20,
    letterSpacing: -0.2,
  );

  /// 18 / 26, w700 — pushed app-bar titles, lead name.
  static final TextStyle titleMd = GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 26 / 18,
    letterSpacing: -0.18,
  );

  /// 16 / 24, w600 — result-card names, app-bar titles.
  static final TextStyle titleSm = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
  );

  /// 15 / 22, w600 — saved-card names, primary button labels.
  static final TextStyle titleXs = GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 22 / 15,
  );

  /// 16 / 24, w400 — long copy, input text.
  static final TextStyle bodyLg = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
  );

  /// 14 / 20, w400 — row labels, feature text.
  static final TextStyle bodyMd = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
  );

  /// 13 / 18, w400 — captions, metadata.
  static final TextStyle bodySm = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 18 / 13,
  );

  /// 14 / 20, w500 — chips, quick filters, segmented labels.
  static final TextStyle labelLg = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 20 / 14,
  );

  /// 13 / 18, w500 — settings labels, card metadata.
  static final TextStyle labelMd = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 18 / 13,
  );

  /// 13 / 18, w600 — badges, pills, overlines (uppercase at the call site).
  static final TextStyle labelSm = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 18 / 13,
    letterSpacing: 0.26,
  );

  /// 14 / 20, w400, tabular — result-card contact values.
  static final TextStyle monoMd = GoogleFonts.jetBrainsMono(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    fontFeatures: _tabularFigures,
  );

  /// 14 / 20, w500, tabular — lead-detail contact values, counts.
  static final TextStyle monoSemibold = GoogleFonts.jetBrainsMono(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 20 / 14,
    fontFeatures: _tabularFigures,
  );

  /// 13 / 18, w400, tabular — badges, timestamps, min/max labels.
  static final TextStyle monoSm = GoogleFonts.jetBrainsMono(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 18 / 13,
    fontFeatures: _tabularFigures,
  );

  /// 15 / 20, w600 — button labels.
  static final TextStyle button = GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 20 / 15,
  );

  /// The theme's [TextTheme], mapped onto the scale above.
  static TextTheme get textTheme => TextTheme(
    displayLarge: headlineLg,
    displayMedium: headlineMd,
    displaySmall: headlineSm,
    headlineLarge: headlineLg,
    headlineMedium: headlineMd,
    headlineSmall: headlineSm,
    titleLarge: titleLg,
    titleMedium: titleMd,
    titleSmall: titleSm,
    bodyLarge: bodyLg,
    bodyMedium: bodyMd,
    bodySmall: bodySm,
    labelLarge: labelLg,
    labelMedium: labelMd,
    labelSmall: labelSm,
  );
}
