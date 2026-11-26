import 'package:flutter/material.dart';

import '../../core/constants/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'app_icon_button.dart';

/// One contact line: icon, optional small label, mono value, copy and an optional
/// second action.
///
/// Two layouts:
/// * **compact** — a single line on result cards (20 px icon, 14 mono value).
/// * **detailed** — a 56 px row on lead detail (icon, 13 px label above a 15 px
///   mono value, copy plus an optional open/directions action).
///
/// Missing data is not hidden here: pass [isMissing] with [missingText] to render
/// the mockup's italic "No email found" / "No website found" in muted type. The
/// caller decides whether the row exists at all.
class ContactRow extends StatelessWidget {
  const ContactRow({
    required this.icon,
    required this.value,
    this.label,
    this.onCopy,
    this.copyTooltip = 'Copy',
    this.extraIcon,
    this.extraTooltip,
    this.onExtra,
    this.isMissing = false,
    this.missingText,
    this.isCompact = false,
    super.key,
  });

  /// Leading rounded icon, 20 px.
  final IconData icon;

  /// The value to display (phone, email, domain, address).
  final String value;

  /// Small label above the value in the detailed layout ("Phone", "Email").
  final String? label;

  /// Shows a copy button when non-null.
  final VoidCallback? onCopy;

  /// Tooltip for the copy button.
  final String copyTooltip;

  /// Optional second action icon (`open_in_new_rounded`, `directions_rounded`).
  final IconData? extraIcon;

  /// Tooltip for the second action.
  final String? extraTooltip;

  /// Handler for the second action.
  final VoidCallback? onExtra;

  /// Renders [missingText] in italic sans instead of a mono value.
  final bool isMissing;

  /// Text shown when [isMissing] ("No email found").
  final String? missingText;

  /// Single-line result-card layout.
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    final Widget valueWidget = isMissing
        ? Text(
            missingText ?? 'Not available',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySm.copyWith(
              color: colors.textMuted,
              fontStyle: FontStyle.italic,
            ),
          )
        : Text(
            value,
            maxLines: isCompact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: (isCompact
                    ? AppTypography.monoMd
                    : AppTypography.monoSemibold)
                .copyWith(
              fontSize: isCompact ? 14 : 15,
              color: isCompact ? colors.textSecondary : colors.textPrimary,
            ),
          );

    if (isCompact) {
      return Row(
        children: <Widget>[
          Icon(icon, size: 20, color: colors.textMuted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: valueWidget),
        ],
      );
    }

    return Row(
      children: <Widget>[
        Icon(icon, size: 20, color: colors.textSecondary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (label != null)
                Text(
                  label!,
                  maxLines: 1,
                  style: AppTypography.bodySm.copyWith(
                    color: colors.textMuted,
                    height: 1.2,
                  ),
                ),
              valueWidget,
            ],
          ),
        ),
        if (onExtra != null && extraIcon != null)
          AppIconButton(
            icon: extraIcon!,
            tooltip: extraTooltip ?? 'Open',
            onPressed: onExtra,
            iconSize: 18,
          ),
        if (onCopy != null)
          AppIconButton(
            icon: AppIcons.copy,
            tooltip: copyTooltip,
            onPressed: onCopy,
            iconSize: 18,
          ),
        if (onExtra == null && onCopy == null)
          const SizedBox(width: AppSpacing.xs),
      ],
    );
  }
}
