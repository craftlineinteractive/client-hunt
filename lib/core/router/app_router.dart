import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../dev/design_gallery_page.dart';
import '../../domain/models/export_args.dart';
import '../../domain/repositories/lead_search_engine.dart';
import '../../features/home/home_page.dart';
import '../../features/results/results_placeholder_page.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import '../constants/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_routes.dart';

export 'app_routes.dart';

/// The app router.
///
/// Three tab destinations live in a [StatefulShellRoute.indexedStack] so each
/// tab preserves its own state and the bottom navigation stays visible. Every
/// other destination is pushed on the root navigator with
/// `parentNavigatorKey: _rootNavigatorKey`, which covers the shell — and with it
/// the bottom bar, exactly as the mockups draw those screens.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

/// The single router instance.
final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.search,
  routes: <RouteBase>[
    StatefulShellRoute.indexedStack(
      builder:
          (
            BuildContext context,
            GoRouterState state,
            StatefulNavigationShell navigationShell,
          ) => AppShell(navigationShell: navigationShell),
      branches: <StatefulShellBranch>[
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.search,
              name: AppRoutes.searchName,
              builder: (BuildContext context, GoRouterState state) =>
                  const HomePage(),
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
                    title: SavedStrings.title,
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
                    title: CommonStrings.settingsTab,
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
      parentNavigatorKey: rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) =>
          ResultsPlaceholderPage(
            request: state.extra is SearchRequest
                ? state.extra! as SearchRequest
                : null,
          ),
    ),
    GoRoute(
      path: AppRoutes.leadDetail,
      name: AppRoutes.leadDetailName,
      parentNavigatorKey: rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) => PlaceholderScreen(
        title: 'Lead details',
        subtitle: state.pathParameters['id'],
      ),
    ),
    GoRoute(
      path: AppRoutes.filters,
      name: AppRoutes.filtersName,
      parentNavigatorKey: rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) =>
          const PlaceholderScreen(title: FiltersStrings.title),
    ),
    GoRoute(
      path: AppRoutes.exportLeads,
      name: AppRoutes.exportLeadsName,
      parentNavigatorKey: rootNavigatorKey,
      // The placeholder renders the ExportArgs it received, so the Results →
      // Export hand-off is checkable on a device before prompt B6 builds the real
      // screen.
      builder: (BuildContext context, GoRouterState state) {
        final Object? extra = state.extra;
        final ExportArgs? args = extra is ExportArgs ? extra : null;
        return PlaceholderScreen(
          title: 'Export leads',
          subtitle: args?.title,
          lines: args == null
              ? null
              : <String>[
                  '${args.leadCount} leads · ${args.scope.displayName}',
                  '${args.resultCount} results · ${args.withEmail} with email · '
                      '${args.withPhone} with phone',
                  if (args.leadIds.isNotEmpty)
                    'Ids: ${args.leadIds.take(3).join(', ')}',
                ],
        );
      },
    ),
    GoRoute(
      path: AppRoutes.pro,
      name: AppRoutes.proName,
      parentNavigatorKey: rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) =>
          const PlaceholderScreen(title: 'ClientHunt Pro'),
    ),
    // Debug-only: the component gallery never ships in a release build. It is
    // registered outside the shell so it has no bottom navigation.
    if (kDebugMode)
      GoRoute(
        path: AppRoutes.designGallery,
        name: AppRoutes.designGalleryName,
        parentNavigatorKey: rootNavigatorKey,
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
/// points at these so every route can be exercised today. [lines] lets a
/// placeholder show the payload it was handed (Export does this for its
/// `ExportArgs`).
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    required this.title,
    this.subtitle,
    this.lines,
    super.key,
  });

  final String title;
  final String? subtitle;

  /// Extra facts rendered under the subtitle.
  final List<String>? lines;

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
              if (lines != null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                for (final String line in lines!)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(
                      line,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySm.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: AppSpacing.md),
              Text(
                CommonStrings.placeholderCaption,
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
