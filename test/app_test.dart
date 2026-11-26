import 'package:clienthunt/app.dart';
import 'package:clienthunt/core/router/app_router.dart';
import 'package:clienthunt/core/theme/theme_mode_provider.dart';
import 'package:clienthunt/shared/widgets/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Forces a fixed theme mode for a test.
class _FixedThemeMode extends ThemeModeNotifier {
  _FixedThemeMode(this.mode);

  final ThemeMode mode;

  @override
  ThemeMode build() => mode;
}

Widget _appWith(ThemeMode mode) {
  return ProviderScope(
    overrides: [themeModeProvider.overrideWith(() => _FixedThemeMode(mode))],
    child: const ClientHuntApp(),
  );
}

void main() {
  setUp(() {
    appRouter.go(AppRoutes.search);
  });

  testWidgets('builds in light mode and opens the Search tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_appWith(ThemeMode.light));
    await tester.pump();

    expect(find.byType(ClientHuntApp), findsOneWidget);
    final MaterialApp app = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );
    expect(app.themeMode, ThemeMode.light);
    expect(app.theme?.brightness, Brightness.light);

    // The three tab labels are present and Search is the landing page.
    expect(find.byType(AppBottomNav), findsOneWidget);
    expect(find.text('Who are you looking for?'), findsOneWidget);
  });

  testWidgets('builds in dark mode', (WidgetTester tester) async {
    await tester.pumpWidget(_appWith(ThemeMode.dark));
    await tester.pump();

    final MaterialApp app = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );
    expect(app.themeMode, ThemeMode.dark);
    expect(app.darkTheme?.brightness, Brightness.dark);
    expect(find.text('Who are you looking for?'), findsOneWidget);
  });

  testWidgets('bottom navigation switches between the three tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_appWith(ThemeMode.light));
    await tester.pump();

    Finder navLabel(String label) => find.descendant(
      of: find.byType(AppBottomNav),
      matching: find.text(label),
    );

    await tester.tap(navLabel('Saved'));
    await tester.pumpAndSettle();
    expect(find.text('Saved leads'), findsWidgets);

    await tester.tap(navLabel('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Theme, defaults, storage and legal.'), findsOneWidget);

    await tester.tap(navLabel('Search'));
    await tester.pumpAndSettle();
    expect(find.text('Who are you looking for?'), findsOneWidget);

    // Put the shared router back so later tests start on Search.
    appRouter.go(AppRoutes.search);
  });
}
