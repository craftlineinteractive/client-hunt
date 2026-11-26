import 'package:clienthunt/core/constants/nav_tabs.dart';
import 'package:clienthunt/core/theme/app_theme.dart';
import 'package:clienthunt/shared/widgets/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the tab constant defines the three approved tabs', () {
    expect(navTabs, hasLength(3));
    expect(navTabs.map((NavTab tab) => tab.label), <String>[
      'Search',
      'Saved',
      'Settings',
    ]);
    // No History screen exists, so no History tab may appear.
    expect(navTabs.any((NavTab tab) => tab.label == 'History'), isFalse);
  });

  testWidgets('AppBottomNav shows exactly the tabs from the constant', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          bottomNavigationBar: AppBottomNav(
            currentIndex: 0,
            onTap: (int index) {},
          ),
        ),
      ),
    );

    expect(find.byType(AppBottomNav), findsOneWidget);
    for (final NavTab tab in navTabs) {
      expect(
        find.descendant(
          of: find.byType(AppBottomNav),
          matching: find.text(tab.label),
        ),
        findsOneWidget,
      );
    }
    expect(find.text('History'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(AppBottomNav),
        matching: find.byType(Icon),
      ),
      findsNWidgets(navTabs.length),
    );
  });

  testWidgets('tapping a tab reports its index', (WidgetTester tester) async {
    int? tapped;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          bottomNavigationBar: AppBottomNav(
            currentIndex: 0,
            onTap: (int index) => tapped = index,
          ),
        ),
      ),
    );

    await tester.tap(
      find.descendant(
        of: find.byType(AppBottomNav),
        matching: find.text('Settings'),
      ),
    );
    expect(tapped, 2);
  });
}
