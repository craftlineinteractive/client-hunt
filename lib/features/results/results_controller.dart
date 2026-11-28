import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/constants/app_strings.dart';
import '../../domain/ads/ad_policy.dart';
import '../../domain/entitlements/feature_gate.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/results/results_filter.dart';
import 'lead_session.dart';
import 'results_state.dart';

/// One-shot things the screen must do but the controller must not.
///
/// The controller never touches a `BuildContext`, a snackbar or the navigator:
/// it emits an event and the page performs it. That keeps every rule testable
/// without a widget tree.
sealed class ResultsUiEvent {
  const ResultsUiEvent();
}

/// Show a snackbar with [text].
final class ResultsMessage extends ResultsUiEvent {
  const ResultsMessage(this.text);

  final String text;
}

/// Open the paywall with [reason] (a `LockReason` name).
final class ResultsOpenPro extends ResultsUiEvent {
  const ResultsOpenPro(this.reason);

  final String reason;
}

/// The user left the screen at a natural break; the page shows the interstitial.
final class ResultsAdBreak extends ResultsUiEvent {
  const ResultsAdBreak(this.trigger);

  final AdTrigger trigger;
}

/// Drives one Results screen.
///
/// Scoped per [SearchRequest] so two results screens (a retry pushed behind the
/// first, for example) can never share or overwrite each other's run.
///
/// **Quota and history belong to this controller**, because only it knows when a
/// run truly completed: one free search is spent and one history entry written
/// when — and only when — `SearchCompleted` arrives with `total >= 1`, exactly
/// once per search id ([_finalisedSearchIds]). A failed, cancelled, empty or
/// zero-lead run spends nothing and records nothing.
class ResultsController extends Notifier<ResultsState> {
  ResultsController(this.request);

  /// The request the route was opened with.
  final SearchRequest request;

  final StreamController<ResultsUiEvent> _events =
      StreamController<ResultsUiEvent>.broadcast();

  /// Search ids whose completion has already been applied. The idempotency
  /// mechanism: a duplicate `SearchCompleted`, a rebuilt screen or a late event
  /// from a cancelled run can never spend a second search or write a second
  /// history entry.
  final Set<String> _finalisedSearchIds = <String>{};

  StreamSubscription<SearchEvent>? _searchSubscription;
  StreamSubscription<List<Lead>>? _savedSubscription;
  LeadSearchEngine? _engine;

  /// Id of the run that has not ended yet, or `null`.
  String? _activeSearchId;
  bool _disposed = false;
  int _run = 0;

  /// One-shot events; the page subscribes in `initState`.
  Stream<ResultsUiEvent> get events => _events.stream;

