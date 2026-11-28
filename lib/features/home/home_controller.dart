import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/ads/ad_coordinator.dart';
import '../../domain/catalogs/city_catalog.dart';
import '../../domain/catalogs/niche_catalog.dart';
import '../../domain/entitlements/entitlements.dart';
import '../../domain/entitlements/feature_gate.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/lead_search_engine.dart';
import '../../domain/repositories/location_service.dart';
import 'home_state.dart';

/// Where a submission stands. The page switches on this to decide whether to
/// show the opt-in dialog, navigate, or stay put.
enum HomeSubmitStage {
  /// The form is not valid; nothing happened.
  invalid,

  /// A submission or ad flow is already running.
  inFlight,

  /// Today's free searches are used up; open the paywall.
  quotaExhausted,

  /// Free user: show the rewarded opt-in dialog, then call
  /// [HomeController.confirmRewarded].
  needsRewardedPrompt,

  /// Cleared to search: navigate to Results with [HomeSubmitResult.request].
  ready,

  /// The user closed the rewarded ad early; stay on Home.
  cancelled,
}

/// Result of [HomeController.start] or [HomeController.confirmRewarded].
class HomeSubmitResult {
  const HomeSubmitResult(this.stage, {this.request, this.reason});

  /// What happened.
  final HomeSubmitStage stage;

  /// The request to hand to Results, for [HomeSubmitStage.ready].
  final SearchRequest? request;

  /// The paywall reason, for [HomeSubmitStage.quotaExhausted].
  final LockReason? reason;

  @override
  String toString() => 'HomeSubmitResult(${stage.name})';
}

/// Outcome of the \"use my location\" button.
enum HomeLocationOutcome {
  /// The city was filled in.
  found,

  /// Permission was declined; show a snackbar.
  denied,

  /// Services off or no fix; show a snackbar.
  unavailable,

  /// A lookup is already running.
  busy,
}

/// What happened when a source chip was tapped.
enum SourceToggleResult {
  /// It became selected.
  selected,

  /// It became deselected.
  deselected,

  /// It is Pro-only; open the paywall with `LockReason.sourceRequiresPro`.
  locked,

  /// It was the last selected source, so it stayed selected.
  lastSelected,
}

/// The Home form's state machine.
///
/// Home is a *form*, not a search: it validates, checks the quota and gates a
/// rewarded ad, then hands a [SearchRequest] to Results. It never consumes a
/// search and never writes history — B2 does both, and only when a search
/// completes with at least one lead.
///
/// The state survives tab switches because the shell keeps the branch alive and
/// this provider is not auto-disposed; only an app restart resets it.
class HomeController extends Notifier<HomeState> {
  @override
  HomeState build() {
    // Read once, not watched: a settings emission must never wipe a half-typed
    // form. B1 does not change settings while Home is alive.
    final AppSettings settings =
        ref.read(settingsProvider).value ?? const AppSettings();
    final Entitlements entitlements = ref
        .read(featureGateProvider)
        .entitlements;

    // Entitlements arrive from a stream. If Home builds before that first value
    // (a cold start), the form starts on Free — the safe default — and this
    // listener widens the cap once the real plan lands, without touching anything
    // the user has already typed or chosen.
    ref.listen<AsyncValue<Entitlements>>(entitlementsProvider, (
      AsyncValue<Entitlements>? previous,
      AsyncValue<Entitlements> next,
    ) {
      final Entitlements? entitlements = next.value;
      if (entitlements == null) {
        return;
      }
      final int cap = entitlements.maxResultsPerSearch;
      state = state.copyWith(
        maxResultsCap: cap,
        filters: state.filters.activeFilterCount == 0
            ? state.filters.copyWith(
                maxResults: state.preferredMaxResults.clamp(25, cap).toInt(),
              )
            : state.filters.copyWith(
                maxResults: state.filters.maxResults.clamp(25, cap).toInt(),
              ),
      );
    });

    final Set<LeadSource> allowed = <LeadSource>{
      for (final LeadSource source in settings.defaultSources)
        if (source != LeadSource.web &&
            entitlements.allowedSources.contains(source))
          source,
    };

    return HomeState(
      niche: '',
      location: '',
      // A saved default the plan no longer allows falls back to Maps, so the form
      // can never start on a Pro-only source for a Free user.
      sources: allowed.isEmpty ? <LeadSource>{LeadSource.maps} : allowed,
      filters: SearchFilters(
        maxResults: settings.maxResults
            .clamp(25, entitlements.maxResultsPerSearch)
            .toInt(),
        dedupe: settings.dedupe,
        skipSaved: settings.skipSaved,
      ),
      defaultCountry: settings.defaultCountry,
      maxResultsCap: entitlements.maxResultsPerSearch,
      preferredMaxResults: settings.maxResults,
    );
  }

