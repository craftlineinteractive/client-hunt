import 'package:clienthunt/core/theme/app_theme.dart';
import 'package:clienthunt/dev/design_gallery_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('design gallery renders in light and dark without overflow', (
    WidgetTester tester,
  ) async {
    // A 390 × 844 phone viewport, the mockup canvas.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: mode,
            home: const DesignGalleryPage(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Design gallery'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Walk the whole page so every section is laid out at this width.
      for (int step = 0; step < 24; step++) {
        await tester.drag(
          find.byType(ListView),
          const Offset(0, -400),
          warnIfMissed: false,
        );
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
      expect(find.text('Bottom navigation'), findsOneWidget);
    }
  });
}
