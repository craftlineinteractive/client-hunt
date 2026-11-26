import 'package:flutter/foundation.dart';

/// Short, human relative time for history rows: \"2 days ago\".
///
/// Deliberately tiny and dependency-free (no `intl`): the app is English/INR
/// only for v1, so a 90-line helper beats a package. [now] is injectable, which is
/// what makes the output testable.
///
/// Buckets:
///
/// | Difference | Output |
/// |---|---|
/// | under a minute, or in the future | `just now` |
/// | under an hour | `5 minutes ago` (singular: `1 minute ago`) |
/// | under a day | `3 hours ago` |
/// | under two days | `Yesterday` |
/// | under seven days | `4 days ago` |
/// | older | `26 Nov 2025` |
String relativeTime(DateTime time, {DateTime? now}) {
  final DateTime reference = now ?? DateTime.now();
  final Duration difference = reference.difference(time);

  if (difference.inSeconds < 60) {
    return 'just now';
  }
  if (difference.inMinutes < 60) {
    return _plural(difference.inMinutes, 'minute');
  }
  if (difference.inHours < 24) {
    return _plural(difference.inHours, 'hour');
  }
  if (difference.inDays < 2) {
    return 'Yesterday';
  }
  if (difference.inDays < 7) {
    return _plural(difference.inDays, 'day');
  }
  return _date(time);
}

/// \"1 minute ago\" / \"5 minutes ago\".
String _plural(int value, String unit) =>
    value == 1 ? '1 $unit ago' : '$value ${unit}s ago';

const List<String> _months = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// \"26 Nov 2025\" — day, short month, year.
String _date(DateTime time) =>
    '${time.day} ${_months[time.month - 1]} ${time.year}';

/// True when [relativeTime] would print a date rather than a relative phrase.
@visibleForTesting
bool isRelativeTimeDateBucket(DateTime time, {DateTime? now}) {
  final DateTime reference = now ?? DateTime.now();
  return reference.difference(time).inDays >= 7;
}