  /// Updates the niche text.
  void setNiche(String value) => state = state.copyWith(niche: value);

  /// Updates the city text.
  void setLocation(String value) => state = state.copyWith(location: value);

  /// Fills a field from a suggestion or a popular chip; the value is the
  /// canonical catalog name.
  void applySuggestion(String value, {required bool isNiche}) {
    state = isNiche
        ? state.copyWith(niche: value)
        : state.copyWith(location: value);
  }

  /// Selects, deselects or refuses a source according to the gate.
  SourceToggleResult toggleSource(LeadSource source) {
    final FeatureGate gate = ref.read(featureGateProvider);
    if (!gate.canUseSource(source)) {
      return SourceToggleResult.locked;
    }
    if (state.sources.contains(source)) {
      if (state.sources.length == 1) {
        return SourceToggleResult.lastSelected;
      }
      state = state.copyWith(
        sources: <LeadSource>{...state.sources}..remove(source),
      );
      return SourceToggleResult.deselected;
    }
    state = state.copyWith(sources: <LeadSource>{...state.sources, source});
    return SourceToggleResult.selected;
  }

  /// Flips one quick toggle in the shared [SearchFilters].
  void toggleQuick(HomeQuickFilter filter) {
    state = state.copyWith(
      filters: switch (filter) {
        HomeQuickFilter.email => state.filters.copyWith(
          hasEmail: !state.filters.hasEmail,
        ),
        HomeQuickFilter.phone => state.filters.copyWith(
          hasPhone: !state.filters.hasPhone,
        ),
        HomeQuickFilter.website => state.filters.copyWith(
          hasWebsite: !state.filters.hasWebsite,
        ),
      },
    );
  }

  /// Applies the filters the Filters screen returned, clamped to the plan.
  void applyFilters(SearchFilters filters) {
    state = state.copyWith(
      filters: filters.copyWith(
        maxResults: filters.maxResults.clamp(25, state.maxResultsCap).toInt(),
      ),
    );
  }

  /// Resolves the device city and fills the field.
  ///
  /// Never throws: a denied permission and a failed fix are ordinary outcomes
  /// the page turns into a snackbar.
  Future<HomeLocationOutcome> useCurrentLocation() async {
    if (state.isLocating) {
      return HomeLocationOutcome.busy;
    }
    state = state.copyWith(isLocating: true);
    try {
      final LocationResult result = await ref
          .read(locationServiceProvider)
          .currentCity();
      if (!ref.mounted) {
        return HomeLocationOutcome.unavailable;
      }
      switch (result) {
        case LocationFound(:final String city):
          state = state.copyWith(
            location: CityCatalog.normalize(city),
            isLocating: false,
          );
          return HomeLocationOutcome.found;
        case LocationPermissionDenied():
          state = state.copyWith(isLocating: false);
          return HomeLocationOutcome.denied;
        case LocationUnavailable():
          state = state.copyWith(isLocating: false);
          return HomeLocationOutcome.unavailable;
      }
    } catch (_) {
      state = state.copyWith(isLocating: false);
      return HomeLocationOutcome.unavailable;
    }
  }

  /// Builds the request Results will run.
  ///
  /// Niche and city are normalized through the catalogs, so \"dental clinic\" and
  /// \"Bombay\" become \"Dentists\" and \"Mumbai\"; values are trimmed; the result
  /// count is clamped to the plan.
  SearchRequest buildRequest({String? id}) {
    final String niche = NicheCatalog.normalize(state.niche);
    final String location = CityCatalog.normalize(state.location);
    return SearchRequest(
      id: id ?? 'search-${DateTime.now().microsecondsSinceEpoch}',
      query: SearchQuery(
        niches: <String>[niche],
        locations: <String>[location],
        sources: state.sources,
        country: state.defaultCountry,
      ),
      filters: state.filters.copyWith(maxResults: state.effectiveMaxResults),
    );
  }

