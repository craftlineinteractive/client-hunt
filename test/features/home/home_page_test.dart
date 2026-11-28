import 'package:clienthunt/app.dart';
import 'package:clienthunt/app/providers.dart';
import 'package:clienthunt/core/constants/app_strings.dart';
import 'package:clienthunt/core/router/app_router.dart';
import 'package:clienthunt/data/fake/fake.dart';
import 'package:clienthunt/domain/entitlements/entitlements.dart';
import 'package:clienthunt/domain/models/models.dart';
import 'package:clienthunt/shared/widgets/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Search tab against the real router and the A2 fakes.
///
/// These tests care about what a user can *reach*: a disabled CTA, the
/// typeahead, locked sources, the quota wall, the rewarded opt-in and the Recent
/// block. They deliberately use the whole app rather than the page alone, so the
/// router, the shell and Home's provider wiring are covered together.
void main() {
  const FakeAdConfig instantAds = FakeAdConfig(
    loadDelay: Duration.zero,
    showDelay: Duration.zero,
    useTestAdPage: false,
  );

  setUp(() {
    appRouter.go(AppRoutes.search);
  });

  /// Pumps the app on Home with a tall viewport, so every block is reachable
  /// without scrolling and a tap cannot land on the wrong row by accident.
  Future<void> pumpHome(
    WidgetTester tester, {
    int remaining = 3,
    bool isPro = false,
    FakeAdConfig ads = instantAds,
    FakeLocationService? location,
    Size size = const Size(390, 1400),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          entitlementsProvider.overrideWith(
            (Ref ref) => Stream<Entitlements>.value(
              isPro ? proEntitlements : freeEntitlements,
            ),
          ),
          quotaRepositoryProvider.overrideWithValue(
            FakeQuotaRepository(
              remainingToday: remaining,
              latency: Duration.zero,
            ),
          ),
          adServiceProvider.overrideWithValue(
            FakeAdService(config: ads, navigatorKey: rootNavigatorKey),
          ),
          if (location != null)
            locationServiceProvider.overrideWithValue(location),
        ],
        child: const ClientHuntApp(),
      ),
    );
    // First frame, then the streams (settings, quota, history) and the rewarded
    // preload that Home starts after the frame.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> fillForm(
    WidgetTester tester, {
    String niche = 'Dentists',
    String city = 'Ahmedabad',
  }) async {
    await tester.enterText(find.byKey(const Key('home-niche-field')), niche);
    await tester.pump();
    await tester.enterText(find.byKey(const Key('home-location-field')), city);
    await tester.pump();
    // Dismiss the typeahead so its overlay cannot swallow the next tap.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
  }

  Future<void> tapFindLeads(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('home-find-leads')));
    await tester.pumpAndSettle();
  }

  testWidgets('the CTA stays inert until both fields are valid', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester);

    await tapFindLeads(tester);
    expect(find.text(AdsStrings.rewardedTitle), findsNothing);
    expect(find.text(HomeStrings.question), findsOneWidget);

    // One character is not a valid niche yet.
    await tester.enterText(find.byKey(const Key('home-niche-field')), 'D');
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('home-location-field')),
      'Ahmedabad',
    );
    await tester.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    await tapFindLeads(tester);
    expect(find.text(AdsStrings.rewardedTitle), findsNothing);

    await tester.enterText(
      find.byKey(const Key('home-niche-field')),
      'Dentists',
    );
    await tester.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    await tapFindLeads(tester);
    expect(find.text(AdsStrings.rewardedTitle), findsOneWidget);
  });

  testWidgets('the typeahead fills the niche from the catalog', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester);

    await tester.enterText(find.byKey(const Key('home-niche-field')), 'dent');
    await tester.pump();

    final Finder suggestions = find.byKey(const Key('home-suggestions'));
    expect(suggestions, findsOneWidget);
    final Finder dentists = find.descendant(
      of: suggestions,
      matching: find.text('Dentists'),
    );
    expect(dentists, findsOneWidget);

    await tester.tap(dentists);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-suggestions')), findsNothing);
    final EditableText field = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('home-niche-field')),
        matching: find.byType(EditableText),
      ),
    );
    expect(field.controller.text, 'Dentists');
  });

  testWidgets('a locked social source opens the paywall', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester);

    final Finder instagram = find.text(LeadSource.instagram.displayName);
    await tester.ensureVisible(instagram);
    await tester.tap(instagram);
    await tester.pumpAndSettle();

    // The placeholder shows its title in the app bar and in the body.
    expect(find.text('ClientHunt Pro'), findsWidgets);
    expect(find.text(HomeStrings.question), findsNothing);
  });

  testWidgets('an exhausted quota blocks the CTA and opens the paywall', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester, remaining: 0);

    expect(
      find.text(
        '0/${freeEntitlements.freeSearchesPerDay} ${HomeStrings.quotaSuffix}',
      ),
      findsOneWidget,
    );
    expect(find.text(HomeStrings.dailyLimitReached), findsOneWidget);

    await tapFindLeads(tester);
    expect(find.text('ClientHunt Pro'), findsWidgets);
  });

  testWidgets('Free sees the opt-in dialog and Cancel stays on Home', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester);
    await fillForm(tester);
    await tapFindLeads(tester);

    expect(find.text(AdsStrings.rewardedTitle), findsOneWidget);
    expect(find.text(AdsStrings.rewardedBody), findsOneWidget);

    await tester.tap(find.text(CommonStrings.cancel));
    await tester.pumpAndSettle();

    expect(find.text(HomeStrings.question), findsOneWidget);
    expect(find.byType(AppBottomNav), findsOneWidget);
  });

  testWidgets('watching the rewarded ad opens Results', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester);
    await fillForm(tester);
    await tapFindLeads(tester);

    await tester.tap(find.text(AdsStrings.rewardedWatch));
    await tester.pumpAndSettle();

    expect(find.text('Dentists in Ahmedabad'), findsWidgets);
    expect(find.byType(AppBottomNav), findsNothing);
  });

  testWidgets('closing the ad early keeps the user on Home', (
    WidgetTester tester,
  ) async {
    await pumpHome(
      tester,
      ads: instantAds.copyWith(rewarded: FakeRewardedOutcome.dismissedEarly),
    );
    await fillForm(tester);
    await tapFindLeads(tester);

    await tester.tap(find.text(AdsStrings.rewardedWatch));
    await tester.pumpAndSettle();

    expect(find.text(AdsStrings.rewardedDismissed), findsOneWidget);
    expect(find.text(HomeStrings.question), findsOneWidget);
    // Let the snackbar time out so no timer outlives the test.
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Pro searches without a dialog or an ad', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester, isPro: true);
    await fillForm(tester);
    await tapFindLeads(tester);

    expect(find.text(AdsStrings.rewardedTitle), findsNothing);
    expect(find.text('Dentists in Ahmedabad'), findsWidgets);
  });

  testWidgets('Recent reruns a search and Clear all empties it', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester);

    expect(find.byKey(const Key('home-recent')), findsOneWidget);
    expect(find.text('Cafes in Mumbai'), findsOneWidget);

    await tester.tap(find.text('Cafes in Mumbai'));
    await tester.pumpAndSettle();
    expect(find.text(AdsStrings.rewardedTitle), findsOneWidget);
    await tester.tap(find.text(CommonStrings.cancel));
    await tester.pumpAndSettle();

    await tester.tap(find.text(CommonStrings.clearAll));
    await tester.pumpAndSettle();
    expect(find.text(HomeStrings.clearRecentTitle), findsOneWidget);
    await tester.tap(find.text(HomeStrings.clearRecentConfirm));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-recent')), findsNothing);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('the quick toggles move the Filters badge', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester);

    final Finder badge = find.descendant(
      of: find.byKey(const Key('home-filters-button')),
      matching: find.text('1'),
    );
    expect(badge, findsNothing);

    final Finder website = find.text(ResultsStrings.filterWebsite);
    await tester.ensureVisible(website);
    await tester.tap(website);
    await tester.pumpAndSettle();

    expect(badge, findsOneWidget);
  });

  testWidgets('a denied location is a snackbar, not a dead field', (
    WidgetTester tester,
  ) async {
    await pumpHome(
      tester,
      location: FakeLocationService(
        outcome: FakeLocationOutcome.permissionDenied,
        delay: Duration.zero,
      ),
    );

    await tester.tap(find.byTooltip(HomeStrings.useMyLocation));
    await tester.pumpAndSettle();

    expect(find.text(HomeStrings.locationDenied), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('nothing overflows on small screens or at 1.3 text scale', (
    WidgetTester tester,
  ) async {
    const List<(double, double, double)> layouts = <(double, double, double)>[
      (320, 1400, 1),
      (360, 1400, 1),
      (411, 1400, 1),
      (360, 1400, 1.3),
      // A short viewport stands in for the keyboard covering the lower half.
      (390, 420, 1),
    ];

    for (final (double width, double height, double scale) in layouts) {
      await pumpHome(tester, size: Size(width, height), textScale: scale);
      await fillForm(tester);
      expect(
        tester.takeException(),
        isNull,
        reason: '${width.toInt()} px wide at text scale $scale',
      );
    }
  });
}
