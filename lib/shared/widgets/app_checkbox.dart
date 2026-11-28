import 'package:flutter/material.dart';

import '../../core/constants/app_icons.dart';
import '../../core/theme/app_colors.dart';

/// A round-square checkbox with a 48 px tap target and a 20 px visual box.
///
/// The mockups draw the box at 16–20 px; the rule is that the *touch* target is
/// 48 px, so the widget keeps a small mark inside a padded hit area. Selected is
/// a filled `primary` box, never a color accent.
///
/// Used by the Results select row and lead cards and, in B4, by Saved. [onChanged]
/// `null` renders the box at 40% opacity and ignores taps, which is how a locked
/// or disabled selection reads.
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    required this.value,
    this.onChanged,
    this.semanticLabel,
    this.size = 20,
    super.key,
  });

  /// Whether the box is ticked.
  final bool value;

  /// Tap handler; `null` disables the control.
  final ValueChanged<bool>? onChanged;

  /// Accessible label, e.g. "Select Northline Dental Studio".
  final String? semanticLabel;

  /// Visual mark size; 20 on lists, 18 in dense rows.
  final double size;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final bool isEnabled = onChanged != null;

    return Semantics(
      checked: value,
      enabled: isEnabled,
      label: semanticLabel,
      child: Tooltip(
        message: semanticLabel ?? (value ? 'Selected' : 'Select'),
        child: Opacity(
          opacity: isEnabled ? 1 : 0.4,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: isEnabled ? () => onChanged!(!value) : null,
                splashColor: colors.overlayPressed,
                highlightColor: colors.overlayHover,
                child: Center(
                  child: Icon(
                    value ? AppIcons.checkbox : AppIcons.checkboxBlank,
                    size: size,
                    color: value ? colors.primary : colors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
