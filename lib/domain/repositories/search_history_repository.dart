import '../models/models.dart';

/// Recent searches, shown on the Search screen.
///
/// Implemented by a fake now and by prompt C's local store later. The list is
/// newest-first and capped by the caller's [limit].
abstract interface class SearchHistoryRepository {
  /// The most recent searches, newest first.
  Stream<List<SearchHistoryEntry>> watchRecent({int limit = 10});

  /// Records a completed search. Re-running the same query updates its timestamp
  /// and count instead of adding a duplicate row.
  Future<SearchHistoryEntry> add(SearchHistoryEntry entry);

  /// Removes every entry ("Clear all").
  Future<void> clear();
}
