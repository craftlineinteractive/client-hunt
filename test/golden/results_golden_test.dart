@Tags(<String>['golden'])
library;

import 'dart:async';

import 'package:clienthunt/app.dart';
import 'package:clienthunt/app/providers.dart';
import 'package:clienthunt/core/router/app_router.dart';
import 'package:clienthunt/core/theme/theme_mode_provider.dart';
import 'package:clienthunt/data/fake/fake.dart';
import 'package:clienthunt/domain/entitlements/entitlements.dart';
import 'package:clienthunt/domain/models/models.dart';
import 'package:clienthunt/domain/repositories/repositories.dart';
import 'package:clienthunt/shared/widgets/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pixel snapshots of the Results screen: loaded, loading, empty and error, in
/// light and dark, at the mockup's 390 x 844.
///
/// Regenerate on the machine that will verify them:
///
///     flutter test --update-goldens --tags golden
void main() {
  setUpAll(_loadBundledFonts);

  const FakeAdConfig instantAds = FakeAdConfig(
    loadDelay: Duration.zero,
    showDelay: Duration.zero,
    useTestAdPage: false,
  );

  const SearchRequest request = SearchRequest(
    id: 'search-golden',
    query: SearchQuery(
      niches: <String>['Dentists'],
      locations: <String>['Ahmedabad'],
    ),
  );

  Future<void> pumpResults(
    WidgetTester tester,
    ThemeMode mode, {
    FakeScenario scenario = FakeScenario.normal,
    Duration latency = Duration.zero,
  }) async {
    appRouter.go(AppRoutes.search);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final DateTime now = DateTime(2026, 11, 26, 9);
    final DummyDataSet data = DummyData.build(now: now);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeModeProvider.overrideWith(() => _FixedThemeMode(mode)),
          entitlementsProvider.overrideWith(
            (Ref ref) => Stream<Entitlements>.value(freeEntitlements),
          ),
          leadSearchEngineProvider.overrideWithValue(
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
          adServiceProvider.overrideWithValue(
            FakeAdService(config: instantAds, navigatorKey: rootNavigatorKey),
          ),
        ],
        child: const ClientHuntApp(),
      ),
    );
    await tester.pump();

    final BuildContext context = tester.element(find.byType(AppBottomNav));
    unawaited(AppNavigator.goToResults(context, request: request));
    await tester.pump();
  }

  /// Advances until [finder] matches, so the fake stream can finish.
  Future<void> pumpUntil(WidgetTester tester, Finder finder) async {
    for (int index = 0; index < 300; index++) {
      if (finder.evaluate().isNotEmpty) {
        return;
      }
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
    testWidgets('Results loaded, ${mode.name}', (WidgetTester tester) async {
      await pumpResults(tester, mode);
      await pumpUntil(tester, find.byKey(const Key('results-list')));
      await tester.pump(const Duration(milliseconds: 400));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/results_loaded.${mode.name}.png'),
      );
    });

    testWidgets('Results loading, ${mode.name}', (WidgetTester tester) async {
      await pumpResults(tester, mode, latency: const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byKey(const Key('results-progress-card')), findsOneWidget);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/results_loading.${mode.name}.png'),
      );

      // The golden is captured; let the fake engine's staged timers run out (one
      // stage plus six batches) so the test does not end with one pending.
      for (int index = 0; index < 12; index++) {
        await tester.pump(const Duration(seconds: 2));
      }
    });

    testWidgets('Results empty, ${mode.name}', (WidgetTester tester) async {
      await pumpResults(tester, mode, scenario: FakeScenario.emptyCompleted);
      await pumpUntil(tester, find.byKey(const Key('results-empty')));
      await tester.pump(const Duration(milliseconds: 400));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/results_empty.${mode.name}.png'),
      );
    });

    testWidgets('Results error, ${mode.name}', (WidgetTester tester) async {
      await pumpResults(tester, mode, scenario: FakeScenario.errorNoNetwork);
      await pumpUntil(tester, find.byKey(const Key('results-error')));
      await tester.pump(const Duration(milliseconds: 400));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/results_error.${mode.name}.png'),
      );
    });
  }
}

/// Forces a fixed theme mode for a golden.
class _FixedThemeMode extends ThemeModeNotifier {
  _FixedThemeMode(this.mode);

  final ThemeMode mode;

  @override
  ThemeMode build() => mode;
}

/// Registers the bundled font families for the test renderer.
Future<void> _loadBundledFonts() async {
  Future<void> load(String family, String asset) async {
    final FontLoader loader = FontLoader(family)
      ..addFont(rootBundle.load(asset));
    await loader.load();
  }

  await load(
    'Plus Jakarta Sans',
    'assets/fonts/plus_jakarta_sans/PlusJakartaSans-Variable.ttf',
  );
  await load('Inter', 'assets/fonts/inter/Inter-Variable.ttf');
  await load(
    'JetBrains Mono',
    'assets/fonts/jetbrains_mono/JetBrainsMono-Variable.ttf',
  );
  await load('MaterialIcons', 'fonts/MaterialIcons-Regular.otf');
}
