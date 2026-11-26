import 'dart:async';

import '../../domain/repositories/quota_repository.dart';
import 'dummy_data.dart';

/// Counts today's free searches in memory, starting at 3 of 5 remaining.
///
/// [consumeOne] never goes below zero: the Search screen asks the
/// `FeatureGate` first, so this is a counter, not an enforcer.
class FakeQuotaRepository implements QuotaRepository {
  FakeQuotaRepository({
    int remainingToday =
        DummyData.dailySearchLimit - DummyData.searchesUsedToday,
    this.latency = const Duration(milliseconds: 150),
  }) : _remaining = remainingToday;

  /// Simulated write latency.
  final Duration latency;

  int _remaining;

  final StreamController<int> _changes = StreamController<int>.broadcast();

  @override
  Stream<int> watchRemainingToday() async* {
    yield _remaining;
    await for (final int remaining in _changes.stream) {
      yield remaining;
    }
  }

  @override
  Future<int> consumeOne() async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
    if (_remaining > 0) {
      _remaining--;
    }
    if (!_changes.isClosed) {
      _changes.add(_remaining);
    }
    return _remaining;
  }

  /// Current count without subscribing.
  int get remainingToday => _remaining;

  /// Releases the change stream.
  Future<void> dispose() => _changes.close();
}
