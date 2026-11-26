import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// JetBrains Mono text with tabular figures.
///
/// The only correct way to render emails, phone numbers, domains, file names,
/// prices and counts. Three sizes mirror the token scale: 14 regular, 14 medium
/// and 13.
class MonoText extends StatelessWidget {
  const MonoText(
    this.text, {
    this.style,
    this.color,
    this.maxLines = 1,
    this.textAlign,
    this.overflow = TextOverflow.ellipsis,
    super.key,
  });

  /// The literal value to show.
  final String text;

  /// One of the mono tokens; defaults to `monoSemibold` at 14.
  final TextStyle? style;

  /// Overrides the color; defaults to `textPrimary`.
  final Color? color;

  /// Maximum lines before ellipsis.
  final int maxLines;

  /// Horizontal alignment.
  final TextAlign? textAlign;

  /// Overflow behavior.
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Text(
      text,
      maxLines: maxLines,
      textAlign: textAlign,
      overflow: overflow,
      style: (style ?? AppTypography.monoSemibold).copyWith(
        color: color ?? colors.textPrimary,
      ),
    );
  }
}
