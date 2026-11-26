import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Visual weight of an [AppButton].
enum AppButtonVariant {
  /// Filled with the primary color. One per screen.
  primary,

  /// Outlined on the card color.
  secondary,

  /// No fill and no border; text only.
  ghost,
}

/// Height of an [AppButton].
enum AppButtonSize {
  /// 48 px.
  medium,

  /// 56 px — hero and sticky-bar CTAs.
  large,
}

/// The app's button.
///
/// * [AppButtonVariant.primary] — filled with `primary`/`onPrimary`.
/// * [AppButtonVariant.secondary] — 1 px border on `card`.
/// * [AppButtonVariant.ghost] — text only.
///
/// Disabled and loading states render at 40% opacity, as in the mockups. A
/// loading button ignores taps but is not dimmed twice. Optional leading icon,
/// 48 or 56 px tall, and a 48 px minimum tap target by construction.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.expand = true,
    this.borderRadius = AppRadius.lg,
    super.key,
  });

  /// Button text.
  final String label;

  /// Tap handler; `null` disables the button.
  final VoidCallback? onPressed;

  /// Visual weight.
  final AppButtonVariant variant;

  /// 48 or 56 px tall.
  final AppButtonSize size;

  /// Optional leading icon, 20 px.
  final IconData? icon;

  /// Shows a spinner in place of the icon and blocks taps.
  final bool isLoading;

  /// Stretch to the available width (default) or hug the content.
  final bool expand;

  /// Corner radius; 16 for screen CTAs, 12–14 for compact bars.
  final double borderRadius;

  bool get _isDisabled => onPressed == null || isLoading;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final double height = size == AppButtonSize.large
        ? AppSpacing.buttonHeightLarge
        : AppSpacing.buttonHeight;

    final (Color background, Color foreground, Color? border) = switch (variant) {
      AppButtonVariant.primary => (colors.primary, colors.onPrimary, null),
      AppButtonVariant.secondary => (colors.card, colors.textPrimary, colors.border),
      AppButtonVariant.ghost => (
        const Color(0x00000000),
        colors.textPrimary,
        null,
      ),
    };

    final Widget leading = isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foreground),
            ),
          )
        : icon == null
        ? const SizedBox.shrink()
        : Icon(icon, size: 20, color: foreground);

    final Widget content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (isLoading || icon != null) ...<Widget>[
          leading,
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.button.copyWith(color: foreground),
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: !_isDisabled,
      label: label,
      child: Opacity(
        opacity: _isDisabled ? 0.4 : 1,
        child: SizedBox(
          height: height,
          width: expand ? double.infinity : null,
          child: Material(
            color: background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              side: border == null
                  ? BorderSide.none
                  : BorderSide(color: border),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _isDisabled ? null : onPressed,
              splashColor: colors.overlayPressed,
              highlightColor: colors.overlayHover,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
