import 'package:flutter/material.dart';

import '../../core/constants/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// A flat, bordered upsell card with inverted colors.
///
/// Black on light, white on dark — the same treatment as the settings Pro card
/// and the paywall hero. No gradient, no illustration: a crown tile, a title, a
/// sentence and a filled-on-inverse action.
class ProUpsellCard extends StatelessWidget {
  const ProUpsellCard({
    required this.title,
    required this.body,
    this.actionLabel = 'Go Pro',
    this.onTap,
    super.key,
  });

  /// Card title.
  final String title;

  /// One or two lines of supporting copy.
  final String body;

  /// Action label.
  final String actionLabel;

  /// Action handler; the whole card is tappable.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final Color foreground = colors.onInverseSurface;

    return Material(
      color: colors.inverseSurface,
      borderRadius: AppRadius.lgAll,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: colors.border.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: foreground.withValues(alpha: 0.08),
                  borderRadius: AppRadius.mdAll,
                  border: Border.all(color: foreground.withValues(alpha: 0.2)),
                ),
                alignment: Alignment.center,
                child: Icon(AppIcons.pro, size: 20, color: foreground),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: AppTypography.titleSm.copyWith(color: foreground),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      body,
                      style: AppTypography.bodySm.copyWith(
                        color: foreground.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: foreground,
                  borderRadius: AppRadius.pillAll,
                ),
                alignment: Alignment.center,
                child: Text(
                  actionLabel,
                  style: AppTypography.labelSm.copyWith(
                    color: colors.inverseSurface,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
