import 'package:flutter/foundation.dart';

import '../models/models.dart';

/// The pipeline stages a search passes through.
///
/// The Results screen maps these onto its progress copy ("Searching Maps…",
/// "Checking websites…"). A stage is a *label*, not a promise of duration: an
/// engine may skip one (a Maps-only fast search never enriches).
enum SearchStage {
  /// Asking each source for listings.
  querying,

  /// Normalizing names, categories and addresses.
  parsing,

  /// Opening business websites for emails and extra phones.
  enriching,

  /// Validating phone numbers, emails and duplicate candidates.
  validating,

  /// Merging duplicates across sources.
  deduplicating,
}

/// Per-source state during a search.
///
/// This is what lets the UI degrade gracefully: a blocked Instagram source marks
/// that chip `blocked` and finishes the search with Maps results instead of
/// failing the whole run.
enum SourceStatus {
  /// Not started yet.
  pending,

  /// In flight.
  running,

  /// Finished successfully.
  done,

  /// Not attempted because the plan does not include this source.
  skippedPro,

  /// The source refused the request (rate limit, auth wall, block).
  blocked,

  /// Tried and failed for another reason.
  failed,
}

/// How one source ended, for the summary the Results screen shows.
@immutable
class SourceResult {
  const SourceResult({required this.status, this.leadsFound = 0, this.message});

  /// Final state of the source.
  final SourceStatus status;

  /// Leads this source contributed.
  final int leadsFound;

  /// User-safe explanation, when the source did not finish cleanly.
  final String? message;

  @override
  String toString() =>
      'SourceResult(${status.name}, $leadsFound leads${message == null ? '' : ', $message'})';
}

/// Everything one search needs.
@immutable
class SearchRequest {
  const SearchRequest({
    required this.id,
    required this.query,
    this.filters = const SearchFilters(),
  });

  /// Idempotency key for this run; also used by [LeadSearchEngine.cancel].
  final String id;

  /// What to look for.
  final SearchQuery query;

  /// How to narrow it.
  final SearchFilters filters;

  /// Value equality, because Results scopes its controller per request: two
  /// builds of the same route must resolve to the same state, not start two
  /// searches.
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SearchRequest &&
            other.id == id &&
            other.query == query &&
            other.filters == filters;
  }

  @override
  int get hashCode => Object.hash(id, query, filters);

  @override
  String toString() => 'SearchRequest($id, ${query.displayTitle})';
}

/// Terminal failure categories. The UI chooses copy and retry affordance from
/// the type, never by parsing [SearchError.message].
enum SearchErrorType {
  /// The device is offline or the request never left.
  noNetwork,

  /// The source asked us to slow down.
  rateLimited,

  /// The source blocked the request.
  sourceBlocked,

  /// The search ran but produced nothing usable.
  noResults,

  /// The user cancelled.
  cancelled,

  /// Anything else.
  unknown,
}

/// A failure with a message safe to show the user.
@immutable
class SearchError {
  const SearchError({required this.type, required this.message});

  /// Category, for copy and retry logic.
  final SearchErrorType type;

  /// Short, user-facing explanation. Never contains a stack trace or a URL with
  /// a key in it.
  final String message;

  @override
  String toString() => 'SearchError(${type.name}: $message)';
}

/// The final numbers for a completed search.
@immutable
class SearchSummary {
  const SearchSummary({
    required this.total,
    required this.withEmail,
    required this.withPhone,
    required this.duration,
    this.perSource = const <LeadSource, SourceResult>{},
  });

  /// Leads returned.
  final int total;

  /// How many of them have at least one email.
  final int withEmail;

  /// How many of them have at least one phone.
  final int withPhone;

  /// Wall-clock time the search took.
  final Duration duration;

  /// Outcome per source that was attempted.
  final Map<LeadSource, SourceResult> perSource;

  @override
  String toString() => 'SearchSummary($total leads, $withEmail email)';
}

/// **What the engine tells the UI.**
///
/// A sealed hierarchy, so a `switch` over it is exhaustive: a screen cannot
/// forget to handle failure. The stream always ends with exactly one of
/// [SearchCompleted] or [SearchFailed].
///
/// Order for a normal run:
/// `SearchStarted` → one or more `SearchProgress` → `SearchPartialResults`
/// (zero or more) → `SearchCompleted`.
sealed class SearchEvent {
  const SearchEvent();

  /// The run this event belongs to; always equal to [SearchRequest.id].
  ///
  /// Hoisted onto the base class so a consumer can drop a late event from a
  /// replaced run with one check instead of one per subclass.
  String get searchId;
}

/// The run started; the Results screen can show its skeleton.
final class SearchStarted extends SearchEvent {
  const SearchStarted({required this.searchId, required this.sources});

  /// Matches [SearchRequest.id].
  @override
  final String searchId;

  /// Sources being attempted, in display order.
  final List<LeadSource> sources;

  @override
  String toString() => 'SearchStarted($searchId)';
}

/// A stage or per-source change.
final class SearchProgress extends SearchEvent {
  const SearchProgress({
    required this.searchId,
    required this.stage,
    this.sourceStatuses = const <LeadSource, SourceStatus>{},
    this.leadsFoundSoFar = 0,
  });

  /// Matches [SearchRequest.id].
  @override
  final String searchId;

  /// Current pipeline stage.
  final SearchStage stage;

  /// Current state of each source.
  final Map<LeadSource, SourceStatus> sourceStatuses;

  /// How many leads are known so far.
  final int leadsFoundSoFar;

  @override
  String toString() => 'SearchProgress(${stage.name}, $leadsFoundSoFar leads)';
}

/// Some leads are ready; the list can render while the rest arrives.
final class SearchPartialResults extends SearchEvent {
  const SearchPartialResults({
    required this.searchId,
    required this.leads,
    required this.foundSoFar,
  });

  /// Matches [SearchRequest.id].
  @override
  final String searchId;

  /// Leads ready at this point.
  final List<Lead> leads;

  /// Total known so far, including [leads] already rendered.
  final int foundSoFar;

  @override
  String toString() => 'SearchPartialResults(${leads.length} leads)';
}

/// The search finished successfully.
final class SearchCompleted extends SearchEvent {
  const SearchCompleted({required this.searchId, required this.summary});

  /// Matches [SearchRequest.id].
  @override
  final String searchId;

  /// Totals and per-source outcomes.
  final SearchSummary summary;

  @override
  String toString() => 'SearchCompleted(${summary.total} leads)';
}

/// The search stopped without a usable result set.
final class SearchFailed extends SearchEvent {
  const SearchFailed({required this.searchId, required this.error});

  /// Matches [SearchRequest.id].
  @override
  final String searchId;

  /// Why it failed, plus user-safe copy.
  final SearchError error;

  @override
  String toString() => 'SearchFailed(${error.type.name})';
}

/// Runs a search and reports progress.
///
/// Implemented by `FakeLeadSearchEngine` in development and by the real lead
/// engine in prompt D. The engine never touches widgets: it emits events, and the
/// Results screen decides how to render them.
abstract interface class LeadSearchEngine {
  /// Runs [request], emitting at least one event and ending with either
  /// [SearchCompleted] or [SearchFailed]. Cancelling the subscription cancels the
  /// work.
  Stream<SearchEvent> search(SearchRequest request);

  /// Stops a run started with [SearchRequest.id]. Emits
  /// [SearchFailed] with [SearchErrorType.cancelled] on that stream.
  Future<void> cancel(String searchId);
}
