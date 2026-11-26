import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// One action inside a [SelectionActionBar].
@immutable
class SelectionAction {
  const SelectionAction({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.isDestructive = false,
  });

  /// Rounded icon, 20 px.
  final IconData icon;

  /// Tooltip and semantic label.
  final String tooltip;

  /// Handler; `null` disables the action.
  final VoidCallback? onTap;

  /// Marks the action as destructive. Still monochrome — the icon, tooltip and
  /// confirmation carry the weight.
  final bool isDestructive;
}

/// The floating bulk-action bar shown while leads are selected.
///
/// Inverted colors in both themes (black on light, white on dark), 56 px tall,
/// 16 px radius, a live dot and "1 selected" on the left, then icon actions on
/// the right. It floats 14 px above the bottom navigation.
class SelectionActionBar extends StatelessWidget {
  const SelectionActionBar({
    required this.selectedCount,
    required this.actions,
    super.key,
  });

  /// Number of selected leads; the bar is hidden by the caller when this is 0.
  final int selectedCount;

  /// Bulk actions, rendered in order.
  final List<SelectionAction> actions;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final Color content = colors.onInverseSurface;

    return Container(
      height: 56,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md + 2,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.inverseSurface,
        borderRadius: AppRadius.lgAll,
        boxShadow: <BoxShadow>[
          if (!colors.isDark)
            BoxShadow(
              color: colors.shadow,
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: content, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$selectedCount selected',
            style: AppTypography.titleSm.copyWith(
              color: content,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          for (final SelectionAction action in actions)
            Tooltip(
              message: action.tooltip,
              child: Semantics(
                button: true,
                label: action.tooltip,
                child: InkWell(
                  onTap: action.onTap,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      action.icon,
                      size: 20,
                      color: content.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
