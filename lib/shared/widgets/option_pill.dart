import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// One choice in an [OptionPillRow].
@immutable
class OptionPillOption<T> {
  const OptionPillOption({required this.value, required this.label});

  /// Value reported when selected.
  final T value;

  /// Short label ("Any", "4.0+", "100+").
  final String label;
}

/// A wrapping row of small single-select pills.
///
/// Used for "Minimum rating" and "Minimum reviews". Pills are 36 px tall, 8 px
/// radius (not fully round, unlike [AppChip]), mono 13 text, and filled with
/// `primary` when selected. The row wraps instead of scrolling so thresholds stay
/// visible.
class OptionPillRow<T> extends StatelessWidget {
  const OptionPillRow({
    required this.options,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  /// The choices.
  final List<OptionPillOption<T>> options;

  /// Selected value.
  final T selected;

  /// Selection handler.
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Wrap(
      spacing: AppSpacing.sm - 2,
      runSpacing: AppSpacing.xs,
      children: <Widget>[
        for (final OptionPillOption<T> option in options)
          Semantics(
            button: true,
            selected: option.value == selected,
            label: option.label,
            child: InkWell(
              onTap: () => onChanged(option.value),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              splashColor: colors.overlayPressed,
              highlightColor: colors.overlayHover,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: option.value == selected
                        ? colors.primary
                        : colors.card,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: option.value == selected
                          ? colors.primary
                          : colors.border,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    option.label,
                    style: AppTypography.monoSm.copyWith(
                      color: option.value == selected
                          ? colors.onPrimary
                          : colors.textSecondary,
                      fontWeight: option.value == selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
