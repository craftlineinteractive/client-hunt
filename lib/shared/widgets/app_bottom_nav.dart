import 'package:flutter/material.dart';

import '../../core/constants/nav_tabs.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// The bottom navigation, built from the single [navTabs] constant.
///
/// Height 64 plus the safe-area inset, a 1 px top border, a pill indicator
/// (40 × 28, filled `primary`) behind the active icon, and labels that are always
/// visible at 13 px. Inactive items are muted; the active label is weight 600.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  /// Index into [navTabs].
  final int currentIndex;

  /// Called with the tapped tab's index.
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSpacing.bottomNavHeight,
          child: Row(
            children: <Widget>[
              for (int index = 0; index < navTabs.length; index++)
                Expanded(
                  child: _NavItem(
                    tab: navTabs[index],
                    isActive: index == currentIndex,
                    onTap: () => onTap(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  final NavTab tab;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final Color contentColor = isActive ? colors.textPrimary : colors.textMuted;

    return Semantics(
      button: true,
      selected: isActive,
      label: tab.label,
      child: InkWell(
        onTap: onTap,
        splashColor: colors.overlayPressed,
        highlightColor: colors.overlayHover,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 28,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOut,
                width: isActive ? 40 : 28,
                decoration: BoxDecoration(
                  color: isActive ? colors.primary : const Color(0x00000000),
                  borderRadius: AppRadius.pillAll,
                ),
                alignment: Alignment.center,
                child: Icon(
                  isActive ? tab.selectedIcon : tab.icon,
                  size: 20,
                  color: isActive ? colors.onPrimary : colors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              tab.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelMd.copyWith(
                color: contentColor,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
