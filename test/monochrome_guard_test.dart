import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Enforces design rule 1: the UI is strictly monochrome and every color comes
/// from `lib/core/theme`.
///
/// Fails when any file under `lib/` outside `lib/core/theme/` contains:
/// * a `Color(0x…)` / `Color.fromARGB(…)` / `Color.fromRGBO(…)` literal, or
/// * a named Material color (`Colors.blue`, `Colors.red`, …).
///
/// `Colors.transparent` is allowed: it is the absence of a color, used for
/// invisible hit areas and ripples.
void main() {
  test('lib/ contains no hardcoded colors outside core/theme', () {
    final Directory lib = Directory('lib');
    expect(
      lib.existsSync(),
      isTrue,
      reason: 'Run this test from the project root.',
    );

    final RegExp colorLiteral = RegExp(
      r'Color\(\s*0x|Color\.fromARGB|Color\.fromRGBO',
    );
    final RegExp namedColor = RegExp(
      r'(?<![A-Za-z0-9_])Colors\.([A-Za-z0-9_]+)',
    );

    final List<String> offenders = <String>[];
    int scanned = 0;

    for (final FileSystemEntity entity in lib.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final String path = entity.path.replaceAll(r'\', '/');
      if (path.contains('core/theme/')) {
        continue;
      }
      scanned++;
      final List<String> lines = entity.readAsLinesSync();
      for (int index = 0; index < lines.length; index++) {
        final String line = lines[index];
        if (colorLiteral.hasMatch(line)) {
          offenders.add('$path:${index + 1}  color literal  →  ${line.trim()}');
        }
        for (final RegExpMatch match in namedColor.allMatches(line)) {
          if (match.group(1) == 'transparent') {
            continue;
          }
          offenders.add(
            '$path:${index + 1}  Colors.${match.group(1)}  →  ${line.trim()}',
          );
        }
      }
    }

    expect(scanned, greaterThan(10), reason: 'The scan found almost no files.');
    expect(
      offenders,
      isEmpty,
      reason:
          'Monochrome rule violated. Use AppColors.of(context) and theme tokens '
          'instead of hardcoded colors:\n${offenders.join('\n')}',
    );
  });
}
