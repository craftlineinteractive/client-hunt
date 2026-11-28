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
///
/// Results are delivered in **batches of eight** rather than all at once, so
/// progressive rendering and "the list does not jump" can be checked. Each batch
/// costs a quarter of the stage latency, so the total stays close to the old
/// single-batch run.
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

  /// Leads per partial batch.
  static const int _batchSize = 8;

  Duration get _latency =>
      scenario == FakeScenario.slow ? searchLatency * 3 : searchLatency;

  Duration get _batchLatency => _latency ~/ 4;

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

    if (scenario == FakeScenario.emptyCompleted) {
      statuses[LeadSource.maps] = SourceStatus.done;
      yield SearchProgress(
        searchId: request.id,
        stage: SearchStage.deduplicating,
        sourceStatuses: Map<LeadSource, SourceStatus>.unmodifiable(statuses),
      );
      yield SearchCompleted(
        searchId: request.id,
        summary: SearchSummary(
          total: 0,
          withEmail: 0,
          withPhone: 0,
          duration: _latency * 2,
          perSource: const <LeadSource, SourceResult>{
            LeadSource.maps: SourceResult(status: SourceStatus.done),
          },
        ),
      );
      return;
    }

    // The large scenario deliberately ignores the result cap: its only job is a
    // 200-row list for performance checks.
    final List<Lead> leads = scenario == FakeScenario.large
        ? _data.largeResults
        : _data.dentistResults
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

    // Batches of eight, so the list grows visibly and the screen can keep its
    // scroll position while rows append.
    int sent = 0;
    while (sent < leads.length) {
      final List<Lead> batch = leads
          .skip(sent)
          .take(_batchSize)
          .toList(growable: false);
      sent += batch.length;
      yield SearchPartialResults(
        searchId: request.id,
        leads: batch,
        foundSoFar: sent,
      );

      await Future<void>.delayed(_batchLatency);
      if (_cancelled.contains(request.id)) {
        yield _cancelledEvent(request.id);
        return;
      }

      if (sent == _batchSize && sent < leads.length) {
        yield SearchProgress(
          searchId: request.id,
          stage: SearchStage.enriching,
          sourceStatuses: Map<LeadSource, SourceStatus>.unmodifiable(statuses),
          leadsFoundSoFar: leads.length,
        );
      }
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
