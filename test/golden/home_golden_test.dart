@Tags(<String>['golden'])
library;

import 'package:clienthunt/app.dart';
import 'package:clienthunt/app/providers.dart';
import 'package:clienthunt/core/constants/app_strings.dart';
import 'package:clienthunt/core/router/app_router.dart';
import 'package:clienthunt/core/theme/theme_mode_provider.dart';
import 'package:clienthunt/data/fake/fake.dart';
import 'package:clienthunt/domain/entitlements/entitlements.dart';
import 'package:clienthunt/features/home/home_controller.dart';
import 'package:clienthunt/shared/widgets/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pixel snapshots of the Search tab and the rewarded opt-in dialog.
///
/// Regenerate on the machine that will verify them:
///
///     flutter test --update-goldens --tags golden
///
/// Fonts are bundled, so a widget test still starts with the placeholder font;
/// this file registers the four families once. Goldens are platform sensitive:
/// these are generated on Windows and must be verified there.
void main() {
  setUpAll(_loadBundledFonts);

  const FakeAdConfig instantAds = FakeAdConfig(
    loadDelay: Duration.zero,
    showDelay: Duration.zero,
    useTestAdPage: false,
  );

  Future<void> pumpHome(WidgetTester tester, ThemeMode mode) async {
    appRouter.go(AppRoutes.search);
    tester.view.physicalSize = const Size(390, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeModeProvider.overrideWith(() => _FixedThemeMode(mode)),
          entitlementsProvider.overrideWith(
            (Ref ref) => Stream<Entitlements>.value(freeEntitlements),
          ),
          adServiceProvider.overrideWithValue(
            FakeAdService(config: instantAds, navigatorKey: rootNavigatorKey),
          ),
        ],
        child: const ClientHuntApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Fill the form through the controller instead of typing: typing leaves a
    // selection highlight and a cursor in the snapshot, which is a test artefact
    // rather than part of the screen.
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.text(HomeStrings.question)),
      listen: false,
    );
    container.read(homeControllerProvider.notifier)
      ..setNiche('Dentists')
      ..setLocation('Ahmedabad');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
    testWidgets('Search tab, ${mode.name}', (WidgetTester tester) async {
      await pumpHome(tester, mode);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/home_filled.${mode.name}.png'),
      );
    });

    testWidgets('rewarded opt-in dialog, ${mode.name}', (
      WidgetTester tester,
    ) async {
      await pumpHome(tester, mode);

      await tester.tap(find.byKey(const Key('home-find-leads')));
      await tester.pumpAndSettle();
      expect(find.text(AdsStrings.rewardedTitle), findsOneWidget);

      await expectLater(
        find.byType(AppDialog),
        matchesGoldenFile('goldens/rewarded_dialog.${mode.name}.png'),
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
