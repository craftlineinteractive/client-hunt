import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/lead_search_engine.dart';

/// How the latest search session ended (or has not ended yet).
enum LeadSessionStatus {
  /// The engine is running and no leads are ready.
  searching,

  /// Some leads are ready; the run is still going.
  partial,

  /// The run finished with at least one lead.
  completed,

  /// The run finished with no leads.
  empty,

  /// The run failed.
  failed,

  /// The user cancelled.
  cancelled,
}

/// **The latest search session, held in memory.**
///
/// Results produces it; Lead Detail consumes it. It exists so a lead can be
/// opened by id from Results *or* from Saved without either screen handing over a
/// whole object — and without Results having to stay mounted.
///
/// It is a snapshot, not a store: nothing is persisted, and a cold start has no
/// session. `leadByIdProvider` handles that by falling back to
/// `LeadRepository`.
class LeadSession {
  const LeadSession({
    required this.request,
    this.leads = const <Lead>[],
    this.summary,
    this.status = LeadSessionStatus.searching,
  });

  /// The request that produced this session.
  final SearchRequest request;

  /// Every lead found, in engine order, including partial batches.
  final List<Lead> leads;

  /// Final totals, once the engine completes.
  final SearchSummary? summary;

  /// Where the run is.
  final LeadSessionStatus status;

  /// The query title ("Dentists in Ahmedabad").
  String get title => request.query.displayTitle;

  /// One lead of this session, or `null` when the id is not in it.
  Lead? leadById(String id) {
    for (final Lead lead in leads) {
      if (lead.id == id) {
        return lead;
      }
    }
    return null;
  }

  /// Copy with selected fields replaced.
  LeadSession copyWith({
    SearchRequest? request,
    List<Lead>? leads,
    SearchSummary? summary,
    LeadSessionStatus? status,
  }) {
    return LeadSession(
      request: request ?? this.request,
      leads: leads ?? this.leads,
      summary: summary ?? this.summary,
      status: status ?? this.status,
    );
  }
}

/// Holds the latest session.
///
/// Written by `ResultsController` only; read by [leadByIdProvider] and, in B3, by
/// Lead Detail. Replacing the session for a new search id makes the previous run
/// unreachable by id, which is intended: Results is the only screen that offers
/// those leads, and it keeps them in its own state.
class LeadSessionController extends Notifier<LeadSession?> {
  @override
  LeadSession? build() => null;

  /// Starts a fresh session for [request], dropping the previous one.
  void start(SearchRequest request) {
    state = LeadSession(request: request);
  }

  /// Replaces the whole session.
  void set(LeadSession? session) => state = session;

  /// Replaces the leads and status of the current session.
  ///
  /// Ignored when there is no session, or when the write names a different
  /// search id — a late batch from a cancelled run must never leak into the new
  /// one.
  void record({
    required String searchId,
    List<Lead>? leads,
    SearchSummary? summary,
    LeadSessionStatus? status,
  }) {
    final LeadSession? current = state;
    if (current == null || current.request.id != searchId) {
      return;
    }
    state = current.copyWith(leads: leads, summary: summary, status: status);
  }

  /// Forgets the session.
  void clear() => state = null;
}

/// The latest search session, or `null` before the first search.
final NotifierProvider<LeadSessionController, LeadSession?>
leadSessionProvider = NotifierProvider<LeadSessionController, LeadSession?>(
  LeadSessionController.new,
);

/// Resolves a lead by id: the current session first, then the saved store.
///
/// Lead Detail (B3) opens `/lead/:id` and calls this. Session first means the
/// card the user tapped is exactly what they see, even before a save; the
/// repository fallback means a saved lead still opens after a restart, when no
/// session exists.
// The family's type is internal to Riverpod 3; the inferred type is what callers
// see, and `ref.watch(leadByIdProvider(id))` gives an `AsyncValue<Lead?>`.
final leadByIdProvider = FutureProvider.family<Lead?, String>((
  Ref ref,
  String id,
) async {
  final Lead? fromSession = ref.watch(leadSessionProvider)?.leadById(id);
  if (fromSession != null) {
    return fromSession;
  }
  return ref.watch(leadRepositoryProvider).getLead(id);
});
