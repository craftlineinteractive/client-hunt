import 'package:flutter/material.dart';

import '../../core/constants/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// A single-line informational note: icon, text, optional action and dismiss.
///
/// Used for "Emails are unverified", "Only on this device" and the paywall's
/// legal notice. Muted by default; [isEmphasized] uses primary text and a
/// stronger icon weight for notes that must not be missed. [actionLabel] adds a
/// text action on the right ("Go Pro", "Details", "Search again") with a 48 px
/// tap height, so a note can be actionable without becoming a card.
class InfoNote extends StatelessWidget {
  const InfoNote({
    required this.text,
    this.icon = AppIcons.info,
    this.onDismiss,
    this.dismissTooltip = 'Dismiss',
    this.isEmphasized = false,
    this.actionLabel,
    this.onAction,
    this.actionTooltip,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    super.key,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'An action needs both a label and a handler',
       );

  /// Note text, 13 px.
  final String text;

  /// Leading icon, 16 px.
  final IconData icon;

  /// Shows a dismiss button when non-null.
  final VoidCallback? onDismiss;

  /// Tooltip for the dismiss button.
  final String dismissTooltip;

  /// Uses primary text instead of muted.
  final bool isEmphasized;

  /// Optional trailing action label.
  final String? actionLabel;

  /// Optional trailing action handler.
  final VoidCallback? onAction;

  /// Tooltip/semantic label for the trailing action; defaults to [actionLabel].
  final String? actionTooltip;

  /// Outer padding.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final Color color = isEmphasized ? colors.textPrimary : colors.textMuted;

    return Padding(
      padding: padding,
      child: Row(
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.sm - 2),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySm.copyWith(color: color),
            ),
          ),
          if (actionLabel != null && onAction != null)
            Tooltip(
              message: actionTooltip ?? actionLabel!,
              child: Semantics(
                button: true,
                label: actionTooltip ?? actionLabel,
                child: InkWell(
                  onTap: onAction,
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      child: Center(
                        widthFactor: 1,
                        heightFactor: 1,
                        child: Text(
                          actionLabel!,
                          maxLines: 1,
                          style: AppTypography.labelMd.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (onDismiss != null) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            Tooltip(
              message: dismissTooltip,
              child: Semantics(
                button: true,
                label: dismissTooltip,
                child: InkWell(
                  onTap: onDismiss,
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: Icon(
                      AppIcons.close,
                      size: 16,
                      color: colors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
