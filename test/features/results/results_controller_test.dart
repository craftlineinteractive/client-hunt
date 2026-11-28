import 'dart:async';

import 'package:clienthunt/app/providers.dart';
import 'package:clienthunt/core/constants/app_strings.dart';
import 'package:clienthunt/data/fake/fake.dart';
import 'package:clienthunt/domain/ads/ad_policy.dart';
import 'package:clienthunt/domain/entitlements/entitlements.dart';
import 'package:clienthunt/domain/entitlements/feature_gate.dart';
import 'package:clienthunt/domain/models/models.dart';
import 'package:clienthunt/domain/repositories/repositories.dart';
import 'package:clienthunt/domain/results/results_filter.dart';
import 'package:clienthunt/features/results/lead_session.dart';
import 'package:clienthunt/features/results/results_controller.dart';
import 'package:clienthunt/features/results/results_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The rules Results owns: search-event handling, the completion rule, quota and
/// history, selection, saving and the leave/ad contract.
///
/// These run against the fake engine and the fakes' in-memory repositories, with
/// no widget tree, so a failure points at the controller rather than at a layout.
void main() {
  final DateTime now = DateTime(2026, 11, 26, 9);
  final DummyDataSet data = DummyData.build(now: now);

  SearchRequest makeRequest({String id = 'search-1', SearchFilters? filters}) {
    return SearchRequest(
      id: id,
      query: const SearchQuery(
        niches: <String>['Dentists'],
        locations: <String>['Ahmedabad'],
      ),
      filters: filters ?? const SearchFilters(),
    );
  }

  /// A repository seeded with a chosen number of saved leads, so the saved cap
  /// can be reached without saving 50 leads in a test.
  FakeLeadRepository repositoryWithSaved(int count) {
    return FakeLeadRepository(
      data: DummyDataSet(
        dentistResults: data.dentistResults,
        largeResults: data.largeResults,
        savedLeads: data.savedLeads.take(count).toList(),
        lists: const <LeadList>[],
        recentSearches: data.recentSearches,
        searchesRemainingToday: data.searchesRemainingToday,
      ),
      latency: Duration.zero,
    );
  }

  ProviderContainer makeContainer({
    LeadSearchEngine? engine,
    bool isPro = false,
    int savedLeads = 3,
    FakeQuotaRepository? quota,
    FakeSearchHistoryRepository? history,
  }) {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        leadSearchEngineProvider.overrideWithValue(
          engine ??
              FakeLeadSearchEngine(searchLatency: Duration.zero, data: data),
        ),
        leadRepositoryProvider.overrideWithValue(
          repositoryWithSaved(savedLeads),
        ),
        quotaRepositoryProvider.overrideWithValue(
          quota ?? FakeQuotaRepository(latency: Duration.zero),
        ),
        searchHistoryRepositoryProvider.overrideWithValue(
          history ??
              FakeSearchHistoryRepository(data: data, latency: Duration.zero),
        ),
        entitlementsProvider.overrideWith(
          (Ref ref) => Stream<Entitlements>.value(
            isPro ? proEntitlements : freeEntitlements,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Lets the stream, the quota write and the history write run to completion.
  Future<void> settle([int rounds = 12]) async {
    for (int index = 0; index < rounds; index++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  /// Keeps the auto-dispose controller alive the way the screen's `ref.watch`
  /// does, then hands back its notifier.
  ResultsController start(ProviderContainer container, SearchRequest request) {
    container.listen(resultsControllerProvider(request), (_, _) {});
    return container.read(resultsControllerProvider(request).notifier);
  }

  test('a normal run completes with the 42 / 31 / 40 counts', () async {
    final ProviderContainer container = makeContainer();
    final request = makeRequest();

    start(container, request);
    await settle();

    final ResultsState state = container.read(
      resultsControllerProvider(request),
    );
    expect(state.phase, ResultsPhase.completed);
    expect(state.leads, hasLength(42));
    expect(state.totalCount, 42);
    expect(state.withEmailCount, 31);
    expect(state.withPhoneCount, 40);
    expect(state.foundSoFar, 42);
    expect(state.sources, <LeadSource>[LeadSource.maps]);
    expect(state.sourceStatuses[LeadSource.maps], SourceStatus.done);
    expect(state.visibleLeads, hasLength(42));
  });

  test('completion spends one search and writes one history entry', () async {
    final FakeQuotaRepository quota = FakeQuotaRepository(
      latency: Duration.zero,
    );
    final FakeSearchHistoryRepository history = FakeSearchHistoryRepository(
      data: data,
      latency: Duration.zero,
    );
    final ProviderContainer container = makeContainer(
      quota: quota,
      history: history,
    );
    final request = makeRequest();

    start(container, request);
    await settle();

    expect(quota.remainingToday, 2);
    final List<SearchHistoryEntry> recent = await history.watchRecent().first;
    expect(recent.first.query.displayTitle, 'Dentists in Ahmedabad');
    expect(recent.first.resultCount, 42);

    // A duplicate SearchCompleted for the same id changes nothing.
    final _ScriptedEngine duplicate = _ScriptedEngine(<SearchEvent>[
      SearchCompleted(searchId: 'search-1', summary: _summary(42)),
      SearchCompleted(searchId: 'search-1', summary: _summary(42)),
    ]);
    final ProviderContainer twice = makeContainer(
      engine: duplicate,
      quota: quota,
      history: history,
    );
    final SearchRequest duplicateRequest = makeRequest();
    start(twice, duplicateRequest);
    await settle();
    // The first container already spent one; the duplicate run must spend one
    // more at most, never two.
    expect(quota.remainingToday, 1);
  });

  test(
    'an empty completed search spends nothing and writes no history',
    () async {
      final FakeQuotaRepository quota = FakeQuotaRepository(
        latency: Duration.zero,
      );
      final FakeSearchHistoryRepository history = FakeSearchHistoryRepository(
        data: data,
        latency: Duration.zero,
      );
      final ProviderContainer container = makeContainer(
        engine: FakeLeadSearchEngine(
          scenario: FakeScenario.emptyCompleted,
          searchLatency: Duration.zero,
          data: data,
        ),
        quota: quota,
        history: history,
      );
      final request = makeRequest();

      start(container, request);
      await settle();

      final ResultsState state = container.read(
        resultsControllerProvider(request),
      );
      expect(state.phase, ResultsPhase.empty);
      expect(quota.remainingToday, 3);
      expect((await history.watchRecent().first), hasLength(2));
    },
  );

  test('a failed search spends nothing and writes no history', () async {
    final FakeQuotaRepository quota = FakeQuotaRepository(
      latency: Duration.zero,
    );
    final FakeSearchHistoryRepository history = FakeSearchHistoryRepository(
      data: data,
      latency: Duration.zero,
    );
    final ProviderContainer container = makeContainer(
      engine: FakeLeadSearchEngine(
        scenario: FakeScenario.errorNoNetwork,
        searchLatency: Duration.zero,
        data: data,
      ),
      quota: quota,
      history: history,
    );
    final request = makeRequest();

    start(container, request);
    await settle();

    final ResultsState state = container.read(
      resultsControllerProvider(request),
    );
    expect(state.phase, ResultsPhase.failed);
    expect(state.error?.type, SearchErrorType.noNetwork);
    expect(quota.remainingToday, 3);
    expect((await history.watchRecent().first), hasLength(2));
  });

  test('a cancelled search spends nothing and keeps no leads', () async {
    final FakeQuotaRepository quota = FakeQuotaRepository(
      latency: Duration.zero,
    );
    final ProviderContainer container = makeContainer(
      engine: _ScriptedEngine(const <SearchEvent>[
        SearchStarted(
          searchId: 'search-1',
          sources: <LeadSource>[LeadSource.maps],
        ),
        SearchProgress(
          searchId: 'search-1',
          stage: SearchStage.querying,
          sourceStatuses: <LeadSource, SourceStatus>{
            LeadSource.maps: SourceStatus.running,
          },
        ),
        SearchFailed(
          searchId: 'search-1',
          error: SearchError(
            type: SearchErrorType.cancelled,
            message: 'Search cancelled.',
          ),
        ),
      ]),
      quota: quota,
    );
    final request = makeRequest();

    start(container, request);
    await settle();

    final ResultsState state = container.read(
      resultsControllerProvider(request),
    );
    expect(state.phase, ResultsPhase.cancelled);
    expect(state.leads, isEmpty);
    expect(quota.remainingToday, 3);
  });

  test('partial batches never duplicate a lead', () async {
    final List<Lead> leads = data.dentistResults.take(4).toList();
    final ProviderContainer container = makeContainer(
      engine: _ScriptedEngine(<SearchEvent>[
        SearchPartialResults(
          searchId: 'search-1',
          leads: leads.take(2).toList(),
          foundSoFar: 2,
        ),
        SearchPartialResults(searchId: 'search-1', leads: leads, foundSoFar: 4),
        SearchCompleted(searchId: 'search-1', summary: _summary(4)),
      ]),
    );
    final request = makeRequest();

    start(container, request);
    await settle();

    final ResultsState state = container.read(
      resultsControllerProvider(request),
    );
    expect(state.leads.map((Lead lead) => lead.id).toSet(), hasLength(4));
    expect(state.leads, hasLength(4));
    expect(state.phase, ResultsPhase.completed);
  });

  test(
    'a failure after partial results keeps them and shows the error',
    () async {
      final List<Lead> leads = data.dentistResults.take(2).toList();
      final ProviderContainer container = makeContainer(
        engine: _ScriptedEngine(<SearchEvent>[
          SearchPartialResults(
            searchId: 'search-1',
            leads: leads,
            foundSoFar: 2,
          ),
          const SearchFailed(
            searchId: 'search-1',
            error: SearchError(
              type: SearchErrorType.rateLimited,
              message: 'Slow down.',
            ),
          ),
        ]),
      );
      final request = makeRequest();

      start(container, request);
      await settle();

      final ResultsState state = container.read(
        resultsControllerProvider(request),
      );
      expect(state.phase, ResultsPhase.failed);
      expect(state.leads, hasLength(2));
      expect(state.error?.type, SearchErrorType.rateLimited);
    },
  );

  test('retry cancels the old run and starts a new search id', () async {
    final FakeLeadSearchEngine engine = FakeLeadSearchEngine(
      searchLatency: Duration.zero,
      data: data,
    );
    final ProviderContainer container = makeContainer(engine: engine);
    final request = makeRequest();

    start(container, request);
    await settle();
    final int seenBeforeRetry = engine.seenRequests.length;

    container.read(resultsControllerProvider(request).notifier).retry();
    await settle();

    final ResultsState state = container.read(
      resultsControllerProvider(request),
    );
    expect(engine.seenRequests.length, seenBeforeRetry + 1);
    expect(engine.seenRequests.last.id, state.searchId);
    expect(state.searchId, isNot(request.id));
    expect(state.phase, ResultsPhase.completed);
    expect(state.leads, hasLength(42));
  });

  test(
    'saving past the Free cap emits the Pro event and saves nothing',
    () async {
      final ProviderContainer container = makeContainer(savedLeads: 50);
      final request = makeRequest();
      final ResultsController controller = start(container, request);
      final List<ResultsUiEvent> events = <ResultsUiEvent>[];
      final StreamSubscription<ResultsUiEvent> subscription = controller.events
          .listen(events.add);
      addTearDown(subscription.cancel);
      await settle();

      final Lead unsaved = data.dentistResults.firstWhere(
        (Lead lead) => !lead.isSaved,
      );
      await controller.toggleSave(unsaved);
      await settle();

      expect(events.whereType<ResultsOpenPro>(), hasLength(1));
      expect(
        events.whereType<ResultsOpenPro>().single.reason,
        LockReason.savedLeadLimitReached.name,
      );
    },
  );

  test('saving under the cap saves and announces it', () async {
    final ProviderContainer container = makeContainer(savedLeads: 2);
    final request = makeRequest();
    final ResultsController controller = start(container, request);
    final List<ResultsUiEvent> events = <ResultsUiEvent>[];
    final StreamSubscription<ResultsUiEvent> subscription = controller.events
        .listen(events.add);
    addTearDown(subscription.cancel);
    await settle();

    final Lead unsaved = data.dentistResults.firstWhere(
      (Lead lead) => !lead.isSaved,
    );
    await controller.toggleSave(unsaved);
    await settle();

    expect(
      events.whereType<ResultsMessage>().single.text,
      ResultsStrings.savedToast,
    );

    // The saved ids updated from the repository stream, so the Saved chip sees it.
    final ResultsState state = container.read(
      resultsControllerProvider(request),
    );
    expect(state.savedIds, contains(unsaved.id));
  });

  test('select all applies to visible leads only', () async {
    final ProviderContainer container = makeContainer();
    final request = makeRequest();
    final ResultsController controller = start(container, request);
    await settle();

    controller.setChip(ResultsChip.website);
    await settle();
    final ResultsState filtered = container.read(
      resultsControllerProvider(request),
    );
    expect(filtered.visibleCount, lessThan(42));

    controller.selectAllVisible();
    await settle();
    final ResultsState selected = container.read(
      resultsControllerProvider(request),
    );
    expect(selected.selectedCount, filtered.visibleCount);
    expect(selected.hasSelection, isTrue);
    expect(selected.allVisibleSelected, isTrue);
    for (final String id in selected.selectedIds) {
      expect(filtered.visibleLeads.any((Lead lead) => lead.id == id), isTrue);
    }

    controller.selectAllVisible();
    await settle();
    expect(container.read(resultsControllerProvider(request)).selectedCount, 0);
  });

  test(
    'applyFilters applies local filters and flags the search-only ones',
    () async {
      final ProviderContainer container = makeContainer();
      final request = makeRequest();
      final ResultsController controller = start(container, request);
      await settle();

      // A local-only change: minimum rating.
      controller.applyFilters(const SearchFilters(minRating: 4.5));
      await settle();
      ResultsState state = container.read(resultsControllerProvider(request));
      expect(state.filtersChanged, isFalse);
      expect(state.visibleCount, lessThan(42));
      expect(
        state.visibleLeads.every((Lead lead) => (lead.rating ?? 0) >= 4.5),
        isTrue,
      );

      // A change the engine must re-run for.
      controller.applyFilters(const SearchFilters(maxResults: 25));
      await settle();
      state = container.read(resultsControllerProvider(request));
      expect(state.filtersChanged, isTrue);
    },
  );

  test('dispose cancels a running search', () async {
    final _ScriptedEngine engine = _ScriptedEngine(const <SearchEvent>[
      SearchStarted(
        searchId: 'search-1',
        sources: <LeadSource>[LeadSource.maps],
      ),
    ]);
    final ProviderContainer container = makeContainer(engine: engine);
    final request = makeRequest();

    start(container, request);
    await settle();
    expect(engine.cancelled, isEmpty);

    container.dispose();
    await settle();
    expect(engine.cancelled, contains('search-1'));
  });

  test(
    'leaving after completion asks for an interstitial; a running search does not',
    () async {
      final ProviderContainer container = makeContainer();
      final request = makeRequest();
      final ResultsController controller = start(container, request);
      final List<ResultsUiEvent> events = <ResultsUiEvent>[];
      final StreamSubscription<ResultsUiEvent> subscription = controller.events
          .listen(events.add);
      addTearDown(subscription.cancel);
      await settle();

      controller.leave();
      await settle();
      expect(events.whereType<ResultsAdBreak>(), hasLength(1));
      expect(
        events.whereType<ResultsAdBreak>().single.trigger,
        AdTrigger.resultsClosed,
      );

      // A fresh controller that is still searching must not ask for an ad.
      final _ScriptedEngine engine = _ScriptedEngine(<SearchEvent>[]);
      final ProviderContainer running = makeContainer(engine: engine);
      final SearchRequest second = makeRequest(id: 'search-running');
      final ResultsController runningController = start(running, second);
      final List<ResultsUiEvent> runningEvents = <ResultsUiEvent>[];
      final StreamSubscription<ResultsUiEvent> runningSubscription =
          runningController.events.listen(runningEvents.add);
      addTearDown(runningSubscription.cancel);
      await settle();
      runningController.leave();
      await settle();

      expect(runningEvents.whereType<ResultsAdBreak>(), isEmpty);
      expect(
        running.read(resultsControllerProvider(second)).phase,
        ResultsPhase.cancelled,
      );
      expect(engine.cancelled, contains('search-running'));
    },
  );

  test('the lead session follows the run and resolves leads by id', () async {
    final ProviderContainer container = makeContainer();
    final request = makeRequest();

    start(container, request);
    await settle();

    final LeadSession? session = container.read(leadSessionProvider);
    expect(session, isNotNull);
    expect(session!.status, LeadSessionStatus.completed);
    expect(session.leads, hasLength(42));
    expect(session.leadById(data.dentistResults.first.id), isNotNull);
    expect(session.leadById('nope'), isNull);
  });
}

SearchSummary _summary(int total) => SearchSummary(
  total: total,
  withEmail: total,
  withPhone: total,
  duration: Duration.zero,
);

/// An engine that replays a fixed event script, for duplicate and partial cases
/// the fake cannot produce.
class _ScriptedEngine implements LeadSearchEngine {
  _ScriptedEngine(this.script);

  final List<SearchEvent> script;
  final List<SearchRequest> seenRequests = <SearchRequest>[];
  final List<String> cancelled = <String>[];

  @override
  Stream<SearchEvent> search(SearchRequest request) async* {
    seenRequests.add(request);
    for (final SearchEvent event in script) {
      yield event;
    }
  }

  @override
  Future<void> cancel(String searchId) async {
    cancelled.add(searchId);
  }
}
