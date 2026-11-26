import 'package:flutter/foundation.dart';

import 'search_query.dart';

/// One past search, shown in the Home "Recent" list.
///
/// The home mockup renders "Dentists in Ahmedabad" with "42 leads · Maps · 2 days
/// ago", so the entry keeps the query, the result count and when it ran. Tapping a
/// row re-runs the query.
@immutable
class SearchHistoryEntry {
  const SearchHistoryEntry({
    required this.id,
    required this.query,
    required this.resultCount,
    required this.searchedAt,
  }) : assert(resultCount >= 0, 'A result count cannot be negative');

  /// Stable local identifier.
  final String id;

  /// The query that produced these results.
  final SearchQuery query;

  /// How many leads the search returned.
  final int resultCount;

  /// When the search ran.
  final DateTime searchedAt;

  /// Copy with selected fields replaced.
  SearchHistoryEntry copyWith({
    String? id,
    SearchQuery? query,
    int? resultCount,
    DateTime? searchedAt,
  }) {
    return SearchHistoryEntry(
      id: id ?? this.id,
      query: query ?? this.query,
      resultCount: resultCount ?? this.resultCount,
      searchedAt: searchedAt ?? this.searchedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SearchHistoryEntry &&
            other.id == id &&
            other.query == query &&
            other.resultCount == resultCount &&
            other.searchedAt == searchedAt;
  }

  @override
  int get hashCode => Object.hash(id, query, resultCount, searchedAt);

  @override
  String toString() =>
      'SearchHistoryEntry(${query.displayTitle}, $resultCount)';
}
