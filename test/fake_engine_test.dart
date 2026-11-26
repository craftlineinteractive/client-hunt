import 'package:clienthunt/data/fake/fake.dart';
import 'package:clienthunt/domain/models/models.dart';
import 'package:clienthunt/domain/repositories/repositories.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Results screen is written against this sequence, so the sequence is
/// asserted: Started → Progress → PartialResults → Completed, with the right
/// terminal event for empty, error and cancel.
void main() {
  const SearchRequest request = SearchRequest(
    id: 'search-1',
    query: SearchQuery(
      niches: <String>['Dentists'],
      locations: <String>['Ahmedabad'],
    ),
  );

  FakeLeadSearchEngine engineFor(FakeScenario scenario) => FakeLeadSearchEngine(
    scenario: scenario,
    searchLatency: Duration.zero,
    data: DummyData.build(now: DateTime(2026, 11, 26, 9)),
  );

  test(
    'normal run emits started, progress, partial results and completed',
    () async {
      final List<SearchEvent> events = await engineFor(
        FakeScenario.normal,
      ).search(request).toList();

      expect(events.first, isA<SearchStarted>());
      expect(events.last, isA<SearchCompleted>());

      final List<SearchProgress> progress = events
          .whereType<SearchProgress>()
          .toList();
      expect(progress.length, greaterThanOrEqualTo(2));
      expect(
        progress.map((SearchProgress event) => event.stage),
        containsAllInOrder(<SearchStage>[
          SearchStage.querying,
          SearchStage.parsing,
          SearchStage.validating,
        ]),
      );
      expect(progress.last.leadsFoundSoFar, 42);

      final List<SearchPartialResults> partial = events
          .whereType<SearchPartialResults>()
          .toList();
      expect(partial, hasLength(1));
      expect(partial.single.leads, hasLength(12));
      expect(partial.single.foundSoFar, 12);

      // Nothing failed before completion.
      expect(events.whereType<SearchFailed>(), isEmpty);
    },
  );

  test('the completed summary carries the 42 / 31 / 40 counts', () async {
    // A tiny non-zero latency so the reported duration is meaningful.
    final FakeLeadSearchEngine engine = FakeLeadSearchEngine(
      searchLatency: const Duration(milliseconds: 1),
      data: DummyData.build(now: DateTime(2026, 11, 26, 9)),
    );
    final List<SearchEvent> events = await engine.search(request).toList();

    final SearchSummary summary = events
        .whereType<SearchCompleted>()
        .single
        .summary;
    expect(summary.total, 42);
    expect(summary.withEmail, 31);
    expect(summary.withPhone, 40);
    expect(summary.perSource[LeadSource.maps]?.status, SourceStatus.done);
    expect(summary.perSource[LeadSource.maps]?.leadsFound, 42);
    expect(summary.duration, greaterThan(Duration.zero));
  });

  test('empty scenario ends in noResults', () async {
    final List<SearchEvent> events = await engineFor(
      FakeScenario.empty,
    ).search(request).toList();

    expect(events.first, isA<SearchStarted>());
    expect(events.whereType<SearchCompleted>(), isEmpty);
    final SearchFailed failure = events.whereType<SearchFailed>().single;
    expect(failure.error.type, SearchErrorType.noResults);
    expect(failure.error.message, isNotEmpty);
  });

  test('no-network scenario ends in noNetwork', () async {
    final List<SearchEvent> events = await engineFor(
      FakeScenario.errorNoNetwork,
    ).search(request).toList();

    expect(events.first, isA<SearchStarted>());
    expect(events.whereType<SearchProgress>(), isEmpty);
    final SearchFailed failure = events.whereType<SearchFailed>().single;
    expect(failure.error.type, SearchErrorType.noNetwork);
    expect(events.whereType<SearchCompleted>(), isEmpty);
  });

  test('rate-limit scenario ends in rateLimited after one stage', () async {
    final List<SearchEvent> events = await engineFor(
      FakeScenario.errorRateLimited,
    ).search(request).toList();

    expect(events.whereType<SearchProgress>(), hasLength(2));
    final SearchFailed failure = events.whereType<SearchFailed>().single;
    expect(failure.error.type, SearchErrorType.rateLimited);
  });

  test('partial scenario completes with the blocked source reported', () async {
    const SearchRequest socialRequest = SearchRequest(
      id: 'search-2',
      query: SearchQuery(
        niches: <String>['Dentists'],
        locations: <String>['Ahmedabad'],
        sources: <LeadSource>{LeadSource.maps, LeadSource.instagram},
      ),
    );

    final List<SearchEvent> events = await engineFor(
      FakeScenario.partialSourceBlocked,
    ).search(socialRequest).toList();

    final SearchSummary summary = events
        .whereType<SearchCompleted>()
        .single
        .summary;
    expect(summary.total, 42);
    expect(summary.perSource[LeadSource.maps]?.status, SourceStatus.done);
    expect(
      summary.perSource[LeadSource.instagram]?.status,
      SourceStatus.blocked,
    );
  });

  test('maxResults caps the run', () async {
    const SearchRequest capped = SearchRequest(
      id: 'search-3',
      query: SearchQuery(
        niches: <String>['Dentists'],
        locations: <String>['Ahmedabad'],
      ),
      filters: SearchFilters(maxResults: 25),
    );

    final List<SearchEvent> events = await engineFor(
      FakeScenario.normal,
    ).search(capped).toList();

    expect(events.whereType<SearchCompleted>().single.summary.total, 25);
    expect(
      events.whereType<SearchPartialResults>().single.leads,
      hasLength(12),
    );
  });

  test('cancel emits a cancelled failure', () async {
    final FakeLeadSearchEngine engine = engineFor(FakeScenario.normal);
    await engine.cancel('search-1');

    final List<SearchEvent> events = await engine.search(request).toList();

    expect(events.first, isA<SearchStarted>());
    expect(events.whereType<SearchCompleted>(), isEmpty);
    expect(
      events.whereType<SearchFailed>().single.error.type,
      SearchErrorType.cancelled,
    );
  });
}