  /// Whether another search is allowed today, from the live quota count.
  HomeQuotaStatus quotaStatus(int? remainingToday) {
    final Entitlements entitlements = ref
        .read(featureGateProvider)
        .entitlements;
    final int? limit = entitlements.freeSearchesPerDay;
    if (limit == null) {
      return HomeQuotaStatus.unlimited;
    }
    if (remainingToday == null) {
      // The stream has not emitted yet: do not block a legitimate search on a
      // loading counter.
      return HomeQuotaStatus.available;
    }
    return remainingToday > 0
        ? HomeQuotaStatus.available
        : HomeQuotaStatus.exhausted;
  }

  /// First half of Find Leads: validate, check the quota, and either hand back a
  /// request (Pro) or ask the page to show the rewarded opt-in dialog.
  ///
  /// Sets [HomeState.isSubmitting] while the dialog/ad flow runs, which disables
  /// the button and blocks a double submit.
  Future<HomeSubmitResult> start() async {
    if (state.isSubmitting) {
      return const HomeSubmitResult(HomeSubmitStage.inFlight);
    }
    if (!state.canSearch) {
      return const HomeSubmitResult(HomeSubmitStage.invalid);
    }

    final FeatureGate gate = ref.read(featureGateProvider);
    final int? remaining = ref.read(remainingSearchesProvider).value;
    if (quotaStatus(remaining) == HomeQuotaStatus.exhausted) {
      return const HomeSubmitResult(
        HomeSubmitStage.quotaExhausted,
        reason: LockReason.dailySearchLimitReached,
      );
    }

    final SearchRequest request = buildRequest();

    // Pro (or a plan without ads) goes straight to Results, no dialog, no ad.
    if (gate.entitlements.isPro || !gate.entitlements.adsEnabled) {
      ref.read(adPolicyProvider).recordUserAction();
      return HomeSubmitResult(HomeSubmitStage.ready, request: request);
    }

    state = state.copyWith(isSubmitting: true);
    return HomeSubmitResult(
      HomeSubmitStage.needsRewardedPrompt,
      request: request,
    );
  }

  /// Second half: play the rewarded ad and decide whether to proceed.
  ///
  /// A missing ad never blocks (the coordinator returns `skippedNoAd`, which is
  /// treated as proceed); a user who closes early stays on Home.
  Future<HomeSubmitResult> confirmRewarded() async {
    final SearchRequest request = buildRequest();
    final AdGateResult gate = await ref
        .read(adCoordinatorProvider)
        .runRewardedGate();

    switch (gate) {
      case AdGateResult.proceed:
      case AdGateResult.skippedNoAd:
        ref.read(adPolicyProvider).recordUserAction();
        state = state.copyWith(isSubmitting: false);
        return HomeSubmitResult(HomeSubmitStage.ready, request: request);
      case AdGateResult.cancelledByUser:
        state = state.copyWith(isSubmitting: false);
        return const HomeSubmitResult(HomeSubmitStage.cancelled);
    }
  }

  /// Releases the in-flight guard (dialog cancelled, paywall opened, page left).
  void cancelSubmission() {
    if (state.isSubmitting) {
      state = state.copyWith(isSubmitting: false);
    }
  }

  /// Re-runs a past search through the same submit flow.
  ///
  /// The stored query fills the fields, sources are filtered by the current gate,
  /// and the current filters stay as they are.
  Future<HomeSubmitResult> rerun(SearchHistoryEntry entry) {
    final FeatureGate gate = ref.read(featureGateProvider);
    final Set<LeadSource> sources = <LeadSource>{
      for (final LeadSource source in entry.query.sources)
        if (gate.canUseSource(source)) source,
    };
    state = state.copyWith(
      niche: entry.query.niches.isEmpty ? '' : entry.query.niches.first,
      location: entry.query.locations.isEmpty
          ? ''
          : entry.query.locations.first,
      sources: sources.isEmpty ? <LeadSource>{LeadSource.maps} : sources,
    );
    return start();
  }

  /// Clears the Recent list.
  Future<void> clearRecent() =>
      ref.read(searchHistoryRepositoryProvider).clear();
}

/// The Home form state.
final NotifierProvider<HomeController, HomeState> homeControllerProvider =
    NotifierProvider<HomeController, HomeState>(HomeController.new);
