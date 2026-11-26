import '../../domain/models/models.dart';
import '../../domain/repositories/lead_search_engine.dart';
import 'dummy_data.dart';
import 'fake_scenario.dart';

/// A scripted [LeadSearchEngine].
///
/// It implements **no search logic at all**: it replays a plausible event
/// sequence over the dummy data so the Results screen can be built against real
/// progress, partial and failure states. The real engine arrives in prompt D and
/// replaces this class behind the same provider.
///
/// Latency defaults to 700 ms per stage (~2.8 s per search), which is long enough
/// to see the loading UI and short enough not to be annoying. [FakeScenario.slow]
/// triples it; the error scenarios fail after one stage.
class FakeLeadSearchEngine implements LeadSearchEngine {
  FakeLeadSearchEngine({
    this.scenario = FakeScenario.normal,
    this.searchLatency = const Duration(milliseconds: 700),
    DummyDataSet? data,
  }) : _data = data ?? DummyData.build();

  /// The scripted behaviour for the next search.
  final FakeScenario scenario;

  /// Base delay between events.
  final Duration searchLatency;

  final DummyDataSet _data;

  final Set<String> _cancelled = <String>{};

  Duration get _latency =>
      scenario == FakeScenario.slow ? searchLatency * 3 : searchLatency;

  @override
  Stream<SearchEvent> search(SearchRequest request) async* {
    final List<LeadSource> sources = request.query.sources.isEmpty
        ? const <LeadSource>[LeadSource.maps]
        : request.query.sources.toList();

    yield SearchStarted(searchId: request.id, sources: sources);

    if (scenario == FakeScenario.errorNoNetwork) {
      await Future<void>.delayed(_latency);
      yield SearchFailed(
        searchId: request.id,
        error: const SearchError(
          type: SearchErrorType.noNetwork,
          message: 'No connection. Check your network and try again.',
        ),
      );
      return;
    }

    final Map<LeadSource, SourceStatus> statuses = <LeadSource, SourceStatus>{
      for (final LeadSource source in sources) source: SourceStatus.pending,
      if (!sources.contains(LeadSource.maps))
        LeadSource.maps: SourceStatus.pending,
    }..[LeadSource.maps] = SourceStatus.running;

    yield SearchProgress(
      searchId: request.id,
      stage: SearchStage.querying,
      sourceStatuses: Map<LeadSource, SourceStatus>.unmodifiable(statuses),
    );

    await Future<void>.delayed(_latency);
    if (_cancelled.contains(request.id)) {
      yield _cancelledEvent(request.id);
      return;
    }

    if (scenario == FakeScenario.errorRateLimited) {
      statuses[LeadSource.maps] = SourceStatus.blocked;
      yield SearchProgress(
        searchId: request.id,
        stage: SearchStage.querying,
        sourceStatuses: Map<LeadSource, SourceStatus>.unmodifiable(statuses),
      );
      yield SearchFailed(
        searchId: request.id,
        error: const SearchError(
          type: SearchErrorType.rateLimited,
          message: 'Maps asked us to slow down. Try again in a minute.',
        ),
      );
      return;
    }

    if (scenario == FakeScenario.empty) {
      statuses[LeadSource.maps] = SourceStatus.done;
      yield SearchProgress(
        searchId: request.id,
        stage: SearchStage.deduplicating,
        sourceStatuses: Map<LeadSource, SourceStatus>.unmodifiable(statuses),
      );
      yield SearchFailed(
        searchId: request.id,
        error: const SearchError(
          type: SearchErrorType.noResults,
          message: 'No leads matched. Try a broader niche or area.',
        ),
      );
      return;
    }

    final List<Lead> leads = _data.dentistResults
        .take(request.filters.maxResults)
        .toList(growable: false);

    statuses[LeadSource.maps] = SourceStatus.done;
    for (final LeadSource source in statuses.keys) {
      if (source == LeadSource.maps) {
        continue;
      }
      statuses[source] = scenario == FakeScenario.partialSourceBlocked
          ? SourceStatus.blocked
          : SourceStatus.done;
    }

    yield SearchProgress(
      searchId: request.id,
      stage: SearchStage.parsing,
      sourceStatuses: Map<LeadSource, SourceStatus>.unmodifiable(statuses),
      leadsFoundSoFar: leads.length,
    );

    await Future<void>.delayed(_latency);
    if (_cancelled.contains(request.id)) {
      yield _cancelledEvent(request.id);
      return;
    }

    final List<Lead> firstBatch = leads.take(12).toList(growable: false);
    yield SearchPartialResults(
      searchId: request.id,
      leads: firstBatch,
      foundSoFar: firstBatch.length,
    );

    await Future<void>.delayed(_latency);
    if (_cancelled.contains(request.id)) {
      yield _cancelledEvent(request.id);
      return;
    }

    yield SearchProgress(
      searchId: request.id,
      stage: SearchStage.validating,
      sourceStatuses: Map<LeadSource, SourceStatus>.unmodifiable(statuses),
      leadsFoundSoFar: leads.length,
    );

    await Future<void>.delayed(_latency);
    if (_cancelled.contains(request.id)) {
      yield _cancelledEvent(request.id);
      return;
    }

    yield SearchCompleted(
      searchId: request.id,
      summary: SearchSummary(
        total: leads.length,
        withEmail: leads.where((Lead lead) => lead.hasEmail).length,
        withPhone: leads.where((Lead lead) => lead.hasPhone).length,
        duration: _latency * 4,
        perSource: <LeadSource, SourceResult>{
          for (final LeadSource source in statuses.keys)
            source: SourceResult(
              status: statuses[source]!,
              leadsFound: source == LeadSource.maps ? leads.length : 0,
              message: statuses[source] == SourceStatus.blocked
                  ? 'This source refused the request.'
                  : null,
            ),
        },
      ),
    );
  }

  SearchFailed _cancelledEvent(String searchId) => SearchFailed(
    searchId: searchId,
    error: const SearchError(
      type: SearchErrorType.cancelled,
      message: 'Search cancelled.',
    ),
  );

  @override
  Future<void> cancel(String searchId) async {
    _cancelled.add(searchId);
  }
}
