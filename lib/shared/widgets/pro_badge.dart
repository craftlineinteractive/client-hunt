import 'package:flutter/material.dart';

import '../../core/constants/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// The small "Pro" pill.
///
/// Filled with `primary`, 24 px tall, with a lock icon so the badge reads as a
/// gate rather than decoration. Used on locked sources, filters, depth options,
/// the profiles card and the paywall. Pass [showLock] false where the badge sits
/// beside a crown (the home app bar), matching the mockups.
class ProBadge extends StatelessWidget {
  const ProBadge({this.showLock = true, this.label = 'Pro', super.key});

  /// Whether to show the lock icon.
  final bool showLock;

  /// Badge text; "Pro" by default, "PRO" in uppercase contexts.
  final String label;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Semantics(
      label: 'Pro feature',
      child: Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: AppRadius.pillAll,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (showLock) ...<Widget>[
              Icon(AppIcons.lock, size: 14, color: colors.onPrimary),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: AppTypography.labelSm.copyWith(
                color: colors.onPrimary,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
