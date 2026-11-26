import 'package:flutter/material.dart';

import '../../core/constants/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// A rating with its review count: star, "4.8", "(184)".
///
/// Two renderings:
/// * inline (default) — for result-card metadata rows, 13 px.
/// * pill ([isPill]) — a 28 px outlined pill for the lead-detail hero.
///
/// Rating and reviews exist only for Maps leads (see README section 7), so the
/// caller must hide this widget entirely for social-only leads rather than pass
/// zero.
class RatingBadge extends StatelessWidget {
  const RatingBadge({
    required this.rating,
    required this.reviewCount,
    this.isPill = false,
    super.key,
  });

  /// 0–5, one decimal.
  final double rating;

  /// Number of reviews.
  final int reviewCount;

  /// Wraps the content in a 28 px outlined pill.
  final bool isPill;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(AppIcons.star, size: 14, color: colors.textPrimary),
        const SizedBox(width: AppSpacing.xs),
        Text(
          rating.toStringAsFixed(1),
          style: AppTypography.labelMd.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '($reviewCount)',
          style: AppTypography.labelMd.copyWith(color: colors.textMuted),
        ),
      ],
    );

    if (!isPill) {
      return Semantics(
        label: 'Rated ${rating.toStringAsFixed(1)} from $reviewCount reviews',
        child: content,
      );
    }

    return Semantics(
      label: 'Rated ${rating.toStringAsFixed(1)} from $reviewCount reviews',
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: AppRadius.pillAll,
          border: Border.all(color: colors.disabled),
        ),
        alignment: Alignment.center,
        child: content,
      ),
    );
  }
}
