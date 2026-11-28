import 'package:flutter/foundation.dart';

import '../../domain/models/models.dart';
import '../../domain/repositories/lead_search_engine.dart';
import '../../domain/results/results_filter.dart';

/// Where a Results screen is in its lifecycle.
enum ResultsPhase {
  /// Running, nothing ready yet: the skeleton and progress card.
  searching,

  /// Running, but leads have started to arrive.
  partial,

  /// Finished with at least one lead.
  completed,

  /// Finished with no leads (the engine found nothing, or filters hide all).
  empty,

  /// Failed. Leads received before the failure stay visible.
  failed,

  /// The user cancelled the run.
  cancelled,
}

/// The result set, the selection and the client-side view controls.
///
/// One immutable value per frame. Everything the screen draws is derived here so
/// a widget test can assert counts without parsing the widget tree, and the
/// controller never holds UI state of its own.
@immutable
class ResultsState {
  const ResultsState({
    required this.request,
    required this.searchId,
    this.phase = ResultsPhase.searching,
    this.stage,
    this.sources = const <LeadSource>[],
    this.sourceStatuses = const <LeadSource, SourceStatus>{},
    this.leads = const <Lead>[],
    this.foundSoFar = 0,
    this.summary,
    this.error,
    this.selectedIds = const <String>{},
    this.sort = SortOption.relevance,
    this.filter = const ResultsFilter(),
    this.activeFilters = const SearchFilters(),
    this.isSearchMode = false,
    this.isNoteDismissed = false,
    this.savedIds = const <String>{},
    this.filtersChanged = false,
  });

  /// The request the screen was opened with.
  final SearchRequest request;

  /// Id of the run currently on screen. A retry replaces it.
  final String searchId;

  /// Lifecycle phase.
  final ResultsPhase phase;

  /// Current pipeline stage, once the engine reports one.
  final SearchStage? stage;

  /// Sources this run attempts, in display order.
  final List<LeadSource> sources;

  /// Live per-source state.
  final Map<LeadSource, SourceStatus> sourceStatuses;

  /// Every lead received so far, in engine order, without duplicates.
  final List<Lead> leads;

  /// How many leads the engine says it has found (may lead [leads] by a batch).
  final int foundSoFar;

  /// Final totals, once the engine completes.
  final SearchSummary? summary;

  /// Terminal failure, when there was one.
  final SearchError? error;

  /// Selected lead ids. Selection survives filtering, so Export never loses a
  /// lead the user ticked and then narrowed away from.
  final Set<String> selectedIds;

  /// Current ordering.
  final SortOption sort;

  /// Chip plus text query.
  final ResultsFilter filter;

  /// Filters currently in force. Updated by the Filters screen; some of them need
  /// a new search, which is what [filtersChanged] reports.
  final SearchFilters activeFilters;

  /// True while the inline search field replaces the title.
  final bool isSearchMode;

  /// True once the \"Emails are unverified\" note is dismissed, for this session.
  final bool isNoteDismissed;

  /// Ids of every saved lead, watched from the repository.
  final Set<String> savedIds;

  /// True when the last Filters change needs a new search.
  final bool filtersChanged;

  /// True while the engine is running.
  bool get isRunning =>
      phase == ResultsPhase.searching || phase == ResultsPhase.partial;

  /// True when anything narrows the visible list.
  bool get isFiltered => filter.isActive || _hasLocalFilters;

  /// Leads after local filters, the chip/text filter and the sort.
  List<Lead> get visibleLeads {
    final Iterable<Lead> locally = activeFilters.hasActiveChanges
        ? leads.where((Lead lead) => matchesLocalFilters(lead, activeFilters))
        : leads;
    return ResultsSort.apply(filter.apply(locally, savedIds: savedIds), sort);
  }

  /// Leads in the result set: the final total, or what has arrived.
  int get totalCount => summary?.total ?? leads.length;

  /// Leads with at least one email: final count, or live.
  int get withEmailCount =>
      summary?.withEmail ?? leads.where((Lead lead) => lead.hasEmail).length;

  /// Leads with at least one phone: final count, or live.
  int get withPhoneCount =>
      summary?.withPhone ?? leads.where((Lead lead) => lead.hasPhone).length;

  /// How many leaves are visible right now.
  int get visibleCount => visibleLeads.length;

  /// How many leads are selected.
  int get selectedCount => selectedIds.length;

  /// True when something is selected.
  bool get hasSelection => selectedIds.isNotEmpty;

  /// True when every visible lead is selected (and there is at least one).
  bool get allVisibleSelected {
    final List<Lead> visible = visibleLeads;
    return visible.isNotEmpty &&
        visible.every((Lead lead) => selectedIds.contains(lead.id));
  }

  /// The selected leads that still exist in the result set.
  List<Lead> get selectedLeads => <Lead>[
    for (final Lead lead in leads)
      if (selectedIds.contains(lead.id)) lead,
  ];

  /// True when a source was blocked or failed — the partial-failure note.
  bool get hasSourceProblem {
    final Map<LeadSource, SourceResult> perSource =
        summary?.perSource ?? const <LeadSource, SourceResult>{};
    if (perSource.values.any(
      (SourceResult result) =>
          result.status == SourceStatus.blocked ||
          result.status == SourceStatus.failed,
    )) {
      return true;
    }
    return sourceStatuses.values.any(
      (SourceStatus status) =>
          status == SourceStatus.blocked || status == SourceStatus.failed,
    );
  }

  /// True when a completed search reached [cap] leads.
  ///
  /// The caller decides *whether* to show the note: Pro has a different cap and
  /// never sees it.
  bool reachedCap(int cap) =>
      phase == ResultsPhase.completed && totalCount >= cap;

  /// True when the engine finished without leads (as opposed to filters hiding
  /// them).
  bool get engineReturnedNothing => phase == ResultsPhase.empty;

  bool get _hasLocalFilters => activeFilters.hasActiveChanges;

  /// Copy with selected fields replaced.
  ///
  /// Pass [clearError] to drop a previous failure: `null` cannot express \"clear\"
  /// for a nullable field.
  ResultsState copyWith({
    String? searchId,
    ResultsPhase? phase,
    SearchStage? stage,
    List<LeadSource>? sources,
    Map<LeadSource, SourceStatus>? sourceStatuses,
    List<Lead>? leads,
    int? foundSoFar,
    SearchSummary? summary,
    SearchError? error,
    bool clearError = false,
    Set<String>? selectedIds,
    SortOption? sort,
    ResultsFilter? filter,
    SearchFilters? activeFilters,
    bool? isSearchMode,
    bool? isNoteDismissed,
    Set<String>? savedIds,
    bool? filtersChanged,
  }) {
    return ResultsState(
      request: request,
      searchId: searchId ?? this.searchId,
      phase: phase ?? this.phase,
      stage: stage ?? this.stage,
      sources: sources ?? this.sources,
      sourceStatuses: sourceStatuses ?? this.sourceStatuses,
      leads: leads ?? this.leads,
      foundSoFar: foundSoFar ?? this.foundSoFar,
      summary: summary ?? this.summary,
      error: clearError ? null : (error ?? this.error),
      selectedIds: selectedIds ?? this.selectedIds,
      sort: sort ?? this.sort,
      filter: filter ?? this.filter,
      activeFilters: activeFilters ?? this.activeFilters,
      isSearchMode: isSearchMode ?? this.isSearchMode,
      isNoteDismissed: isNoteDismissed ?? this.isNoteDismissed,
      savedIds: savedIds ?? this.savedIds,
      filtersChanged: filtersChanged ?? this.filtersChanged,
    );
  }
}
