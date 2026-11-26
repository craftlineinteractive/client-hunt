import 'package:flutter/material.dart';

import '../../core/constants/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// A single-line informational note: icon, text, optional dismiss.
///
/// Used for "Contact details are sourced publicly and unverified", "Only on this
/// device" and the paywall's legal notice. Muted by default; [isEmphasized] uses
/// primary text and a stronger icon weight for notes that must not be missed.
class InfoNote extends StatelessWidget {
  const InfoNote({
    required this.text,
    this.icon = AppIcons.info,
    this.onDismiss,
    this.dismissTooltip = 'Dismiss',
    this.isEmphasized = false,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    super.key,
  });

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
