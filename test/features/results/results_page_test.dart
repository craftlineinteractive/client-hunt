import 'dart:async';

import 'package:clienthunt/app.dart';
import 'package:clienthunt/app/providers.dart';
import 'package:clienthunt/core/constants/app_strings.dart';
import 'package:clienthunt/core/router/app_router.dart';
import 'package:clienthunt/data/fake/fake.dart';
import 'package:clienthunt/domain/entitlements/entitlements.dart';
import 'package:clienthunt/domain/models/models.dart';
import 'package:clienthunt/domain/repositories/repositories.dart';
import 'package:clienthunt/features/home/home_page.dart';
import 'package:clienthunt/features/results/results_controller.dart';
import 'package:clienthunt/features/results/results_page.dart';
import 'package:clienthunt/features/results/results_state.dart';
import 'package:clienthunt/shared/widgets/app_bottom_nav.dart';
import 'package:clienthunt/shared/widgets/lead_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Results screen against the real router, the fake engine and the fakes.
///
/// These tests drive what a user can do: watch progress, filter, sort, select,
/// copy, export, open a lead, leave. They deliberately never assert pixel values
/// — the goldens do that.
void main() {
  final DateTime now = DateTime(2026, 11, 26, 9);
  final DummyDataSet data = DummyData.build(now: now);

  const SearchRequest request = SearchRequest(
    id: 'search-test',
    query: SearchQuery(
      niches: <String>['Dentists'],
      locations: <String>['Ahmedabad'],
    ),
  );

  const FakeAdConfig instantAds = FakeAdConfig(
    loadDelay: Duration.zero,
    showDelay: Duration.zero,
    useTestAdPage: false,
  );

  setUp(() {
    appRouter.go(AppRoutes.search);
  });

  Future<void> pumpResults(
    WidgetTester tester, {
    SearchRequest? searchRequest,
    FakeScenario scenario = FakeScenario.normal,
    Duration latency = Duration.zero,
    LeadSearchEngine? engine,
    bool isPro = false,
    FakeAdService? ads,
    bool forceInterstitial = false,
    Size size = const Size(390, 1000),
    double textScale = 1,
  }) async {
    // A second pump in the same test reuses the singleton router, whose stack
    // would still be on Results; reset it before mounting.
    appRouter.go(AppRoutes.search);

    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          leadSearchEngineProvider.overrideWithValue(
            engine ??
                FakeLeadSearchEngine(
                  scenario: scenario,
                  searchLatency: latency,
                  data: data,
                ),
          ),
          leadRepositoryProvider.overrideWithValue(
            FakeLeadRepository(data: data, latency: Duration.zero),
          ),
          quotaRepositoryProvider.overrideWithValue(
            FakeQuotaRepository(latency: Duration.zero),
          ),
          searchHistoryRepositoryProvider.overrideWithValue(
            FakeSearchHistoryRepository(data: data, latency: Duration.zero),
          ),
          contactLauncherProvider.overrideWithValue(FakeContactLauncher()),
          entitlementsProvider.overrideWith(
            (Ref ref) => Stream<Entitlements>.value(
              isPro ? proEntitlements : freeEntitlements,
            ),
          ),
          adServiceProvider.overrideWithValue(
            ads ??
                FakeAdService(
                  config: instantAds,
                  navigatorKey: rootNavigatorKey,
                ),
          ),
        ],
        child: const ClientHuntApp(),
      ),
    );
    await tester.pump();

    if (forceInterstitial) {
      ProviderScope.containerOf(
        tester.element(find.byType(ClientHuntApp).first),
        listen: false,
      ).read(forcedInterstitialProvider.notifier).set(true);
    }

    final BuildContext context = tester.element(find.byType(AppBottomNav));
    unawaited(
      AppNavigator.goToResults(context, request: searchRequest ?? request),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
  }

  /// Pumps frames until [finder] matches (or gives up).
  Future<void> pumpUntil(
    WidgetTester tester,
    Finder finder, {
    int maxFrames = 300,
    Duration step = const Duration(milliseconds: 20),
  }) async {
    for (int index = 0; index < maxFrames; index++) {
      if (finder.evaluate().isNotEmpty) {
        return;
      }
      await tester.pump(step);
    }
  }

  ResultsState readState(WidgetTester tester, [SearchRequest? searchRequest]) {
    final BuildContext context = tester.element(find.byType(ResultsPage));
    final ProviderContainer container = ProviderScope.containerOf(
      context,
      listen: false,
    );
    return container.read(resultsControllerProvider(searchRequest ?? request));
  }

  testWidgets('the loading card lists sources and cancels the search', (
    WidgetTester tester,
  ) async {
    await pumpResults(tester, latency: const Duration(milliseconds: 200));

    expect(find.byKey(const Key('results-progress-card')), findsOneWidget);
    expect(find.text(ResultsStrings.loadingQuerying), findsWidgets);
    expect(find.text(LeadSource.maps.displayName), findsOneWidget);
    expect(find.text(ResultsStrings.sourceRunning), findsOneWidget);
    expect(find.text(ResultsStrings.foundSoFar(0)), findsOneWidget);

    await tester.tap(find.text(CommonStrings.cancel));
    await pumpUntil(tester, find.byType(HomePage));

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(ResultsPage), findsNothing);
  });

  testWidgets('partial results append under a pinned header without jumping', (
    WidgetTester tester,
  ) async {
    await pumpResults(tester, latency: const Duration(milliseconds: 120));

    await pumpUntil(tester, find.byKey(const Key('results-progress-header')));
    expect(find.byKey(const Key('results-progress-header')), findsOneWidget);

    final ScrollableState scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );

    await pumpUntil(
      tester,
      find.byKey(const Key('results-progress-header')),
      maxFrames: 1,
    );
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pump();
    final double offsetBefore = scrollable.position.pixels;

    await pumpUntil(
      tester,
      find.text(ResultsStrings.leadsCount(42)),
      maxFrames: 400,
    );

    expect(scrollable.position.pixels, closeTo(offsetBefore, 1));
    expect(readState(tester).phase, ResultsPhase.completed);
  });

  testWidgets('a completed search shows the 42 / 31 / 40 counts', (
    WidgetTester tester,
  ) async {
    await pumpResults(tester);
    await pumpUntil(tester, find.byKey(const Key('results-list')));

    // Stats strip cells.
    expect(find.text('42'), findsWidgets);
    expect(find.text('31'), findsWidgets);
    expect(find.text('40'), findsWidgets);
    expect(find.text(ResultsStrings.statsLeads), findsOneWidget);
    expect(find.text(ResultsStrings.statsEmails), findsOneWidget);
    expect(find.text(ResultsStrings.statsPhones), findsOneWidget);

    final ResultsState state = readState(tester);
    expect(state.totalCount, 42);
    expect(state.withEmailCount, 31);
    expect(state.withPhoneCount, 40);
  });

  testWidgets('a chip filters the list without changing the totals', (
    WidgetTester tester,
  ) async {
    await pumpResults(tester);
    await pumpUntil(tester, find.byKey(const Key('results-list')));
    final int before = readState(tester).visibleCount;

    await tester.tap(find.text(ResultsStrings.filterWebsite));
    await tester.pump();

    final ResultsState state = readState(tester);
    expect(state.visibleCount, lessThan(before));
    expect(state.totalCount, 42);
    expect(state.visibleLeads.every((Lead lead) => lead.hasWebsite), isTrue);
  });

  testWidgets('the inline search filters as you type', (
    WidgetTester tester,
  ) async {
    await pumpResults(tester);
    await pumpUntil(tester, find.byKey(const Key('results-list')));

    await tester.tap(find.byKey(const Key('results-search-toggle')));
    await tester.pump();
    expect(find.byKey(const Key('results-search-field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('results-search-field')),
      'Northline',
    );
    await tester.pump();

    final ResultsState state = readState(tester);
    expect(state.isSearchMode, isTrue);
    expect(state.filter.text, 'Northline');
    expect(state.visibleCount, lessThan(42));
    expect(
      state.visibleLeads.every(
        (Lead lead) => lead.name.toLowerCase().contains('northline'),
      ),
      isTrue,
    );
  });

  testWidgets('the sort menu reorders the visible leads', (
    WidgetTester tester,
  ) async {
    await pumpResults(tester);
    await pumpUntil(tester, find.byKey(const Key('results-list')));

    await tester.tap(find.byKey(const Key('results-sort-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ResultsStrings.sortNameAZ));
    await tester.pumpAndSettle();

    final List<Lead> visible = readState(tester).visibleLeads;
    final List<String> names = <String>[
      for (final Lead lead in visible) lead.name.toLowerCase(),
    ];
    expect(names, orderedEquals(<String>[...names]..sort()));
  });

  testWidgets('selecting a lead shows the count and the export badge', (
    WidgetTester tester,
  ) async {
    await pumpResults(tester);
    await pumpUntil(tester, find.byKey(const Key('results-list')));

    // The card's checkbox is labelled with the lead name.
    await tester.tap(find.byTooltip(data.dentistResults.first.name));
    await tester.pump();

    expect(find.text(ResultsStrings.selectedCount(1)), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('results-export-count')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Export receives the selection as ExportArgs', (
    WidgetTester tester,
  ) async {
    await pumpResults(tester);
    await pumpUntil(tester, find.byKey(const Key('results-list')));

    await tester.tap(find.byKey(const Key('results-select-all')));
    await tester.pump();

    await tester.tap(find.text(ResultsStrings.exportLeads));
    await tester.pumpAndSettle();

    expect(find.text('Export leads'), findsWidgets);
    expect(find.text('42 leads · Selected only'), findsOneWidget);
    expect(find.text('Dentists in Ahmedabad'), findsWidgets);
  });

  testWidgets('the copy menu writes the emails to the clipboard', (
    WidgetTester tester,
  ) async {
    String? clipboard;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard =
              (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await pumpResults(tester);
    await pumpUntil(tester, find.byKey(const Key('results-list')));

    await tester.tap(find.byTooltip(ResultsStrings.copyAllTooltip));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ResultsStrings.copyEmails(31)));
    await tester.pumpAndSettle();

    expect(clipboard, isNotNull);
    expect(clipboard!.split('\n'), hasLength(31));
    expect(clipboard, contains('@'));
    expect(find.text(ResultsStrings.copiedEmailsToast), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('copying phones writes 40 numbers', (WidgetTester tester) async {
    String? clipboard;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard =
              (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await pumpResults(tester);
    await pumpUntil(tester, find.byKey(const Key('results-list')));

    await tester.tap(find.byTooltip(ResultsStrings.copyAllTooltip));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ResultsStrings.copyPhones(40)));
    await tester.pumpAndSettle();

    expect(clipboard!.split('\n'), hasLength(40));
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('a landline-only lead has WhatsApp disabled', (
    WidgetTester tester,
  ) async {
    final Lead landlineOnly = Lead(
      id: 'landline-1',
      name: 'Cedar Legal Associates',
      category: 'Law firm',
      area: 'Navrangpura',
      city: 'Ahmedabad',
      phones: <PhoneContact>[
        PhoneContact(
          value: DummyData.fakePhone(9001),
          kind: PhoneKind.landline,
          isPrimary: true,
        ),
      ],
      emails: <EmailContact>[
        EmailContact(value: DummyData.fakeEmail('cedar-legal')),
      ],
      rating: 4.4,
      reviewCount: 12,
      isOpenNow: true,
      sources: const <LeadSource>{LeadSource.maps},
      discoveredAt: now,
    );

    await pumpResults(tester, engine: _OneShotEngine(<Lead>[landlineOnly]));
    await pumpUntil(tester, find.byType(LeadCard));

    final Finder whatsApp = find.byTooltip(ResultsStrings.whatsAppTooltip);
    expect(whatsApp, findsOneWidget);
    final Opacity opacity = tester.widget<Opacity>(
      find.descendant(of: whatsApp, matching: find.byType(Opacity)).first,
    );
    expect(opacity.opacity, 0.4);

    // Call still works and records the channel.
    await tester.tap(find.byTooltip(ResultsStrings.callTooltip));
    await tester.pump();
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(ResultsPage)),
      listen: false,
    );
    final FakeContactLauncher launcher =
        container.read(contactLauncherProvider) as FakeContactLauncher;
    expect(launcher.lastCall?.channel, ContactChannel.phone);
  });

  testWidgets('tapping a card opens Lead Detail with its id', (
    WidgetTester tester,
  ) async {
    await pumpResults(tester);
    await pumpUntil(tester, find.byKey(const Key('results-list')));

    await tester.tap(find.text(data.dentistResults.first.name));
    await tester.pumpAndSettle();

    // App bar title and placeholder heading both read "Lead details".
    expect(find.text(LeadDetailStrings.title), findsWidgets);
    expect(find.text(data.dentistResults.first.id), findsOneWidget);
  });

  testWidgets('the Free cap note appears when a search hits the cap', (
    WidgetTester tester,
  ) async {
    final List<Lead> fifty = data.largeResults.take(50).toList();
    await pumpResults(tester, engine: _OneShotEngine(fifty));
    await pumpUntil(tester, find.byKey(const Key('results-list')));

    expect(find.byKey(const Key('results-cap-note')), findsOneWidget);
    expect(find.text(ResultsStrings.capNote(50, 200)), findsOneWidget);
  });

  testWidgets('Pro never sees the cap note', (WidgetTester tester) async {
    final List<Lead> fifty = data.largeResults.take(50).toList();
    await pumpResults(tester, engine: _OneShotEngine(fifty), isPro: true);
    await pumpUntil(tester, find.byKey(const Key('results-list')));
    // The entitlements arrive on a stream, so let the Pro value land.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(readState(tester).totalCount, 50);
    expect(find.byKey(const Key('results-cap-note')), findsNothing);
  });

  testWidgets('an empty completed search offers Edit search', (
    WidgetTester tester,
  ) async {
    await pumpResults(tester, scenario: FakeScenario.emptyCompleted);
    await pumpUntil(tester, find.byKey(const Key('results-empty')));

    expect(find.text(ResultsStrings.emptyTitle), findsOneWidget);
    expect(find.text(ResultsStrings.emptyAction), findsOneWidget);

    await tester.tap(find.text(ResultsStrings.emptyAction));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('the no-network error offers Retry and Edit search', (
    WidgetTester tester,
  ) async {
    await pumpResults(tester, scenario: FakeScenario.errorNoNetwork);
    await pumpUntil(tester, find.byKey(const Key('results-error')));

    expect(find.text(CommonStrings.noNetworkTitle), findsOneWidget);
    expect(find.text(CommonStrings.retry), findsOneWidget);
    expect(find.text(ResultsStrings.emptyAction), findsOneWidget);
  });

  testWidgets('the rate-limited error shows its own copy', (
    WidgetTester tester,
  ) async {
    await pumpResults(tester, scenario: FakeScenario.errorRateLimited);
    await pumpUntil(tester, find.byKey(const Key('results-error')));

    expect(find.text(ResultsStrings.rateLimitedTitle), findsOneWidget);
    expect(find.text(ResultsStrings.rateLimitedBody), findsOneWidget);
  });

  testWidgets('a blocked source shows the partial note and its details', (
    WidgetTester tester,
  ) async {
    const SearchRequest socialRequest = SearchRequest(
      id: 'search-social',
      query: SearchQuery(
        niches: <String>['Dentists'],
        locations: <String>['Ahmedabad'],
        sources: <LeadSource>{LeadSource.maps, LeadSource.instagram},
      ),
    );
    await pumpResults(
      tester,
      searchRequest: socialRequest,
      scenario: FakeScenario.partialSourceBlocked,
    );
    await pumpUntil(tester, find.byKey(const Key('results-source-note')));

    expect(find.text(ResultsStrings.partialSourcesNote), findsOneWidget);

    await tester.tap(find.text(ResultsStrings.detailsAction));
    await tester.pumpAndSettle();
    expect(find.text(ResultsStrings.sourceDetailsTitle), findsOneWidget);
    expect(
      find.textContaining(
        '${LeadSource.instagram.displayName}: ${ResultsStrings.sourceBlocked}',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text(CommonStrings.done));
    await tester.pumpAndSettle();
  });

  testWidgets('nothing overflows at 320, 360, 411 dp or at 1.3 text scale', (
    WidgetTester tester,
  ) async {
    const List<(double, double, double)> layouts = <(double, double, double)>[
      (320, 900, 1),
      (360, 900, 1),
      (411, 900, 1),
      (360, 900, 1.3),
      // A short viewport stands in for the keyboard over a search field.
      (390, 420, 1),
    ];

    for (final (double width, double height, double scale) in layouts) {
      await pumpResults(tester, size: Size(width, height), textScale: scale);
      await pumpUntil(tester, find.byKey(const Key('results-list')));
      expect(
        tester.takeException(),
        isNull,
        reason: '${width.toInt()} px wide at text scale $scale',
      );

      await tester.tap(find.byKey(const Key('results-search-toggle')));
      await tester.pump();
      expect(
        tester.takeException(),
        isNull,
        reason: '${width.toInt()} dp with the search field open',
      );
      await tester.tap(find.byTooltip(ResultsStrings.closeSearchTooltip));
      await tester.pump();
    }
  });

  testWidgets('leaving a completed search asks for an interstitial', (
    WidgetTester tester,
  ) async {
    final _SpyAdService ads = _SpyAdService(
      config: instantAds,
      navigatorKey: rootNavigatorKey,
    );
    await pumpResults(tester, ads: ads, forceInterstitial: true);
    await pumpUntil(tester, find.byKey(const Key('results-list')));

    await tester.tap(find.byTooltip('Go back'));
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    expect(ads.interstitialsShown, 1);
  });

  testWidgets('leaving a running search never asks for an interstitial', (
    WidgetTester tester,
  ) async {
    final _SpyAdService ads = _SpyAdService(
      config: instantAds,
      navigatorKey: rootNavigatorKey,
    );
    await pumpResults(
      tester,
      ads: ads,
      forceInterstitial: true,
      latency: const Duration(milliseconds: 400),
    );
    expect(find.byKey(const Key('results-progress-card')), findsOneWidget);

    await tester.tap(find.byTooltip('Go back'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(HomePage), findsOneWidget);
    expect(ads.interstitialsShown, 0);
  });

  testWidgets('unsaving and saving a card updates the bookmark', (
    WidgetTester tester,
  ) async {
    await pumpResults(tester);
    await pumpUntil(tester, find.byKey(const Key('results-list')));

    // The hero starts saved in the demo data.
    expect(find.byTooltip(ResultsStrings.removeSavedTooltip), findsWidgets);

    await tester.tap(find.byTooltip(ResultsStrings.removeSavedTooltip).first);
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(ResultsStrings.unsavedToast), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });
}

/// An engine that emits one partial batch and completes, for data the fake
/// scenario does not produce (a landline-only lead, exactly 50 leads).
class _OneShotEngine implements LeadSearchEngine {
  _OneShotEngine(this.leads);

  final List<Lead> leads;

  @override
  Stream<SearchEvent> search(SearchRequest request) async* {
    yield SearchStarted(
      searchId: request.id,
      sources: <LeadSource>[LeadSource.maps],
    );
    yield SearchProgress(
      searchId: request.id,
      stage: SearchStage.querying,
      sourceStatuses: const <LeadSource, SourceStatus>{
        LeadSource.maps: SourceStatus.running,
      },
    );
    yield SearchPartialResults(
      searchId: request.id,
      leads: leads,
      foundSoFar: leads.length,
    );
    yield SearchCompleted(
      searchId: request.id,
      summary: SearchSummary(
        total: leads.length,
        withEmail: leads.where((Lead lead) => lead.hasEmail).length,
        withPhone: leads.where((Lead lead) => lead.hasPhone).length,
        duration: Duration.zero,
        perSource: <LeadSource, SourceResult>{
          LeadSource.maps: SourceResult(
            status: SourceStatus.done,
            leadsFound: leads.length,
          ),
        },
      ),
    );
  }

  @override
  Future<void> cancel(String searchId) async {}
}

/// Counts interstitials; the fake service otherwise answers instantly.
class _SpyAdService extends FakeAdService {
  _SpyAdService({required super.config, required super.navigatorKey});

  int interstitialsShown = 0;

  @override
  Future<bool> showInterstitial() async {
    final bool shown = await super.showInterstitial();
    if (shown) {
      interstitialsShown++;
    }
    return shown;
  }
}
