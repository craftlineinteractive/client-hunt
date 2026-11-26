import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// A 320 × 50 ad slot placeholder.
///
/// Free users only — Pro removes it. Until real ads arrive in prompt E this is an
/// honest, labelled placeholder ("Ad"), never a fake advertisement. An optional
/// [headline] and [onTap] support the saved-leads variant with a "Learn more"
/// action.
class AdBannerPlaceholder extends StatelessWidget {
  const AdBannerPlaceholder({
    this.headline = AppStrings.adHeadline,
    this.isDashed = false,
    this.onTap,
    this.actionLabel,
    super.key,
  });

  /// Supporting line under the "Ad" label.
  final String headline;

  /// Draws a dashed-style border (saved leads variant).
  final bool isDashed;

  /// Optional tap handler.
  final VoidCallback? onTap;

  /// Optional trailing underlined action ("Learn more").
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final Widget content = Container(
      width: 320,
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(
          color: isDashed ? colors.disabled : colors.border,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 1,
            ),
            decoration: BoxDecoration(
              color: colors.divider,
              borderRadius: BorderRadius.circular(AppRadius.checkbox),
            ),
            child: Text(
              AppStrings.adLabel.toUpperCase(),
              style: AppTypography.monoSm.copyWith(color: colors.textMuted),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              headline,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySm.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (actionLabel != null) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            Text(
              actionLabel!,
              style: AppTypography.bodySm.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return Semantics(label: 'Advertisement placeholder', child: content);
    }
    return GestureDetector(onTap: onTap, child: content);
  }
}
