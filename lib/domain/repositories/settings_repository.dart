import '../models/models.dart';

/// The user's app settings.
///
/// Implemented by a fake now and by prompt C's local store later. A single
/// [AppSettings] value is streamed, so every screen that changes a default sees
/// the change immediately.
abstract interface class SettingsRepository {
  /// The current settings, and every later change.
  Stream<AppSettings> watch();

  /// Persists a complete settings value.
  Future<void> update(AppSettings settings);
}
