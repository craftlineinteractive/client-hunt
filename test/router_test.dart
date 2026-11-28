import 'dart:async';

import 'package:clienthunt/app.dart';
import 'package:clienthunt/core/constants/nav_tabs.dart';
import 'package:clienthunt/core/router/app_router.dart';
import 'package:clienthunt/features/lead_detail/lead_detail_page.dart';
import 'package:clienthunt/shared/widgets/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Bottom-navigation visibility is a routing rule, not a per-screen decision:
/// the three tab destinations live in the shell; everything else is pushed on the
/// root navigator and covers the bar.
void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ClientHuntApp()));
    await tester.pumpAndSettle();
  }

  setUp(() {
    appRouter.go(AppRoutes.search);
  });

  test('route constants and the tab constant agree', () {
    expect(
      AppRoutes.tabLocations,
      navTabs.map((NavTab tab) => tab.path).toList(),
    );
    expect(AppRoutes.tabLocations, <String>['/search', '/saved', '/settings']);
    expect(AppRoutes.leadDetailPath('lead-42'), '/lead/lead-42');
  });

  testWidgets('the bottom navigation is visible on all three tabs', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    for (final String tab in AppRoutes.tabLocations) {
      appRouter.go(tab);
      await tester.pumpAndSettle();
      expect(
        find.byType(AppBottomNav),
        findsOneWidget,
        reason: '$tab is a tab destination',
      );
    }
  });

  testWidgets('every pushed route covers the bottom navigation', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    Future<void> expectPushed(
      String label,
      void Function(BuildContext context) navigate, {
      void Function()? whilePushed,
      bool expectBackArrow = true,
    }) async {
      final BuildContext context = tester.element(find.byType(AppBottomNav));
      navigate(context);
      await tester.pumpAndSettle();

      expect(find.byType(AppBottomNav), findsNothing, reason: label);
      if (expectBackArrow) {
        // A Material `BackButton` or the app bar's own icon button (which carries
        // the "Go back" tooltip); both cover the same contract.
        final bool hasBackButton =
            find.byType(BackButton).evaluate().isNotEmpty ||
            find.byTooltip('Go back').evaluate().isNotEmpty;
        expect(hasBackButton, isTrue, reason: label);
      }
      whilePushed?.call();

      appRouter.pop();
      await tester.pumpAndSettle();
      expect(
        find.byType(AppBottomNav),
        findsOneWidget,
        reason: '$label closes back to the tab it was opened from',
      );
    }

    await expectPushed(
      'results',
      (BuildContext context) => AppNavigator.goToResults(context),
    );
    await expectPushed(
      'lead detail',
      (BuildContext context) => AppNavigator.goToLead(context, 'lead-42'),
      // The path parameter reaches the real screen.
      whilePushed: () {
        final LeadDetailPage page = tester.widget<LeadDetailPage>(
          find.byType(LeadDetailPage),
        );
        expect(page.leadId, 'lead-42');
      },
    );

    await expectPushed(
      'filters',
      (BuildContext context) => AppNavigator.openFilters(context),
    );
    await expectPushed(
      'export',
      (BuildContext context) => AppNavigator.openExport(context),
    );
    await expectPushed(
      'pro',
      (BuildContext context) => AppNavigator.openPro(context),
    );
    await expectPushed(
      'debug gallery',
      (BuildContext context) => AppNavigator.openDesignGallery(context),
      // The gallery's app bar uses the close icon variant, not a BackButton.
      expectBackArrow: false,
    );
  });

  testWidgets('results returns to the Search tab', (WidgetTester tester) async {
    await pumpApp(tester);

    final BuildContext context = tester.element(find.byType(AppBottomNav));
    unawaited(AppNavigator.goToResults(context));
    await tester.pumpAndSettle();
    expect(find.byType(AppBottomNav), findsNothing);

    appRouter.pop();
    await tester.pumpAndSettle();
    expect(find.text('Who are you looking for?'), findsOneWidget);
  });
}
