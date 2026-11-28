import 'package:clienthunt/app/providers.dart';
import 'package:clienthunt/data/fake/fake.dart';
import 'package:clienthunt/domain/entitlements/entitlements.dart';
import 'package:clienthunt/domain/models/models.dart';
import 'package:clienthunt/domain/repositories/lead_search_engine.dart';
import 'package:clienthunt/domain/repositories/quota_repository.dart';
import 'package:clienthunt/domain/repositories/search_history_repository.dart';
import 'package:clienthunt/features/home/home_controller.dart';
import 'package:clienthunt/features/home/home_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records consumption so tests can prove Home never spends a search.
class _SpyQuota implements QuotaRepository {
  _SpyQuota(this.remaining);

  final int remaining;
  int consumeCalls = 0;

  @override
  Stream<int> watchRemainingToday() => Stream<int>.value(remaining);

  @override
  Future<int> consumeOne() async {
    consumeCalls++;
    return remaining - 1;
  }
}

/// Records history writes so tests can prove Home never adds an entry.
class _SpyHistory implements SearchHistoryRepository {
  int addCalls = 0;
  int clearCalls = 0;

  @override
  Stream<List<SearchHistoryEntry>> watchRecent({int limit = 10}) =>
      Stream<List<SearchHistoryEntry>>.value(const <SearchHistoryEntry>[]);

  @override
  Future<SearchHistoryEntry> add(SearchHistoryEntry entry) async {
    addCalls++;
    return entry;
  }

  @override
  Future<void> clear() async {
    clearCalls++;
  }
}

