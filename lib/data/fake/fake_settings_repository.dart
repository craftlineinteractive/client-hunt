import 'dart:async';

import '../../domain/models/models.dart';
import '../../domain/repositories/settings_repository.dart';

/// In-memory [AppSettings]: the defaults the Settings screen starts from, and
/// every later change for the session.
class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({
    AppSettings initial = const AppSettings(),
    this.latency = const Duration(milliseconds: 150),
  }) : _value = initial;

  /// Simulated write latency.
  final Duration latency;

  AppSettings _value;

  final StreamController<AppSettings> _changes =
      StreamController<AppSettings>.broadcast();

  @override
  Stream<AppSettings> watch() async* {
    yield _value;
    await for (final AppSettings settings in _changes.stream) {
      yield settings;
    }
  }

  @override
  Future<void> update(AppSettings settings) async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
    _value = settings;
    if (!_changes.isClosed) {
      _changes.add(settings);
    }
  }

  /// The current value without subscribing; handy in debug pages and tests.
  AppSettings get value => _value;

  /// Releases the change stream.
  Future<void> dispose() => _changes.close();
}
