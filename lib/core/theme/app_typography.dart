import 'package:flutter/material.dart';

/// Typography scale for ClientHunt.
///
/// Three families, **bundled as assets** (no runtime fetching, works offline and
/// in tests and goldens):
/// * **Plus Jakarta Sans** — headings and button labels.
/// * **Inter** — body copy, labels and controls.
/// * **JetBrains Mono** — emails, phone numbers, domains, codes and counts.
///
/// The three files are variable fonts, declared once per weight in `pubspec.yaml`
/// and pinned with a `wght` variation so the rendered weight always matches the
/// token. Mono styles enable tabular figures so numeric columns line up. No UI
/// text is smaller than 13 px; the mockups' 10–12 px labels are raised here.
abstract final class AppTypography {
  /// Heading family. Must match the `family` declared in `pubspec.yaml`.
  static const String headingFamily = 'Plus Jakarta Sans';

  /// Body family.
  static const String bodyFamily = 'Inter';

  /// Numeric / code family.
  static const String monoFamily = 'JetBrains Mono';

  static const List<FontFeature> _tabularFigures = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  /// Builds a token with an explicit weight.
  ///
  /// [weight] does two things: it selects the declared font file and it pins the
  /// variable font's `wght` axis. Without the variation the renderer would use
  /// the file's default instance, so a token asking for 700 could draw at 400.
  static TextStyle _style({
    required String family,
    required double fontSize,
    required FontWeight weight,
    required double height,
    double? letterSpacing,
    bool tabular = false,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: fontSize,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      fontFeatures: tabular ? _tabularFigures : null,
      fontVariations: <FontVariation>[
        FontVariation('wght', weight.value.toDouble()),
      ],
    );
  }

  /// 26 / 32, w700 — home question.
  static final TextStyle headlineLg = _style(
    family: headingFamily,
    fontSize: 26,
    weight: FontWeight.w700,
    height: 32 / 26,
    letterSpacing: -0.26,
  );

  /// 24 / 32, w700 — paywall title.
  static final TextStyle headlineMd = _style(
    family: headingFamily,
    fontSize: 24,
    weight: FontWeight.w700,
    height: 32 / 24,
    letterSpacing: -0.48,
  );

  /// 22 / 28, w700 — settings title.
  static final TextStyle headlineSm = _style(
    family: headingFamily,
    fontSize: 22,
    weight: FontWeight.w700,
    height: 28 / 22,
    letterSpacing: -0.44,
  );

  /// 20 / 28, w700 — tab titles, wordmark.
  static final TextStyle titleLg = _style(
    family: headingFamily,
    fontSize: 20,
    weight: FontWeight.w700,
    height: 28 / 20,
    letterSpacing: -0.2,
  );

  /// 18 / 26, w700 — pushed app-bar titles, lead name.
  static final TextStyle titleMd = _style(
    family: headingFamily,
    fontSize: 18,
    weight: FontWeight.w700,
    height: 26 / 18,
    letterSpacing: -0.18,
  );

  /// 16 / 24, w600 — result-card names, app-bar titles.
  static final TextStyle titleSm = _style(
    family: headingFamily,
    fontSize: 16,
    weight: FontWeight.w600,
    height: 24 / 16,
  );

  /// 15 / 22, w600 — saved-card names, primary button labels.
  static final TextStyle titleXs = _style(
    family: headingFamily,
    fontSize: 15,
    weight: FontWeight.w600,
    height: 22 / 15,
  );

  /// 16 / 24, w400 — long copy, input text.
  static final TextStyle bodyLg = _style(
    family: bodyFamily,
    fontSize: 16,
    weight: FontWeight.w400,
    height: 24 / 16,
  );

  /// 14 / 20, w400 — row labels, feature text.
  static final TextStyle bodyMd = _style(
    family: bodyFamily,
    fontSize: 14,
    weight: FontWeight.w400,
    height: 20 / 14,
  );

  /// 13 / 18, w400 — captions, metadata.
  static final TextStyle bodySm = _style(
    family: bodyFamily,
    fontSize: 13,
    weight: FontWeight.w400,
    height: 18 / 13,
  );

  /// 14 / 20, w500 — chips, quick filters, segmented labels.
  static final TextStyle labelLg = _style(
    family: bodyFamily,
    fontSize: 14,
    weight: FontWeight.w500,
    height: 20 / 14,
  );

  /// 13 / 18, w500 — settings labels, card metadata.
  static final TextStyle labelMd = _style(
    family: bodyFamily,
    fontSize: 13,
    weight: FontWeight.w500,
    height: 18 / 13,
  );

  /// 13 / 18, w600 — badges, pills, overlines (uppercase at the call site).
  static final TextStyle labelSm = _style(
    family: bodyFamily,
    fontSize: 13,
    weight: FontWeight.w600,
    height: 18 / 13,
    letterSpacing: 0.26,
  );

  /// 14 / 20, w400, tabular — result-card contact values.
  static final TextStyle monoMd = _style(
    family: monoFamily,
    fontSize: 14,
    weight: FontWeight.w400,
    height: 20 / 14,
    tabular: true,
  );

  /// 14 / 20, w500, tabular — lead-detail contact values, counts.
  static final TextStyle monoSemibold = _style(
    family: monoFamily,
    fontSize: 14,
    weight: FontWeight.w500,
    height: 20 / 14,
    tabular: true,
  );

  /// 13 / 18, w400, tabular — badges, timestamps, min/max labels.
  static final TextStyle monoSm = _style(
    family: monoFamily,
    fontSize: 13,
    weight: FontWeight.w400,
    height: 18 / 13,
    tabular: true,
  );

  /// 15 / 20, w600 — button labels.
  static final TextStyle button = _style(
    family: headingFamily,
    fontSize: 15,
    weight: FontWeight.w600,
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
