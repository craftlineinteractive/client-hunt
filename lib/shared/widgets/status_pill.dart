import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// A CRM status pill: New, Contacted, Replied or Closed.
///
/// There is no color coding. The four states differ by border strength, fill
/// step and weight:
/// * **New** and **Replied** — `primary` border, primary text.
/// * **Contacted** — muted border, secondary text.
/// * **Closed** — faint border, muted text.
///
/// Any other label falls back to the neutral style, so unknown states never
/// break the layout.
class StatusPill extends StatelessWidget {
  const StatusPill({required this.label, super.key});

  /// One of "New", "Contacted", "Replied", "Closed".
  final String label;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    final (Color border, Color text, Color fill) = switch (label) {
      'New' ||
      'Replied' => (colors.primary, colors.textPrimary, colors.surface),
      'Contacted' => (
        colors.disabledForeground,
        colors.textSecondary,
        colors.cardSubtle,
      ),
      'Closed' => (colors.disabled, colors.textMuted, colors.surface),
      _ => (colors.border, colors.textSecondary, colors.cardSubtle),
    };

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: AppRadius.pillAll,
        border: Border.all(color: border),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTypography.labelMd.copyWith(
          color: text,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
