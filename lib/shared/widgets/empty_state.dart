import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'app_button.dart';

/// A centered empty state: 32 px icon, title, one or two lines of body, optional
/// action and optional secondary action. Used for "no results", "nothing saved
/// yet" and error states. Icons and weight carry the meaning — never color.
///
/// Results uses the second action for "Edit search" plus "Clear filters"; a
/// single-action state simply leaves it null.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.padding = const EdgeInsets.all(AppSpacing.xxl),
    super.key,
  });

  /// Rounded icon, 32 px.
  final IconData icon;

  /// Short headline.
  final String title;

  /// Explanatory body copy.
  final String body;

  /// Optional action label.
  final String? actionLabel;

  /// Optional action handler.
  final VoidCallback? onAction;

  /// Optional second, quieter action ("Clear filters").
  final String? secondaryActionLabel;

  /// Handler for [secondaryActionLabel].
  final VoidCallback? onSecondaryAction;

  /// Outer padding.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: colors.border),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 32, color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.titleMd.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(color: colors.textMuted),
          ),
          if (actionLabel != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xl),
            AppButton(label: actionLabel!, onPressed: onAction, expand: false),
          ],
          if (secondaryActionLabel != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: secondaryActionLabel!,
              onPressed: onSecondaryAction,
              variant: AppButtonVariant.ghost,
              expand: false,
            ),
          ],
        ],
      ),
    );
  }
}
