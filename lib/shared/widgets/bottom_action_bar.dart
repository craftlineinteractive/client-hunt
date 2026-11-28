import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'app_button.dart';
import 'app_icon_button.dart';

/// A sticky bottom bar with one primary action and an optional secondary action.
///
/// Used by search results, filters, export and the paywall. Sits above the safe
/// area, has a 1 px top border, a soft top shadow in light mode and 13 px caption
/// support above the button. The primary button is 52–56 px tall; the secondary
/// is a 52 px outlined icon button.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({
    required this.primaryLabel,
    required this.onPrimary,
    this.primaryIcon,
    this.caption,
    this.secondaryIcon,
    this.secondaryTooltip,
    this.onSecondary,
    this.isSecondaryTrailing = false,
    this.isPrimaryLoading = false,
    this.trailing,
    super.key,
  });

  /// Primary button label.
  final String primaryLabel;

  /// Primary button handler.
  final VoidCallback? onPrimary;

  /// Optional primary button icon.
  final IconData? primaryIcon;

  /// Optional 13 px caption above the row ("5 filters active", a plan's billing
  /// summary). Never write a price here: prices come from [ProPlan].
  final String? caption;

  /// Optional secondary icon button.
  final IconData? secondaryIcon;

  /// Tooltip/label for the secondary button; required when [secondaryIcon] is set.
  final String? secondaryTooltip;

  /// Handler for the secondary button.
  final VoidCallback? onSecondary;

  /// Places the secondary button **after** the primary instead of before it.
  ///
  /// Results uses this so the copy menu sits on the right, as the mockup draws
  /// it, without duplicating the bar.
  final bool isSecondaryTrailing;

  /// Shows a spinner in the primary button.
  final bool isPrimaryLoading;

  /// Optional widget trailing the primary button (a count pill).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final bool hasSecondary = secondaryIcon != null;

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.border)),
        boxShadow: <BoxShadow>[
          if (!colors.isDark)
            BoxShadow(
              color: colors.shadow,
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (caption != null) ...<Widget>[
                Text(
                  caption!,
                  textAlign: TextAlign.center,
                  style: AppTypography.monoSm.copyWith(color: colors.textMuted),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              Row(
                children: <Widget>[
                  if (hasSecondary && !isSecondaryTrailing) ...<Widget>[
                    _secondary(),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: AppButton(
                            label: primaryLabel,
                            onPressed: onPrimary,
                            icon: primaryIcon,
                            size: AppButtonSize.large,
                            isLoading: isPrimaryLoading,
                            borderRadius: AppRadius.md,
                          ),
                        ),
                        if (trailing != null) ...<Widget>[
                          const SizedBox(width: AppSpacing.sm),
                          trailing!,
                        ],
                      ],
                    ),
                  ),
                  if (hasSecondary && isSecondaryTrailing) ...<Widget>[
                    const SizedBox(width: AppSpacing.sm),
                    _secondary(),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _secondary() => AppIconButton(
    icon: secondaryIcon!,
    tooltip: secondaryTooltip ?? 'Secondary action',
    onPressed: onSecondary,
    size: 52,
    outlined: true,
  );
}
