import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Where a lead came from: "Maps", "Instagram", "LinkedIn", "Facebook", "X", "Web".
///
/// A quiet outlined pill with mono text, as drawn in the result cards and the
/// lead-detail hero. The caller supplies the label so this widget stays free of
/// domain types.
class SourceBadge extends StatelessWidget {
  const SourceBadge({required this.label, super.key});

  /// Source name exactly as it should render.
  final String label;

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
      // A Row with `min` keeps the pill hugging its label; a Container with
      // `alignment` would stretch to the parent's width inside a Wrap/Row.
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: AppTypography.monoSm.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
