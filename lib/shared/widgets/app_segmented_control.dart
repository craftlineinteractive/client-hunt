import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// How the selected segment is drawn.
enum AppSegmentedStyle {
  /// Selected segment is a raised card on a recessed track (settings, filters,
  /// saved-list statuses).
  boxed,

  /// Selected segment is filled with `primary` (lead-detail status).
  filled,
}

/// One option in an [AppSegmentedControl].
@immutable
class AppSegmentOption<T> {
  const AppSegmentOption({
    required this.value,
    required this.label,
    this.count,
  });

  /// Value reported when selected.
  final T value;

  /// Segment label, 13 px.
  final String label;

  /// Optional count under the label (saved-list statuses), rendered in mono.
  final int? count;
}

/// A 2–5 option segmented control.
///
/// Options share the width equally. The track is `surface` with a 1 px border and
/// a 12 px radius; the selected option is either a raised card ([AppSegmentedStyle.boxed])
/// or a primary fill ([AppSegmentedStyle.filled]). Each option keeps a 48 px tap
/// area through its padding.
class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    required this.options,
    required this.selected,
    required this.onChanged,
    this.style = AppSegmentedStyle.boxed,
    super.key,
  }) : assert(
         options.length >= 2 && options.length <= 5,
         'Segmented controls take 2 to 5 options',
       );

  /// The options, left to right.
  final List<AppSegmentOption<T>> options;

  /// Currently selected value.
  final T selected;

  /// Selection handler.
  final ValueChanged<T> onChanged;

  /// Selected-segment treatment.
  final AppSegmentedStyle style;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: <Widget>[
          for (final AppSegmentOption<T> option in options)
            Expanded(
              child: _Segment<T>(
                option: option,
                isSelected: option.value == selected,
                style: style,
                onTap: () => onChanged(option.value),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.option,
    required this.isSelected,
    required this.style,
    required this.onTap,
  });

  final AppSegmentOption<T> option;
  final bool isSelected;
  final AppSegmentedStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final bool isFilled = style == AppSegmentedStyle.filled;

    final Color foreground;
    final Color? background;
    if (!isSelected) {
      foreground = colors.textSecondary;
      background = null;
    } else if (isFilled) {
      foreground = colors.onPrimary;
      background = colors.primary;
    } else {
      foreground = colors.textPrimary;
      background = colors.card;
    }

    return Semantics(
      button: true,
      selected: isSelected,
      label: option.count == null
          ? option.label
          : '${option.label} ${option.count}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        splashColor: colors.overlayPressed,
        highlightColor: colors.overlayHover,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: background ?? Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            boxShadow: <BoxShadow>[
              if (isSelected && !isFilled && !colors.isDark)
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.labelMd.copyWith(
                  color: foreground,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (option.count != null)
                Text(
                  '${option.count}',
                  style: AppTypography.monoSm.copyWith(
                    color: isSelected
                        ? (isFilled
                              ? colors.onPrimary.withValues(alpha: 0.8)
                              : colors.textSecondary)
                        : colors.textMuted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
