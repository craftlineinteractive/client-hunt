import 'package:clienthunt/core/utils/relative_time.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Recent row's meta line is the only place a search timestamp appears, and
/// it must never say something wrong ("in 2 days") for a clock skew or a fresh
/// search.
void main() {
  final DateTime now = DateTime(2026, 11, 26, 12);

  String at(Duration ago) => relativeTime(now.subtract(ago), now: now);

  test('under a minute and future times read as just now', () {
    expect(at(const Duration(seconds: 59)), 'just now');
    expect(
      relativeTime(now.add(const Duration(minutes: 5)), now: now),
      'just now',
    );
  });

  test('minutes and hours are pluralized', () {
    expect(at(const Duration(minutes: 1)), '1 minute ago');
    expect(at(const Duration(minutes: 5)), '5 minutes ago');
    expect(at(const Duration(hours: 1)), '1 hour ago');
    expect(at(const Duration(hours: 23)), '23 hours ago');
  });

  test('the day buckets are Yesterday, then days, then a date', () {
    expect(at(const Duration(days: 1)), 'Yesterday');
    expect(at(const Duration(days: 2)), '2 days ago');
    expect(at(const Duration(days: 6)), '6 days ago');
    expect(at(const Duration(days: 7)), '19 Nov 2026');
    expect(at(const Duration(days: 365)), '26 Nov 2025');
  });

  test('the date bucket is the same test the helper exposes', () {
    expect(
      isRelativeTimeDateBucket(now.subtract(const Duration(days: 6)), now: now),
      isFalse,
    );
    expect(
      isRelativeTimeDateBucket(now.subtract(const Duration(days: 7)), now: now),
      isTrue,
    );
  });
}