  @override
  ResultsState build() {
    ref.onDispose(_onDispose);
    _subscribeToSavedLeads();

    final ResultsState initial = ResultsState(
      request: request,
      searchId: request.id,
      activeFilters: request.filters,
      sort: request.filters.sortBy,
    );
    _startSearch(initial.searchId, request.filters);
    // The session is published by the first event, not here: a Notifier may not
    // modify another provider while it is building.
    return initial;
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Starts a new run of the same query with a new search id.
  ///
  /// The previous subscription is cancelled first, so a slow batch from the old
  /// run can never land in the new one. Quota follows the normal rule: a retry
  /// that completes with leads spends a search like any other.
  void retry() {
    _searchSubscription?.cancel();
    _searchSubscription = null;
    _run++;
    final String searchId = '${request.id}#$_run';

    final ResultsState next = ResultsState(
      request: request,
      searchId: searchId,
      activeFilters: state.activeFilters,
      sort: state.sort,
      filter: state.filter,
      isNoteDismissed: state.isNoteDismissed,
      savedIds: state.savedIds,
    );
    _set(next);
    _publishSession(next, LeadSessionStatus.searching);
    _startSearch(searchId, state.activeFilters);
  }

  /// Cancels a running search. The page then leaves the screen.
  Future<void> cancel() async {
    if (!state.isRunning) {
      return;
    }
    final String searchId = state.searchId;
    _activeSearchId = null;
    await _searchSubscription?.cancel();
    _searchSubscription = null;
    _set(state.copyWith(phase: ResultsPhase.cancelled));
    _publishSession(state, LeadSessionStatus.cancelled);
    try {
      await ref.read(leadSearchEngineProvider).cancel(searchId);
    } catch (error) {
      debugPrint('[results] cancel failed: $error');
    }
  }

  /// Called when the screen is being removed.
  ///
  /// While a search is running the run is cancelled silently and **no ad** is
  /// requested. Otherwise this records one completed user action and asks the
  /// page for an interstitial at `AdTrigger.resultsClosed`.
  void leave() {
    if (state.isRunning) {
      unawaited(cancel());
      return;
    }
    ref.read(adPolicyProvider).recordUserAction();
    _emit(const ResultsAdBreak(AdTrigger.resultsClosed));
  }

  /// Selects or deselects one lead.
  void toggleSelect(String leadId) {
    final Set<String> next = <String>{...state.selectedIds};
    if (!next.remove(leadId)) {
      next.add(leadId);
    }
    _set(state.copyWith(selectedIds: next));
  }

  /// Selects every currently visible lead, or clears when all are selected.
  ///
  /// Hidden leads keep whatever selection they had: the checkbox is about what
  /// the user can see.
  void selectAllVisible() {
    if (state.allVisibleSelected) {
      _set(state.copyWith(selectedIds: const <String>{}));
      return;
    }
    _set(
      state.copyWith(
        selectedIds: <String>{
          ...state.selectedIds,
          for (final Lead lead in state.visibleLeads) lead.id,
        },
      ),
    );
  }

  /// Drops the selection.
  void clearSelection() => _set(state.copyWith(selectedIds: const <String>{}));

  /// Applies a chip.
  void setChip(ResultsChip chip) =>
      _set(state.copyWith(filter: state.filter.copyWith(chip: chip)));

  /// Applies a text query.
  void setQuery(String text) =>
      _set(state.copyWith(filter: state.filter.copyWith(text: text)));

  /// Shows or hides the inline search field; hiding clears the query.
  void setSearchMode(bool isSearchMode) {
    _set(
      state.copyWith(
        isSearchMode: isSearchMode,
        filter: isSearchMode ? state.filter : state.filter.copyWith(text: ''),
      ),
    );
  }

  /// Replaces the query with an empty one.
  void clearQuery() =>
      _set(state.copyWith(filter: state.filter.copyWith(text: '')));

  /// Applies an ordering.
  void setSort(SortOption sort) => _set(state.copyWith(sort: sort));

  /// Dismisses the unverified-emails note for this session.
  void dismissNote() => _set(state.copyWith(isNoteDismissed: true));

  /// Applies the filters returned by the Filters screen.
  ///
  /// Contact presence, rating, reviews and keywords are re-applied to the leads
  /// already received. Anything that changes what the engine searches for
  /// (open status, depth, result cap, cleanup flags) sets [ResultsState
  /// .filtersChanged], and the screen offers "Search again".
  void applyFilters(SearchFilters filters) {
    _set(
      state.copyWith(
        activeFilters: filters,
        filtersChanged: _needsNewSearch(state.activeFilters, filters),
      ),
    );
  }

  /// Clears the chip and the text query — the local-empty action.
  void clearLocalFilters() =>
      _set(state.copyWith(filter: const ResultsFilter()));

  /// Saves or unsaves a lead, respecting the plan's saved-lead cap.
  ///
  /// A save past the cap opens the paywall through [ResultsOpenPro]; the page
  /// performs the navigation, so this stays testable.
  Future<void> toggleSave(Lead lead) async {
    final LeadRepositoryWriter writer = LeadRepositoryWriter(
      repository: ref.read(leadRepositoryProvider),
      gate: ref.read(featureGateProvider),
    );
    final LeadSaveOutcome outcome = await writer.toggle(lead);
    switch (outcome) {
      case LeadSaveOutcome.saved:
        _emit(const ResultsMessage(ResultsStrings.savedToast));
      case LeadSaveOutcome.unsaved:
        _emit(const ResultsMessage(ResultsStrings.unsavedToast));
      case LeadSaveOutcome.limitReached:
        _emit(ResultsOpenPro(LockReason.savedLeadLimitReached.name));
    }
  }

  // ---------------------------------------------------------------------------
  // Search events
  // ---------------------------------------------------------------------------

  void _startSearch(String searchId, SearchFilters filters) {
    final LeadSearchEngine engine = ref.read(leadSearchEngineProvider);
    _engine = engine;
    _activeSearchId = searchId;
    final SearchRequest runRequest = SearchRequest(
      id: searchId,
      query: request.query,
      filters: filters,
    );
    _searchSubscription = engine
        .search(runRequest)
        .listen(
          _onEvent,
          onError: (Object error) {
            _onEvent(
              SearchFailed(
                searchId: searchId,
                error: SearchError(
                  type: SearchErrorType.unknown,
                  message: error.toString(),
                ),
              ),
            );
          },
        );
  }

  void _onEvent(SearchEvent event) {
    if (_disposed) {
      return;
    }
    // A late event from a replaced run is never applied.
    if (event.searchId != state.searchId) {
      return;
    }
    switch (event) {
      case SearchStarted(:final List<LeadSource> sources):
        _set(
          state.copyWith(
            phase: state.leads.isEmpty
                ? ResultsPhase.searching
                : ResultsPhase.partial,
            sources: sources,
            sourceStatuses: <LeadSource, SourceStatus>{
              for (final LeadSource source in sources)
                source: state.sourceStatuses[source] ?? SourceStatus.pending,
            },
          ),
        );
      case SearchProgress(
        :final SearchStage stage,
        :final Map<LeadSource, SourceStatus> sourceStatuses,
        :final int leadsFoundSoFar,
      ):
        _set(
          state.copyWith(
            phase: state.leads.isEmpty
                ? ResultsPhase.searching
                : ResultsPhase.partial,
            stage: stage,
            sourceStatuses: sourceStatuses.isEmpty
                ? state.sourceStatuses
                : sourceStatuses,
            foundSoFar: leadsFoundSoFar > state.foundSoFar
                ? leadsFoundSoFar
                : state.foundSoFar,
          ),
        );
      case SearchPartialResults(:final List<Lead> leads, :final int foundSoFar):
        _appendLeads(leads, foundSoFar: foundSoFar);
      case SearchCompleted(:final SearchSummary summary):
        _complete(summary);
      case SearchFailed(:final SearchError error):
        _fail(error);
    }
  }

  void _appendLeads(List<Lead> batch, {required int foundSoFar}) {
    final Set<String> known = <String>{
      for (final Lead lead in state.leads) lead.id,
    };
    final List<Lead> merged = <Lead>[...state.leads];
    for (final Lead lead in batch) {
      if (known.add(lead.id)) {
        merged.add(lead);
      }
    }
    final ResultsState next = state.copyWith(
      leads: List<Lead>.unmodifiable(merged),
      foundSoFar: foundSoFar > merged.length ? foundSoFar : merged.length,
      phase: ResultsPhase.partial,
    );
    _set(next);
    _publishSession(next, LeadSessionStatus.partial);
  }

  void _complete(SearchSummary summary) {
    if (state.phase == ResultsPhase.completed ||
        state.phase == ResultsPhase.empty) {
      return;
    }
    final bool isFirstCompletion = _finalisedSearchIds.add(state.searchId);
    _activeSearchId = null;
    final ResultsState next = state.copyWith(
      phase: summary.total > 0 ? ResultsPhase.completed : ResultsPhase.empty,
      summary: summary,
      foundSoFar: summary.total,
      clearError: true,
    );
    _set(next);
    _publishSession(
      next,
      summary.total > 0 ? LeadSessionStatus.completed : LeadSessionStatus.empty,
    );

    // The one place a search is spent and recorded. A duplicate completion, a
    // rebuild or a late event fails this guard and changes nothing.
    if (!isFirstCompletion || summary.total < 1) {
      return;
    }
    unawaited(_recordCompletedSearch(summary));
  }

  Future<void> _recordCompletedSearch(SearchSummary summary) async {
    try {
      await ref.read(quotaRepositoryProvider).consumeOne();
      await ref
          .read(searchHistoryRepositoryProvider)
          .add(
            SearchHistoryEntry(
              id: 'history-${state.searchId}',
              query: request.query,
              resultCount: summary.total,
              searchedAt: DateTime.now(),
            ),
          );
    } catch (error) {
      // A counter write failing must never invalidate results the user can see.
      debugPrint('[results] could not record the completed search: $error');
    }
  }

  void _fail(SearchError error) {
    final ResultsPhase phase = switch (error.type) {
      SearchErrorType.cancelled => ResultsPhase.cancelled,
      SearchErrorType.noResults => ResultsPhase.empty,
      _ => ResultsPhase.failed,
    };
    _activeSearchId = null;
    final ResultsState next = state.copyWith(phase: phase, error: error);
    _set(next);
    _publishSession(next, switch (phase) {
      ResultsPhase.cancelled => LeadSessionStatus.cancelled,
      ResultsPhase.empty => LeadSessionStatus.empty,
      _ => LeadSessionStatus.failed,
    });
  }

  // ---------------------------------------------------------------------------
  // Plumbing
  // ---------------------------------------------------------------------------

  /// True when [next] changes anything the engine must re-run for.
  static bool _needsNewSearch(SearchFilters current, SearchFilters next) {
    return current.openStatus != next.openStatus ||
        current.depth != next.depth ||
        current.maxResults != next.maxResults ||
        current.dedupe != next.dedupe ||
        current.skipSaved != next.skipSaved ||
        current.removeInvalidPhones != next.removeInvalidPhones ||
        current.groupByCity != next.groupByCity;
  }

  void _subscribeToSavedLeads() {
    _savedSubscription = ref
        .read(leadRepositoryProvider)
        .watchSavedLeads()
        .listen(
          (List<Lead> leads) {
            if (_disposed) {
              return;
            }
            _set(
              state.copyWith(
                savedIds: <String>{for (final Lead lead in leads) lead.id},
              ),
            );
          },
          onError: (Object error) =>
              debugPrint('[results] saved-lead watch failed: $error'),
        );
  }

  void _publishSession(ResultsState next, LeadSessionStatus status) {
    if (_disposed) {
      return;
    }
    ref
        .read(leadSessionProvider.notifier)
        .set(
          LeadSession(
            request: SearchRequest(
              id: next.searchId,
              query: request.query,
              filters: next.activeFilters,
            ),
            leads: next.leads,
            summary: next.summary,
            status: status,
          ),
        );
  }

  void _set(ResultsState next) {
    if (_disposed) {
      return;
    }
    state = next;
  }

  void _emit(ResultsUiEvent event) {
    if (!_events.isClosed) {
      _events.add(event);
    }
  }

  void _onDispose() {
    _disposed = true;
    _searchSubscription?.cancel();
    _searchSubscription = null;
    _savedSubscription?.cancel();
    _savedSubscription = null;
    _events.close();

    // The screen is gone while a search is still running: stop the work, not
    // just our subscription, so a slow source is not left crawling.
    final String? runningId = _activeSearchId;
    final LeadSearchEngine? engine = _engine;
    _activeSearchId = null;
    if (runningId != null && engine != null) {
      unawaited(
        engine.cancel(runningId).catchError((Object error) {
          debugPrint('[results] could not cancel $runningId: $error');
        }),
      );
    }
  }
}

/// Result of a bookmark toggle.
enum LeadSaveOutcome { saved, unsaved, limitReached }

/// Applies the save/unsave rule without a widget tree.
///
/// Split out so the cap behaviour is unit-testable and Results stays a thin
/// caller. The repository is the only writer; the cap comes from the gate.
class LeadRepositoryWriter {
  const LeadRepositoryWriter({required this.repository, required this.gate});

  final LeadRepository repository;
  final FeatureGate gate;

  Future<LeadSaveOutcome> toggle(Lead lead) async {
    if (lead.isSaved) {
      await repository.deleteLeads(<String>[lead.id]);
      return LeadSaveOutcome.unsaved;
    }
    final int savedCount = await repository.savedCount();
    if (!gate.canSaveMore(savedCount)) {
      return LeadSaveOutcome.limitReached;
    }
    await repository.saveLead(lead);
    return LeadSaveOutcome.saved;
  }
}

/// One controller per request.
///
/// Keyed by the whole [SearchRequest] (which has value equality), so a rebuild of
/// the same route resolves to the same run instead of starting a second one.
final resultsControllerProvider =
    NotifierProvider.family<ResultsController, ResultsState, SearchRequest>(
      ResultsController.new,
    );
