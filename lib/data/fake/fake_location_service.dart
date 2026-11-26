import '../../domain/repositories/location_service.dart';

/// What the fake location service reports.
///
/// Debug builds switch this from the gallery so every Home state — found,
/// permission denied, unavailable — is reachable without a device permission
/// dialog.
enum FakeLocationOutcome {
  /// A city is resolved.
  found(displayName: 'Location: found'),

  /// The user declined permission.
  permissionDenied(displayName: 'Location: denied'),

  /// Services are off or the fix failed.
  unavailable(displayName: 'Location: unavailable');

  const FakeLocationOutcome({required this.displayName});

  /// Label for the debug panel.
  final String displayName;
}

/// Returns a fixed city after a short delay, or the configured failure.
///
/// No geolocator, no permission package, no platform channel: prompt E replaces
/// this implementation behind the same [LocationService] interface.
class FakeLocationService implements LocationService {
  FakeLocationService({
    this.outcome = FakeLocationOutcome.found,
    this.city = 'Ahmedabad',
    this.delay = const Duration(milliseconds: 600),
  });

  /// Which result to return.
  final FakeLocationOutcome outcome;

  /// City returned by [FakeLocationOutcome.found].
  final String city;

  /// Simulated fix latency, long enough to show a loading state.
  final Duration delay;

  @override
  Future<LocationResult> currentCity() async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return switch (outcome) {
      FakeLocationOutcome.found => LocationFound(city),
      FakeLocationOutcome.permissionDenied => const LocationPermissionDenied(),
      FakeLocationOutcome.unavailable => const LocationUnavailable(),
    };
  }
}
