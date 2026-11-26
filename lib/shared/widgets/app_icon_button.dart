import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';

/// An icon-only button with a required accessible label.
///
/// Used for app-bar actions, copy buttons and the compact action grids in the
/// mockups. The visual box is 44–52 px but the tap target is always at least
/// 48 px, so a 44 px button still meets the touch rule. [tooltip] is required so
/// every icon has a text alternative for screen readers.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.size = 44,
    this.outlined = false,
    this.borderRadius = AppRadius.md,
    this.iconSize,
    super.key,
  }) : assert(size >= 44 && size <= 52, 'Size must be between 44 and 52 px');

  /// The rounded icon to draw.
  final IconData icon;

  /// Tooltip and semantic label. Never optional: icons cannot speak.
  final String tooltip;

  /// Tap handler; `null` disables the button.
  final VoidCallback? onPressed;

  /// Visual box size, 44–52 px.
  final double size;

  /// Draws a 1 px border on a card fill.
  final bool outlined;

  /// Corner radius of the visual box.
  final double borderRadius;

  /// Optional icon size override; defaults to 20 below 48 px, otherwise 22.
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final bool isDisabled = onPressed == null;
    final double resolvedIconSize = iconSize ?? (size >= 48 ? 22 : 20);

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: !isDisabled,
        label: tooltip,
        child: Opacity(
          opacity: isDisabled ? 0.4 : 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: Center(
              child: Material(
                color: outlined ? colors.card : const Color(0x00000000),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                  side: outlined
                      ? BorderSide(color: colors.border)
                      : BorderSide.none,
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: isDisabled ? null : onPressed,
                  splashColor: colors.overlayPressed,
                  highlightColor: colors.overlayHover,
                  child: SizedBox(
                    width: size,
                    height: size,
                    child: Icon(
                      icon,
                      size: resolvedIconSize,
                      color: colors.textPrimary,
                    ),
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
