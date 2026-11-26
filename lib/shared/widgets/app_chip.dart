import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Fill style used when a chip is not selected.
enum AppChipTone {
  /// `surface` fill with a border and primary text (home's niche chips).
  filled,

  /// `card` fill with a border and secondary text (result/quick filters).
  outlined,
}

/// Height of an [AppChip].
enum AppChipSize {
  /// 36 px — quick filters and column chips.
  medium,

  /// 44 px — source pills and saved-list filters.
  large,
}

/// A selectable pill chip.
///
/// Selected means filled with `primary`. Unselected follows [tone]. The chip can
/// carry a leading icon, a trailing mono count, or a lock icon for Pro-only
/// options. The visible pill is 36 or 44 px tall; the touch area is padded to the
/// 48 px minimum.
class AppChip extends StatelessWidget {
  const AppChip({
    required this.label,
    this.onTap,
    this.isSelected = false,
    this.leadingIcon,
    this.trailingCount,
    this.isLocked = false,
    this.showCheckWhenSelected = false,
    this.tone = AppChipTone.filled,
    this.size = AppChipSize.medium,
    this.isEnabled = true,
    super.key,
  });

  /// Chip text.
  final String label;

  /// Tap handler; `null` renders a static chip.
  final VoidCallback? onTap;

  /// Selected chips are filled with `primary`.
  final bool isSelected;

  /// Optional leading icon, 16–18 px.
  final IconData? leadingIcon;

  /// Optional trailing count, rendered in mono.
  final int? trailingCount;

  /// Shows a lock instead of the leading icon state (Pro-only option).
  final bool isLocked;

  /// Shows a check before the leading icon when selected.
  final bool showCheckWhenSelected;

  /// Fill style when unselected.
  final AppChipTone tone;

  /// 36 or 44 px.
  final AppChipSize size;

  /// When false the chip renders at 40% opacity and ignores taps.
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final double height = size == AppChipSize.large ? 44 : 36;
    final double verticalInset = math.max(0, (48 - height) / 2);

    final Color background;
    final Color foreground;
    final Color borderColor;
    if (isSelected) {
      background = colors.primary;
      foreground = colors.onPrimary;
      borderColor = colors.primary;
    } else {
      background = tone == AppChipTone.filled ? colors.surface : colors.card;
      foreground = tone == AppChipTone.filled
          ? colors.textPrimary
          : colors.textSecondary;
      borderColor = colors.border;
    }

    final Color contentColor = isLocked ? colors.textSecondary : foreground;

    final Widget pill = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.pillAll,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (isLocked) ...<Widget>[
            Icon(AppIcons.lock, size: 15, color: colors.textMuted),
            const SizedBox(width: AppSpacing.xs + 2),
          ] else if (isSelected && showCheckWhenSelected) ...<Widget>[
            Icon(AppIcons.check, size: 16, color: foreground),
            const SizedBox(width: AppSpacing.xs + 2),
          ] else if (leadingIcon != null) ...<Widget>[
            Icon(
              leadingIcon,
              size: size == AppChipSize.large ? 18 : 16,
              color: contentColor,
            ),
            const SizedBox(width: AppSpacing.xs + 2),
          ],
          Text(
            label,
            maxLines: 1,
            style: AppTypography.labelLg.copyWith(
              color: contentColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          if (trailingCount != null) ...<Widget>[
            const SizedBox(width: AppSpacing.xs + 2),
            Text(
              '$trailingCount',
              style: AppTypography.monoSm.copyWith(
                color: isSelected
                    ? colors.onPrimary.withValues(alpha: 0.8)
                    : colors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );

    return Opacity(
      opacity: isEnabled ? 1 : 0.4,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: verticalInset),
        child: Material(
          color: const Color(0x00000000),
          child: InkWell(
            onTap: isEnabled ? onTap : null,
            borderRadius: AppRadius.pillAll,
            splashColor: colors.overlayPressed,
            highlightColor: colors.overlayHover,
            child: pill,
          ),
        ),
      ),
    );
  }
}
