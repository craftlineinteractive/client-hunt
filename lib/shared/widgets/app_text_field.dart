import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Which field frame to draw.
enum AppTextFieldVariant {
  /// Standard bordered field on the card color (file name, note, search).
  outlined,

  /// Borderless 52 px row inside an [AppFieldGroup] (home niche/location).
  grouped,
}

/// A text field in one of the app's two approved styles.
///
/// Both variants support a leading icon and an optional trailing action. The
/// grouped variant is designed to sit inside [AppFieldGroup], which draws the
/// shared border and dividers.
class AppTextField extends StatelessWidget {
  const AppTextField({
    this.controller,
    this.focusNode,
    this.initialValue,
    this.hintText,
    this.leadingIcon,
    this.trailing,
    this.variant = AppTextFieldVariant.outlined,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.autofocus = false,
    this.isEnabled = true,
    this.isMono = false,
    this.maxLines = 1,
    this.semanticLabel,
    super.key,
  });

  /// External controller. Mutually exclusive with [initialValue].
  final TextEditingController? controller;

  /// External focus node, for typeahead and the Next/Search keyboard actions.
  final FocusNode? focusNode;

  /// Initial text when no controller is supplied.
  final String? initialValue;

  /// Placeholder text.
  final String? hintText;

  /// Leading icon, 20 px.
  final IconData? leadingIcon;

  /// Optional trailing widget (an icon button or a suffix label).
  final Widget? trailing;

  /// Field style.
  final AppTextFieldVariant variant;

  /// Keyboard type.
  final TextInputType? keyboardType;

  /// Keyboard action.
  final TextInputAction? textInputAction;

  /// Change handler.
  final ValueChanged<String>? onChanged;

  /// Submit handler.
  final ValueChanged<String>? onSubmitted;

  /// Tap handler.
  final VoidCallback? onTap;

  /// Requests focus on first build.
  final bool autofocus;

  /// Whether the field accepts input.
  final bool isEnabled;

  /// Renders the value in JetBrains Mono (file names, codes).
  final bool isMono;

  /// 1 for inputs; more for a note textarea.
  final int maxLines;

  /// Optional accessibility label when the hint alone is not descriptive.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final TextStyle style = isMono
        ? AppTypography.monoMd.copyWith(color: colors.textPrimary)
        : AppTypography.bodyLg.copyWith(color: colors.textPrimary);

    if (variant == AppTextFieldVariant.grouped) {
      return SizedBox(
        height: 52,
        child: Row(
          children: <Widget>[
            if (leadingIcon != null) ...<Widget>[
              Icon(leadingIcon, size: 20, color: colors.textSecondary),
              const SizedBox(width: AppSpacing.sm + 2),
            ],
            Expanded(
              child: Semantics(
                label: semanticLabel ?? hintText,
                textField: true,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onTap: onTap,
                  enabled: isEnabled,
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  autofocus: autofocus,
                  style: style,
                  cursorColor: colors.primary,
                  // The group draws the surface and the border. The theme's
                  // input decoration is filled and bordered, and it wins over
                  // `collapsed` for the state borders, so without this every
                  // grouped row paints a second box inside the group.
                  decoration:
                      InputDecoration.collapsed(
                        hintText: hintText,
                        hintStyle: AppTypography.bodyLg.copyWith(
                          color: colors.textMuted,
                        ),
                      ).copyWith(
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                      ),
                ),
              ),
            ),
            if (trailing != null) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ],
          ],
        ),
      );
    }

    return Semantics(
      label: semanticLabel ?? hintText,
      textField: true,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onTap: onTap,
        enabled: isEnabled,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        autofocus: autofocus,
        maxLines: maxLines,
        style: style,
        cursorColor: colors.primary,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: leadingIcon == null ? null : Icon(leadingIcon, size: 20),
          suffixIcon: trailing,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md + 2,
            vertical: maxLines > 1 ? AppSpacing.md : AppSpacing.md + 2,
          ),
        ),
      ),
    );
  }
}

/// A connected group of [AppTextField.grouped] rows.
///
/// A 12 px radius container filled with `surface`, one border, and 1 px dividers
/// between rows — the home screen's niche/location pair.
class AppFieldGroup extends StatelessWidget {
  const AppFieldGroup({
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.md + 2),
    super.key,
  });

  /// Group rows, usually two [AppTextField]s.
  final List<Widget> children;

  /// Horizontal padding applied to every row.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int index = 0; index < children.length; index++) ...<Widget>[
            if (index > 0) Divider(height: 1, color: colors.divider),
            Padding(padding: padding, child: children[index]),
          ],
        ],
      ),
    );
  }
}
