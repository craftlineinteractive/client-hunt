import 'dart:io';

import 'package:clienthunt/core/constants/app_strings.dart';
import 'package:clienthunt/domain/models/models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the product decisions recorded in README section 9.
///
/// These are not styling tests: each one fails if copy or pricing drifts back to
/// a decision the product owner has already made.
void main() {
  test('no copy claims our data is verified', () {
    final File strings = File('lib/core/constants/app_strings.dart');
    expect(
      strings.existsSync(),
      isTrue,
      reason: 'Run this test from the project root.',
    );

    // Declaration names allowed to contain "verif". Two are the approved
    // negations ("not verified", "unverified") — they deny verification, which
    // is exactly the promised wording. One is the future Pro feature line.
    const Set<String> allowed = <String>{
      'notVerifiedNote',
      'unverifiedNotice',
      'aiVerifyFeature',
    };

    final RegExp risky = RegExp(r'verif', caseSensitive: false);
    final RegExp declaration = RegExp(
      r'(?:static\s+)?const\s+String\s+(\w+)\s*=',
    );

    final List<String> offenders = <String>[];
    final List<String> lines = strings.readAsLinesSync();
    // The declaration a line belongs to; a multi-line string literal keeps the
    // name from its opening line so `'…';` continuation lines are covered too.
    String? currentDeclaration;

    for (int index = 0; index < lines.length; index++) {
      final String line = lines[index];
      // Comments are not user-facing copy; only string literals matter here.
      if (line.trimLeft().startsWith('/')) {
        continue;
      }
      final RegExpMatch? match = declaration.firstMatch(line);
      if (match != null) {
        currentDeclaration = match.group(1);
      }
      if (risky.hasMatch(line) &&
          (currentDeclaration == null ||
              !allowed.contains(currentDeclaration))) {
        offenders.add('line ${index + 1}: ${line.trim()}');
      }
      if (line.trimRight().endsWith(';')) {
        currentDeclaration = null;
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Only ${allowed.join(', ')} may mention verification. Everywhere else '
          'the app says "Public contact details". Offenders:\n'
          '${offenders.join('\n')}',
    );

    // The one approved "verify" line must still exist, and must be the Pro
    // feature that ships with a "Coming soon" badge.
    expect(
      AppStrings.aiVerifyFeature,
      'AI to organize, format and verify leads',
    );
    expect(AppStrings.publicContactDetails, 'Public contact details');
  });

  test('sample Pro reviews follow kDebugMode', () {
    // True in debug (where tests run), false in any release build, so a release
    // build renders no invented testimonials at all.
    expect(kShowSampleProReviews, kDebugMode);
  });

  test('the open-status filter has only any and open now', () {
    expect(OpenStatus.values, <OpenStatus>[OpenStatus.any, OpenStatus.openNow]);
    expect(
      OpenStatus.values.map((OpenStatus value) => value.displayName),
      isNot(contains('Recently active')),
    );
  });

  test('Pro prices are the approved values and every caption is derived', () {
    expect(ProPlan.yearly.priceInRupees, 2999);
    expect(ProPlan.monthly.priceInRupees, 299);
    expect(ProPlan.weekly.priceInRupees, 99);
    expect(ProPlan.all, hasLength(3));

    expect(ProPlan.yearly.formattedPrice, '₹2,999');
    expect(ProPlan.yearly.priceLabel, '₹2,999 / year');
    expect(ProPlan.monthly.priceLabel, '₹299 / month');
    expect(ProPlan.weekly.priceLabel, '₹99 / week');

    // Derived, not literal: ₹2,999 / 12 rounds to ₹250 and saves 16%.
    expect(ProPlan.yearly.monthlyEquivalentInRupees, 250);
    expect(ProPlan.yearly.caption, 'About ₹250 / month');
    expect(ProPlan.yearly.savingsPercent, 16);
    expect(ProPlan.yearly.savingsLabel, 'Save 16%');
    expect(ProPlan.yearly.billingSummary, '₹2,999 billed yearly');
    expect(ProPlan.yearly.displayBadges, <String>['Best value', 'Save 16%']);

    // Non-yearly plans carry no savings claim.
    expect(ProPlan.monthly.savingsLabel, isNull);
    expect(ProPlan.weekly.monthlyEquivalentInRupees, isNull);
  });

  test('no stray price text exists anywhere under lib/', () {
    final Directory lib = Directory('lib');
    expect(lib.existsSync(), isTrue);

    // Any rupee amount outside the plan constants would be a second source of
    // truth for pricing — including the old ₹249 drift.
    final RegExp rupeeAmount = RegExp(r'₹\s?\d');
    final List<String> offenders = <String>[];

    for (final FileSystemEntity entity in lib.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final String path = entity.path.replaceAll(r'\', '/');
      if (path.endsWith('domain/models/pro_plan.dart')) {
        continue;
      }
      final List<String> lines = entity.readAsLinesSync();
      for (int index = 0; index < lines.length; index++) {
        if (rupeeAmount.hasMatch(lines[index])) {
          offenders.add('$path:${index + 1}  ${lines[index].trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Prices may only be written in ProPlan. Derive captions instead:\n'
          '${offenders.join('\n')}',
    );
  });
}
