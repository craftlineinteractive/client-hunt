import 'package:flutter/material.dart';

import 'app_icons.dart';

/// One destination in the app's bottom navigation.
@immutable
class NavTab {
  const NavTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.path,
  });

  /// Visible label under the icon.
  final String label;

  /// Icon shown when the tab is not active.
  final IconData icon;

  /// Icon shown when the tab is active.
  final IconData selectedIcon;

  /// GoRouter path for the tab's root page.
  final String path;
}

/// **The single bottom-navigation definition.**
///
/// Decided: exactly three tabs — Search, Saved, Settings. History is not a
/// destination; recent searches live on the Search screen and "Clear all" lives
/// with them. The three-tab mockups are therefore authoritative and the four-tab
/// frames are noise. To add History later, append a [NavTab] here and register its
/// branch in `app_router.dart` — no widget change is needed.
const List<NavTab> navTabs = <NavTab>[
  NavTab(
    label: 'Search',
    icon: AppIcons.searchOutline,
    selectedIcon: AppIcons.search,
    path: '/search',
  ),
  NavTab(
    label: 'Saved',
    icon: AppIcons.savedOutline,
    selectedIcon: AppIcons.saved,
    path: '/saved',
  ),
  NavTab(
    label: 'Settings',
    icon: AppIcons.settings,
    selectedIcon: AppIcons.settings,
    path: '/settings',
  ),
];
