import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// The small "Free" pill, the quiet counterpart to [ProBadge].
///
/// Outlined on `surface` so it never competes with the primary fill.
class FreeBadge extends StatelessWidget {
  const FreeBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.pillAll,
        border: Border.all(color: colors.border),
      ),
      // A `min` Row keeps the pill hugging its label; `alignment` on the
      // Container would stretch it to the parent's width inside a Wrap.
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Free',
            style: AppTypography.labelSm.copyWith(
              color: colors.textSecondary,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
