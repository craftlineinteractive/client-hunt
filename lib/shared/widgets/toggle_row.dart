import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// A settings/filter row with a switch.
///
/// At least 52 px tall, label at 14/500, optional badge beside the label (a Pro
/// badge on locked filters) and an optional subtitle. The switch itself is themed
/// monochrome and keeps the platform's 48 px tap target.
class ToggleRow extends StatelessWidget {
  const ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.icon,
    this.subtitle,
    this.badge,
    this.isEnabled = true,
    super.key,
  });

  /// Row label.
  final String label;

  /// Current switch value.
  final bool value;

  /// Change handler; `null` disables the switch.
  final ValueChanged<bool>? onChanged;

  /// Optional leading icon, 16 px in a 28 px tile.
  final IconData? icon;

  /// Optional second line under the label.
  final String? subtitle;

  /// Optional widget beside the label (usually a Pro badge).
  final Widget? badge;

  /// Dims the row and disables the switch.
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Opacity(
      opacity: isEnabled ? 1 : 0.5,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 16, color: colors.textPrimary),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            label,
                            style: AppTypography.bodyMd.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (badge != null) ...<Widget>[
                          const SizedBox(width: AppSpacing.sm),
                          badge!,
                        ],
                      ],
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          style: AppTypography.bodySm.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Switch(value: value, onChanged: isEnabled ? onChanged : null),
            ],
          ),
        ),
      ),
    );
  }
}
