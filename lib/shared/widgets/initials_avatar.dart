import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';

/// A square initials tile: "SD" for Shalby Dental.
///
/// 40 px in list rows, 64 px on lead detail. Not circular — the mockups use a
/// rounded square with a 1 px border on `surface`. Initials are derived by the
/// caller from the lead name.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    required this.initials,
    this.size = 40,
    this.radius = AppRadius.md,
    super.key,
  });

  /// One or two uppercase letters.
  final String initials;

  /// Tile edge length; 40 or 64 px.
  final double size;

  /// Corner radius; 12 for rows, 14 for the detail hero.
  final double radius;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final double fontSize = size >= 56 ? 20 : 14;
    return Semantics(
      label: 'Initials $initials',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: colors.border),
        ),
        alignment: Alignment.center,
        child: Text(
          initials.toUpperCase(),
          maxLines: 1,
          style: AppTypography.titleMd.copyWith(
            fontSize: fontSize,
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}
