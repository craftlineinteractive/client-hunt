import 'dart:async';

import '../../domain/models/models.dart';
import '../../domain/repositories/search_history_repository.dart';
import 'dummy_data.dart';

/// In-memory recent searches, seeded with the two entries the mockup shows.
///
/// Re-running a query does not create a duplicate row: the existing entry moves to
/// the top with its new count and timestamp, which is what "Recent" should mean.
class FakeSearchHistoryRepository implements SearchHistoryRepository {
  FakeSearchHistoryRepository({
    DummyDataSet? data,
    this.latency = const Duration(milliseconds: 150),
  }) : _entries = <SearchHistoryEntry>[
         ...(data ?? DummyData.build()).recentSearches,
       ];

  /// Simulated write latency.
  final Duration latency;

  final List<SearchHistoryEntry> _entries;

  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Stream<List<SearchHistoryEntry>> watchRecent({int limit = 10}) async* {
    yield _snapshot(limit);
    await for (final Object? _ in _changes.stream) {
      yield _snapshot(limit);
    }
  }

  @override
  Future<SearchHistoryEntry> add(SearchHistoryEntry entry) async {
    await _pause();
    _entries.removeWhere(
      (SearchHistoryEntry existing) =>
          existing.query.displayTitle == entry.query.displayTitle,
    );
    _entries.insert(0, entry);
    _notify();
    return entry;
  }

  @override
  Future<void> clear() async {
    await _pause();
    _entries.clear();
    _notify();
  }

  /// Releases the change stream.
  Future<void> dispose() => _changes.close();

  List<SearchHistoryEntry> _snapshot(int limit) {
    final List<SearchHistoryEntry> sorted = <SearchHistoryEntry>[..._entries]
      ..sort(
        (SearchHistoryEntry a, SearchHistoryEntry b) =>
            b.searchedAt.compareTo(a.searchedAt),
      );
    return List<SearchHistoryEntry>.unmodifiable(sorted.take(limit));
  }

  Future<void> _pause() async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
  }

  void _notify() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }
}
