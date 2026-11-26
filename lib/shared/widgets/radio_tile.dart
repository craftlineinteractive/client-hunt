import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// A selectable tile with a radio indicator.
///
/// Two uses:
/// * export scope options — title, optional trailing count, radio on the right;
/// * search depth — title, subtitle and an optional Pro badge.
///
/// The selected tile gets a 2 px `primary` border and a `cardSubtle` fill. Locked
/// tiles render at 80% opacity and are not tappable.
class RadioTile extends StatelessWidget {
  const RadioTile({
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.subtitle,
    this.trailingCount,
    this.badge,
    this.isLocked = false,
    this.isEnabled = true,
    super.key,
  });

  /// Primary label.
  final String title;

  /// Optional second line.
  final String? subtitle;

  /// Whether this tile is the selected option.
  final bool isSelected;

  /// Tap handler.
  final VoidCallback? onTap;

  /// Optional count shown right-aligned in mono ("42", "31").
  final int? trailingCount;

  /// Optional widget beside the title (a Pro badge).
  final Widget? badge;

  /// Marks the tile as Pro-only (dimmed, radio empty).
  final bool isLocked;

  /// Disables the tile entirely.
  final bool isEnabled;

  bool get _isInteractive => isEnabled && onTap != null;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final bool dimmed = isLocked || !isEnabled;

    return Opacity(
      opacity: dimmed ? 0.8 : 1,
      child: Material(
        color: isSelected ? colors.cardSubtle : colors.card,
        borderRadius: AppRadius.mdAll,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _isInteractive ? onTap : null,
          splashColor: colors.overlayPressed,
          highlightColor: colors.overlayHover,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadius.mdAll,
              border: Border.all(
                color: isSelected ? colors.primary : colors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              title,
                              style: AppTypography.bodyMd.copyWith(
                                color: dimmed
                                    ? colors.textSecondary
                                    : colors.textPrimary,
                                fontWeight: FontWeight.w600,
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
                              color: dimmed
                                  ? colors.textMuted
                                  : colors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailingCount != null) ...<Widget>[
                  Text(
                    '$trailingCount',
                    style: AppTypography.monoSm.copyWith(
                      color: isSelected ? colors.textPrimary : colors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                _RadioDot(isSelected: isSelected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? colors.primary : colors.disabledForeground,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: isSelected
          ? Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}
