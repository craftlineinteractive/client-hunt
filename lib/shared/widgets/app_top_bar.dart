import 'package:flutter/material.dart';

import '../../core/constants/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// The app bar, in its two approved variants.
///
/// * [AppTopBar.tab] — a root tab screen: no back button, a large title, optional
///   wordmark, optional actions. Used by Search, Saved and Settings.
/// * [AppTopBar.pushed] — a pushed screen: a back (or close) button, a compact
///   title with an optional muted subtitle, and up to three actions.
///
/// Built on Material's [AppBar] so the status-bar inset, safe area and system
/// gestures are handled for free. Elevation is zero and the theme supplies the
/// 1 px bottom border. Text is never smaller than 13 px.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// Root-tab variant.
  const AppTopBar.tab({
    required this.title,
    this.actions,
    this.showWordmark = false,
    this.trailing,
    super.key,
  }) : subtitle = null,
       leadingIcon = null,
       onLeading = null,
       _isPushed = false;

  /// Pushed-screen variant.
  const AppTopBar.pushed({
    required this.title,
    this.subtitle,
    this.actions,
    this.leadingIcon = AppIcons.back,
    this.onLeading,
    super.key,
  }) : showWordmark = false,
       trailing = null,
       _isPushed = true;

  /// The screen title.
  final String title;

  /// Muted second line under a pushed title ("42 leads · Maps").
  final String? subtitle;

  /// Right-hand actions, normally [AppIconButton]s.
  final List<Widget>? actions;

  /// Draws the ClientHunt logo and wordmark instead of a plain title.
  final bool showWordmark;

  /// Optional widget pinned to the right of a tab title (a count pill).
  final Widget? trailing;

  /// Leading icon for the pushed variant; defaults to a back arrow.
  final IconData? leadingIcon;

  /// Called when the leading button is tapped; defaults to popping the route.
  final VoidCallback? onLeading;

  final bool _isPushed;

  @override
  Size get preferredSize => const Size.fromHeight(AppSpacing.appBarHeight);

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    final Widget titleWidget = _isPushed
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleSm.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySm.copyWith(
                    color: colors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (showWordmark) ...<Widget>[
                Icon(AppIcons.logo, size: 20, color: colors.textPrimary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: AppTypography.titleMd.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ] else
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headlineSm.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: AppSpacing.sm),
                trailing!,
              ],
            ],
          );

    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: AppSpacing.lg,
      title: titleWidget,
      leadingWidth: _isPushed ? 56 : 0,
      leading: _isPushed
          ? IconButton(
              icon: Icon(leadingIcon, size: 24),
              tooltip: leadingIcon == AppIcons.close ? 'Close' : 'Go back',
              onPressed: onLeading ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      actions: actions == null
          ? null
          : <Widget>[...actions!, const SizedBox(width: AppSpacing.sm)],
    );
  }
}
