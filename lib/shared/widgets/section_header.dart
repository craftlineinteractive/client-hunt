import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// A section title with an optional leading icon and an optional trailing action.
///
/// Used above cards and list groups ("Sources", "Recent", "Columns", "My notes").
/// The trailing action is a text button whose tap target is padded to 48 px; pass
/// [trailing] instead when a badge or count must sit on the right.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.icon,
    this.trailingText,
    this.onTrailingTap,
    this.trailing,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  /// Section title, rendered at 16/600.
  final String title;

  /// Optional leading icon, 20 px.
  final IconData? icon;

  /// Optional trailing text action ("Clear all", "Select all").
  final String? trailingText;

  /// Tap handler for [trailingText].
  final VoidCallback? onTrailingTap;

  /// Optional trailing widget, used instead of [trailingText].
  final Widget? trailing;

  /// Outer padding.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final Widget? trailingWidget =
        trailing ??
        (trailingText == null
            ? null
            : InkWell(
                onTap: onTrailingTap,
                borderRadius: BorderRadius.circular(AppSpacing.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.md,
                  ),
                  child: Text(
                    trailingText!,
                    style: AppTypography.labelMd.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ));

    return Padding(
      padding: padding,
      child: Row(
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 20, color: colors.textPrimary),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Text(
              title,
              style: AppTypography.titleSm.copyWith(color: colors.textPrimary),
            ),
          ),
          ?trailingWidget,
        ],
      ),
    );
  }
}