void main() {
  const FakeAdConfig instantAds = FakeAdConfig(
    loadDelay: Duration.zero,
    showDelay: Duration.zero,
    useTestAdPage: false,
  );

  Future<ProviderContainer> makeContainer({
    bool isPro = false,
    int remaining = 3,
    FakeAdConfig ads = instantAds,
    FakeLocationService? location,
    _SpyQuota? quota,
    _SpyHistory? history,
    AppSettings settings = const AppSettings(),
  }) async {
    final ProviderContainer container = ProviderContainer.test(
      overrides: [
        entitlementsProvider.overrideWith(
          (Ref ref) => Stream<Entitlements>.value(
            isPro ? proEntitlements : freeEntitlements,
          ),
        ),
        settingsProvider.overrideWith(
          (Ref ref) => Stream<AppSettings>.value(settings),
        ),
        quotaRepositoryProvider.overrideWithValue(
          quota ?? _SpyQuota(remaining),
        ),
        searchHistoryRepositoryProvider.overrideWithValue(
          history ?? _SpyHistory(),
        ),
        locationServiceProvider.overrideWithValue(
          location ?? FakeLocationService(delay: Duration.zero),
        ),
        adServiceProvider.overrideWithValue(FakeAdService(config: ads)),
      ],
    );
    // Providers are auto-disposed in Riverpod 3, so a bare read would drop the
    // value again before the next line. Subscribe first, then wait for the first
    // values so Home is built from the steady state, not the cold-start fallback.
    container
      ..listen(settingsProvider, (_, _) {})
      ..listen(entitlementsProvider, (_, _) {})
      ..listen(remainingSearchesProvider, (_, _) {});
    await container.read(settingsProvider.future);
    await container.read(entitlementsProvider.future);
    await container.read(remainingSearchesProvider.future);
    // Keep the controller alive for the whole test: it holds the form state.
    container.listen(homeControllerProvider, (_, _) {});
    return container;
  }

  HomeState stateOf(ProviderContainer container) =>
      container.read(homeControllerProvider);

  HomeController controllerOf(ProviderContainer container) =>
      container.read(homeControllerProvider.notifier);

  group('initial state', () {
    test(
      'starts from settings with Maps selected and Email/Phone on',
      () async {
        final ProviderContainer container = await makeContainer();
        final HomeState state = stateOf(container);

        expect(state.niche, isEmpty);
        expect(state.location, isEmpty);
        expect(state.sources, <LeadSource>{LeadSource.maps});
        expect(state.filters.hasEmail, isTrue);
        expect(state.filters.hasPhone, isTrue);
        expect(state.filters.hasWebsite, isFalse);
        expect(state.activeFilterCount, 0);
        expect(state.canSearch, isFalse);
        expect(state.maxResultsCap, 50);
        expect(state.defaultCountry, 'India');
      },
    );

    test(
      'falls back to Maps when the saved default source is not allowed',
      () async {
        final ProviderContainer container = await makeContainer(
          settings: const AppSettings(
            defaultSources: <LeadSource>{LeadSource.instagram},
          ),
        );
        expect(stateOf(container).sources, <LeadSource>{LeadSource.maps});
      },
    );

    test('Pro gets a 200 cap; settings max results is clamped to it', () async {
      final ProviderContainer container = await makeContainer(
        isPro: true,
        settings: const AppSettings(maxResults: 200),
      );
      expect(stateOf(container).maxResultsCap, 200);
      expect(stateOf(container).filters.maxResults, 200);
    });
  });

  group('canSearch rules', () {
    HomeState withFields(ProviderContainer container) {
      controllerOf(container)
        ..setNiche('Dentists')
        ..setLocation('Ahmedabad');
      return stateOf(container);
    }

    test('both fields must be valid and a source selected', () async {
      final ProviderContainer container = await makeContainer();
      expect(stateOf(container).canSearch, isFalse);

      controllerOf(container).setNiche('D');
      controllerOf(container).setLocation('Ahmedabad');
      expect(stateOf(container).canSearch, isFalse, reason: '1 char niche');

      controllerOf(container).setNiche('Dentists');
      expect(stateOf(container).canSearch, isTrue);

      controllerOf(container).setLocation('A');
      expect(stateOf(container).canSearch, isFalse, reason: '1 char city');
    });

    test('rejects more than 60 characters and strange characters', () async {
      final ProviderContainer container = await makeContainer();
      withFields(container);

      controllerOf(container).setNiche('a' * 61);
      expect(stateOf(container).canSearch, isFalse);
      expect(stateOf(container).nicheIssue, PlaceIssue.tooLong);

      controllerOf(container).setNiche('Den@tists');
      expect(stateOf(container).canSearch, isFalse);
      expect(stateOf(container).nicheIssue, PlaceIssue.invalidCharacters);

      controllerOf(container).setNiche('Dental & Co.');
      expect(stateOf(container).canSearch, isTrue);
      expect(stateOf(container).nicheIssue, isNull);

      controllerOf(container).setLocation('  ');
      expect(stateOf(container).canSearch, isFalse);
      expect(stateOf(container).locationIssue, PlaceIssue.tooShort);
    });
  });

  group('sources', () {
    test('Free cannot select a social source', () async {
      final ProviderContainer container = await makeContainer();
      expect(
        controllerOf(container).toggleSource(LeadSource.instagram),
        SourceToggleResult.locked,
      );
      expect(stateOf(container).sources, <LeadSource>{LeadSource.maps});
    });

    test('Pro can multi-select and always keeps one source', () async {
      final ProviderContainer container = await makeContainer(isPro: true);
      final HomeController controller = controllerOf(container);

      expect(
        controller.toggleSource(LeadSource.instagram),
        SourceToggleResult.selected,
      );
      expect(
        controller.toggleSource(LeadSource.linkedin),
        SourceToggleResult.selected,
      );
      expect(stateOf(container).sources.length, 3);

      expect(
        controller.toggleSource(LeadSource.maps),
        SourceToggleResult.deselected,
      );
      expect(
        controller.toggleSource(LeadSource.linkedin),
        SourceToggleResult.deselected,
      );
      expect(stateOf(container).sources, <LeadSource>{LeadSource.instagram});
      expect(
        controller.toggleSource(LeadSource.instagram),
        SourceToggleResult.lastSelected,
      );
      expect(stateOf(container).sources, <LeadSource>{LeadSource.instagram});
    });
  });

  group('filters', () {
    test('quick toggles write into the shared filters and count', () async {
      final ProviderContainer container = await makeContainer();
      final HomeController controller = controllerOf(container);

      controller.toggleQuick(HomeQuickFilter.email);
      expect(stateOf(container).filters.hasEmail, isFalse);
      expect(stateOf(container).activeFilterCount, 1);

      controller.toggleQuick(HomeQuickFilter.website);
      expect(stateOf(container).filters.hasWebsite, isTrue);
      expect(stateOf(container).activeFilterCount, 2);

      controller.toggleQuick(HomeQuickFilter.email);
      expect(stateOf(container).activeFilterCount, 1);
    });

    test('advanced filters add to the same count and are capped', () async {
      final ProviderContainer container = await makeContainer();
      final HomeController controller = controllerOf(container);

      controller.applyFilters(
        const SearchFilters(depth: SearchDepth.deep, maxResults: 100),
      );
      final HomeState state = stateOf(container);
      expect(state.filters.depth, SearchDepth.deep);
      expect(state.filters.maxResults, 50, reason: 'Free cap is 50');
      // 50 is the default, so only the depth change still counts as active.
      expect(state.activeFilterCount, 1);
    });
  });

  group('request building', () {
    test('normalizes niche and city, trims values and caps results', () async {
      final ProviderContainer container = await makeContainer(
        isPro: true,
        settings: const AppSettings(maxResults: 200),
      );
      final HomeController controller = controllerOf(container)
        ..setNiche('  dental   clinic ')
        ..setLocation(' bombay ');

      final HomeSubmitResult result = await controller.start();
      expect(result.stage, HomeSubmitStage.ready);

      final SearchRequest request = result.request!;
      expect(request.query.niches, <String>['Dentists']);
      expect(request.query.locations, <String>['Mumbai']);
      expect(request.query.sources, <LeadSource>{LeadSource.maps});
      expect(request.filters.maxResults, 200);
      expect(request.query.country, 'India');
      expect(request.id, startsWith('search-'));
    });

    test('Free is capped at 50 even if settings ask for 200', () async {
      final ProviderContainer container = await makeContainer(
        settings: const AppSettings(maxResults: 200),
      );
      controllerOf(container)
        ..setNiche('Dentists')
        ..setLocation('Ahmedabad');
      await controllerOf(container).start();
      final SearchRequest request = controllerOf(container).buildRequest();
      expect(request.filters.maxResults, 50);
    });
  });

  group('quota', () {
    test('exhausted Free cannot start and asks for the paywall', () async {
      final ProviderContainer container = await makeContainer(remaining: 0);
      controllerOf(container)
        ..setNiche('Dentists')
        ..setLocation('Ahmedabad');

      final HomeSubmitResult result = await controllerOf(container).start();
      expect(result.stage, HomeSubmitStage.quotaExhausted);
      expect(stateOf(container).isSubmitting, isFalse);
    });

    test('Pro is unlimited even at zero remaining', () async {
      final ProviderContainer container = await makeContainer(
        isPro: true,
        remaining: 0,
      );
      controllerOf(container)
        ..setNiche('Dentists')
        ..setLocation('Ahmedabad');

      final HomeSubmitResult result = await controllerOf(container).start();
      expect(result.stage, HomeSubmitStage.ready);
      expect(controllerOf(container).quotaStatus(0), HomeQuotaStatus.unlimited);
    });
  });

  group('rewarded flow', () {
    Future<ProviderContainer> freeReady({FakeAdConfig? ads}) async {
      final ProviderContainer container = await makeContainer(
        ads: ads ?? instantAds,
      );
      controllerOf(container)
        ..setNiche('Dentists')
        ..setLocation('Ahmedabad');
      return container;
    }

    test(
      'Free is asked for the opt-in dialog and guarded against double taps',
      () async {
        final ProviderContainer container = await freeReady();
        final HomeController controller = controllerOf(container);

        final HomeSubmitResult first = await controller.start();
        expect(first.stage, HomeSubmitStage.needsRewardedPrompt);
        expect(stateOf(container).isSubmitting, isTrue);

        final HomeSubmitResult second = await controller.start();
        expect(second.stage, HomeSubmitStage.inFlight);

        controller.cancelSubmission();
        expect(stateOf(container).isSubmitting, isFalse);
      },
    );

    test('an earned reward proceeds', () async {
      final ProviderContainer container = await freeReady();
      final HomeController controller = controllerOf(container);
      await controller.start();

      final HomeSubmitResult result = await controller.confirmRewarded();
      expect(result.stage, HomeSubmitStage.ready);
      expect(result.request!.query.displayTitle, 'Dentists in Ahmedabad');
      expect(stateOf(container).isSubmitting, isFalse);
    });

    test('closing early stays on Home', () async {
      final ProviderContainer container = await freeReady(
        ads: instantAds.copyWith(rewarded: FakeRewardedOutcome.dismissedEarly),
      );
      final HomeController controller = controllerOf(container);
      await controller.start();

      final HomeSubmitResult result = await controller.confirmRewarded();
      expect(result.stage, HomeSubmitStage.cancelled);
      expect(stateOf(container).isSubmitting, isFalse);
    });

    test('no ad available still proceeds', () async {
      final ProviderContainer container = await freeReady(
        ads: instantAds.copyWith(rewarded: FakeRewardedOutcome.unavailable),
      );
      final HomeController controller = controllerOf(container);
      await controller.start();

      final HomeSubmitResult result = await controller.confirmRewarded();
      expect(result.stage, HomeSubmitStage.ready);
    });

    test('Pro never sees the dialog', () async {
      final ProviderContainer container = await makeContainer(isPro: true);
      controllerOf(container)
        ..setNiche('Dentists')
        ..setLocation('Ahmedabad');
      final HomeSubmitResult result = await controllerOf(container).start();
      expect(result.stage, HomeSubmitStage.ready);
      expect(stateOf(container).isSubmitting, isFalse);
    });
  });

  group('recent rerun', () {
    test('fills the fields and runs the same flow', () async {
      final ProviderContainer container = await makeContainer();
      final SearchHistoryEntry entry = SearchHistoryEntry(
        id: 'h1',
        query: const SearchQuery(
          niches: <String>['Cafes'],
          locations: <String>['Mumbai'],
        ),
        resultCount: 88,
        searchedAt: DateTime(2026, 11, 24),
      );

      final HomeSubmitResult result = await controllerOf(
        container,
      ).rerun(entry);
      expect(stateOf(container).niche, 'Cafes');
      expect(stateOf(container).location, 'Mumbai');
      expect(result.stage, HomeSubmitStage.needsRewardedPrompt);
      expect(result.request!.query.displayTitle, 'Cafes in Mumbai');
    });
  });

  group('location', () {
    test('a found city fills the field, normalized', () async {
      final ProviderContainer container = await makeContainer(
        location: FakeLocationService(city: 'bombay', delay: Duration.zero),
      );
      final HomeLocationOutcome outcome = await controllerOf(
        container,
      ).useCurrentLocation();
      expect(outcome, HomeLocationOutcome.found);
      expect(stateOf(container).location, 'Mumbai');
      expect(stateOf(container).isLocating, isFalse);
    });

    test('denied and unavailable are outcomes, not exceptions', () async {
      for (final (FakeLocationOutcome outcome, HomeLocationOutcome expected)
          in <(FakeLocationOutcome, HomeLocationOutcome)>[
            (FakeLocationOutcome.permissionDenied, HomeLocationOutcome.denied),
            (FakeLocationOutcome.unavailable, HomeLocationOutcome.unavailable),
          ]) {
        final ProviderContainer container = await makeContainer(
          location: FakeLocationService(outcome: outcome, delay: Duration.zero),
        );
        expect(await controllerOf(container).useCurrentLocation(), expected);
        expect(stateOf(container).location, isEmpty);
      }
    });
  });

  test('Home never consumes a search and never writes history', () async {
    final _SpyQuota quota = _SpyQuota(3);
    final _SpyHistory history = _SpyHistory();
    final ProviderContainer container = await makeContainer(
      quota: quota,
      history: history,
    );
    final HomeController controller = controllerOf(container)
      ..setNiche('Dentists')
      ..setLocation('Ahmedabad');

    await controller.start();
    await controller.confirmRewarded();
    controller.buildRequest();

    expect(quota.consumeCalls, 0, reason: 'B2 consumes, not Home');
    expect(history.addCalls, 0, reason: 'B2 writes history, not Home');
    expect(history.clearCalls, 0);
  });
}
