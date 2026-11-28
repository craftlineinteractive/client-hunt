import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/export_args.dart';
import '../../domain/models/search_filters.dart';
import '../../domain/repositories/lead_search_engine.dart';

/// **Every route path and name in one place.**
///
/// Nothing outside this file may build a location string. Screens call the
/// helpers in [AppNavigator], which are typed and therefore cannot drift from
/// these constants.
///
/// Route shape:
/// * **Shell routes** — `/search`, `/saved`, `/settings`. They live inside the
///   `StatefulShellRoute` in `app_router.dart`, so each tab keeps its own
///   navigation state and the bottom bar stays visible.
/// * **Pushed routes** — `/results`, `/lead/:id`, `/filters`, `/export`, `/pro`.
///   They go on the root navigator and cover the shell, bottom bar included.
/// * **Debug route** — `/dev/gallery`, registered only in debug builds.
abstract final class AppRoutes {
  // Tab destinations (inside the shell).
  static const String search = '/search';
  static const String searchName = 'search';

  static const String saved = '/saved';
  static const String savedName = 'saved';

  static const String settings = '/settings';
  static const String settingsName = 'settings';

  // Pushed, full-screen destinations (root navigator).
  static const String results = '/results';
  static const String resultsName = 'results';

  /// `/lead/:id` — the lead id is the path parameter.
  static const String leadDetail = '/lead/:id';
  static const String leadDetailName = 'leadDetail';

  /// Location of one lead's detail screen.
  static String leadDetailPath(String leadId) => '/lead/$leadId';

  static const String filters = '/filters';
  static const String filtersName = 'filters';

  static const String exportLeads = '/export';
  static const String exportLeadsName = 'exportLeads';

  static const String pro = '/pro';
  static const String proName = 'pro';

  // Debug only.
  static const String designGallery = '/dev/gallery';
  static const String designGalleryName = 'designGallery';

  /// The three tab locations, in bottom-navigation order.
  static const List<String> tabLocations = <String>[search, saved, settings];
}

/// Typed navigation helpers.
///
/// Every screen uses these instead of raw `context.push('/…')`, so a path change
/// is a single edit in [AppRoutes]. Back-stack behaviour is part of the contract:
///
/// * results → back returns to Search (results is pushed from Search);
/// * lead detail → back returns to whatever pushed it (results or saved);
/// * filters / export / pro → back (or close) returns to the screen that opened
///   them, which is still mounted underneath;
/// * Android system back follows exactly the same stack — no route overrides
///   `pop`.
abstract final class AppNavigator {
  const AppNavigator._();

  /// Pushes the results screen for a search.
  ///
  /// The [SearchRequest] is the route `extra`, so Results runs exactly the query
  /// Home built (normalized niche and city, chosen sources, filters, capped
  /// result count) instead of reconstructing it. A restored route has no extra,
  /// so Results must handle `null` with a safe message rather than crash.
  static Future<void> goToResults(
    BuildContext context, {
    SearchRequest? request,
  }) {
    return context.push<void>(AppRoutes.results, extra: request);
  }

  /// Pushes the detail screen for [leadId].
  static Future<void> goToLead(BuildContext context, String leadId) {
    return context.push<void>(AppRoutes.leadDetailPath(leadId));
  }

  /// Pushes the filters screen and resolves with the applied filters, or `null`
  /// when the user closed it without applying.
  static Future<SearchFilters?> openFilters(
    BuildContext context, {
    SearchFilters? initial,
  }) {
    return context.push<SearchFilters>(AppRoutes.filters, extra: initial);
  }

  /// Pushes the export screen with the selection Results built.
  ///
  /// [args] is the route `extra`. It is optional so the export screen can still
  /// be exercised on its own; with no extra it falls back to its own empty state.
  static Future<void> openExport(BuildContext context, {ExportArgs? args}) {
    return context.push<void>(AppRoutes.exportLeads, extra: args);
  }

  /// Pushes the paywall. The optional [reason] lets the paywall open scrolled to
  /// the feature that triggered it; it is carried as `extra`.
  static Future<void> openPro(BuildContext context, {String? reason}) {
    return context.push<void>(AppRoutes.pro, extra: reason);
  }

  /// Opens the debug component gallery (debug builds only).
  static Future<void> openDesignGallery(BuildContext context) {
    return context.push<void>(AppRoutes.designGallery);
  }

  /// Switches to a tab destination. Using `go` keeps the shell (and therefore
  /// each tab's state) alive.
  static void goToTab(BuildContext context, String location) {
    assert(
      AppRoutes.tabLocations.contains(location),
      '$location is not a tab location',
    );
    context.go(location);
  }
}
