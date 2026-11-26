import 'package:flutter/material.dart';

import '../../core/constants/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Trailing affordance of a [SettingsRow].
enum SettingsTrailing {
  /// A right chevron (pushes a screen).
  chevron,

  /// An external-link icon (opens a URL).
  external,

  /// Nothing.
  none,
}

/// A titled group of settings rows in one bordered card.
///
/// The title sits above the card at 13/600; rows are separated by 1 px dividers
/// and clipped by the 16 px radius, exactly as in the settings mockup.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({required this.children, this.title, super.key});

  /// Optional group title ("Appearance", "Search defaults").
  final String? title;

  /// [SettingsRow] and [ToggleRow] children.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xs,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              title!,
              style: AppTypography.labelMd.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: colors.border),
            boxShadow: <BoxShadow>[
              if (!colors.isDark)
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int index = 0; index < children.length; index++) ...<Widget>[
                if (index > 0) Divider(height: 1, color: colors.divider),
                children[index],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One row inside a [SettingsGroup].
///
/// A 28 px icon tile on `surface`, a 14/500 label, an optional value, and a
/// chevron or external-link affordance. Rows are at least 52 px tall with a 48 px
/// tap target when [onTap] is set.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.label,
    this.icon,
    this.value,
    this.trailing = SettingsTrailing.chevron,
    this.onTap,
    this.trailingWidget,
    this.isMonoValue = false,
    this.isEnabled = true,
    super.key,
  });

  /// Row label.
  final String label;

  /// Optional leading icon, 16 px inside a 28 px tile.
  final IconData? icon;

  /// Optional value shown before the trailing affordance.
  final String? value;

  /// Chevron, external link or nothing.
  final SettingsTrailing trailing;

  /// Tap handler.
  final VoidCallback? onTap;

  /// Replaces the value + affordance entirely (a switch, badge or custom control).
  final Widget? trailingWidget;

  /// Renders the value in mono (numbers, versions, emails).
  final bool isMonoValue;

  /// Dims the row and disables the tap.
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final IconData? trailingIcon = switch (trailing) {
      SettingsTrailing.chevron => AppIcons.chevronRight,
      SettingsTrailing.external => AppIcons.external,
      SettingsTrailing.none => null,
    };

    return Opacity(
      opacity: isEnabled ? 1 : 0.5,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        splashColor: colors.overlayPressed,
        highlightColor: colors.overlayHover,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.sm),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 16, color: colors.textPrimary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.bodyMd.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (trailingWidget != null)
                  trailingWidget!
                else ...<Widget>[
                  if (value != null)
                    Flexible(
                      child: Text(
                        value!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style:
                            (isMonoValue
                                    ? AppTypography.monoSm
                                    : AppTypography.bodySm)
                                .copyWith(color: colors.textMuted),
                      ),
                    ),
                  if (trailingIcon != null) ...<Widget>[
                    const SizedBox(width: AppSpacing.xs),
                    Icon(trailingIcon, size: 16, color: colors.textMuted),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
