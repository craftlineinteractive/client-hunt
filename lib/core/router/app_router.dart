import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../dev/design_gallery_page.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import '../constants/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Every route path and name in one place.
///
/// Later prompts navigate with these constants instead of raw strings so a path
/// change is a single edit.
abstract final class AppRoutes {
  static const String search = '/search';
  static const String searchName = 'search';

  static const String saved = '/saved';
  static const String savedName = 'saved';

  static const String settings = '/settings';
  static const String settingsName = 'settings';

  static const String results = '/results';
  static const String resultsName = 'results';

  /// `/lead/:id` — the id is a placeholder until the data layer exists.
  static const String leadDetail = '/lead/:id';
  static const String leadDetailName = 'leadDetail';

  static String leadDetailPath(String id) => '/lead/$id';

  static const String filters = '/filters';
  static const String filtersName = 'filters';

  static const String exportLeads = '/export';
  static const String exportLeadsName = 'exportLeads';

  static const String pro = '/pro';
  static const String proName = 'pro';

  static const String designGallery = '/dev/gallery';
  static const String designGalleryName = 'designGallery';
}

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

/// The app router.
///
/// The three tab destinations live in a [StatefulShellRoute] so the bottom
/// navigation survives tab switches. Every other destination is pushed on the
/// root navigator, covering the shell and its navigation bar, exactly as the
/// mockups draw them.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.search,
  routes: <RouteBase>[
    StatefulShellRoute.indexedStack(
      builder: (BuildContext context, GoRouterState state,
              StatefulNavigationShell navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: <StatefulShellBranch>[
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.search,
              name: AppRoutes.searchName,
              builder: (BuildContext context, GoRouterState state) =>
                  const PlaceholderScreen(
                title: AppStrings.searchTab,
                subtitle: AppStrings.question,
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.saved,
              name: AppRoutes.savedName,
              builder: (BuildContext context, GoRouterState state) =>
                  const PlaceholderScreen(
                title: 'Saved leads',
                subtitle: 'Your on-device lead pipeline.',
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.settings,
              name: AppRoutes.settingsName,
              builder: (BuildContext context, GoRouterState state) =>
                  const PlaceholderScreen(
                title: AppStrings.settingsTab,
                subtitle: 'Theme, defaults, storage and legal.',
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.results,
      name: AppRoutes.resultsName,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) =>
          const PlaceholderScreen(title: 'Search results'),
    ),
    GoRoute(
      path: AppRoutes.leadDetail,
      name: AppRoutes.leadDetailName,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) =>
          PlaceholderScreen(
        title: 'Lead details',
        subtitle: state.pathParameters['id'],
      ),
    ),
    GoRoute(
      path: AppRoutes.filters,
      name: AppRoutes.filtersName,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) =>
          const PlaceholderScreen(title: AppStrings.filters),
    ),
    GoRoute(
      path: AppRoutes.exportLeads,
      name: AppRoutes.exportLeadsName,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) =>
          const PlaceholderScreen(title: 'Export leads'),
    ),
    GoRoute(
      path: AppRoutes.pro,
      name: AppRoutes.proName,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) =>
          const PlaceholderScreen(title: 'ClientHunt Pro'),
    ),
    // Debug-only: the component gallery never ships in a release build.
    if (kDebugMode)
      GoRoute(
        path: AppRoutes.designGallery,
        name: AppRoutes.designGalleryName,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) =>
            const DesignGalleryPage(),
      ),
  ],
);

/// Shell that hosts the three tab destinations and the bottom navigation.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (int index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

/// A deliberately empty screen that only names the destination.
///
/// Each feature folder gets its real screen in prompt B; the router already
/// points at these so every route can be exercised today.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({required this.title, this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.headlineSm.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMd.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Text(
                AppStrings.placeholderCaption,
                textAlign: TextAlign.center,
                style: AppTypography.bodySm.copyWith(color: colors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
