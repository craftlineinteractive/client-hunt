import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// The app's card.
///
/// 16 px radius, a 1 px border, and a soft shadow in light mode only — dark mode
/// uses the border and surface steps for depth, never a shadow. Padding defaults
/// to 16 px; dense cards pass 12–14. When [onTap] is set the card is tappable and
/// clips its ripple to the rounded shape.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.color,
    this.borderColor,
    this.radius = AppRadius.lg,
    this.showShadow = true,
    super.key,
  });

  /// Card content.
  final Widget child;

  /// Inner padding.
  final EdgeInsetsGeometry padding;

  /// Optional tap handler; adds ripple and semantics.
  final VoidCallback? onTap;

  /// Overrides the card fill (for example `cardSubtle`).
  final Color? color;

  /// Overrides the border color.
  final Color? borderColor;

  /// Corner radius; 16 by default, 12 for compact tiles.
  final double radius;

  /// Shadows are suppressed automatically in dark mode.
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final BorderRadius borderRadius = BorderRadius.circular(radius);
    final Color fill = color ?? colors.card;

    final Widget content = Padding(padding: padding, child: child);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor ?? colors.border),
        boxShadow: <BoxShadow>[
          if (showShadow && !colors.isDark)
            BoxShadow(
              color: colors.shadow,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              borderRadius: borderRadius,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                splashColor: colors.overlayPressed,
                highlightColor: colors.overlayHover,
                child: content,
              ),
            ),
    );
  }
}
