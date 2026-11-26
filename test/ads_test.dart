import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The product has **no banner or native ad placements**: only an opt-in
/// rewarded ad before a Free search and occasional interstitials at natural
/// breaks (README "Ads model"). This guard keeps a banner from creeping back in
/// through a widget, a string or a comment.
void main() {
  test('lib/ contains no banner ad placeholder or banner copy', () {
    final Directory lib = Directory('lib');
    expect(
      lib.existsSync(),
      isTrue,
      reason: 'Run this test from the project root.',
    );

    final RegExp banner = RegExp('banner', caseSensitive: false);
    final List<String> offenders = <String>[];
    int scanned = 0;

    for (final FileSystemEntity entity in lib.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      scanned++;
      final String path = entity.path.replaceAll(r'\', '/');
      final List<String> lines = entity.readAsLinesSync();
      for (int index = 0; index < lines.length; index++) {
        final String line = lines[index];
        // Two kinds of mention are legitimate and allowed:
        // * Flutter's own `debugShowCheckedModeBanner` — a framework flag, not
        //   an ad placement;
        // * a sentence saying there are none ("no banner ads"), which is the
        //   documentation and copy this model requires.
        final bool isAllowed = RegExp(
          r'no\s*banner|noBanners|debugShowCheckedModeBanner',
          caseSensitive: false,
        ).hasMatch(line);
        if (line.contains('AdBannerPlaceholder')) {
          offenders.add('$path:${index + 1}  AdBannerPlaceholder');
        } else if (banner.hasMatch(line) && !isAllowed) {
          offenders.add('$path:${index + 1}  ${line.trim()}');
        }
      }
    }

    expect(scanned, greaterThan(10), reason: 'The scan found almost no files.');
    expect(
      offenders,
      isEmpty,
      reason:
          'ClientHunt has no banner ads. Remove the banner placement/copy:\n'
          '${offenders.join('\n')}',
    );
  });

  test('AdsStrings carries the rewarded model, not ad-slot copy', () {
    final String strings = File(
      'lib/core/constants/app_strings.dart',
    ).readAsStringSync();
    expect(strings, contains('rewardedTitle'));
    expect(strings, contains('testAdLabel'));
    expect(strings, isNot(contains('adHeadline')));
  });
}
