/// Where the device thinks the user is.
///
/// A sealed result, so Home must handle all three: a found city fills the
/// location field; denied and unavailable are only a snackbar, never a crash.
/// Prompt E implements this with a platform permission flow; today the fake
/// returns a fixed city after a short delay.
sealed class LocationResult {
  const LocationResult();
}

/// A city was resolved (\"Ahmedabad\").
final class LocationFound extends LocationResult {
  const LocationFound(this.city);

  /// Canonical city name.
  final String city;

  @override
  String toString() => 'LocationFound($city)';
}

/// The user declined the location permission.
final class LocationPermissionDenied extends LocationResult {
  const LocationPermissionDenied();

  @override
  String toString() => 'LocationPermissionDenied()';
}

/// Location services are off, the fix timed out, or the platform refused.
final class LocationUnavailable extends LocationResult {
  const LocationUnavailable();

  @override
  String toString() => 'LocationUnavailable()';
}

/// Resolves the current city.
///
/// Deliberately tiny: Home only needs one city string. No geolocator or
/// permission package is added until prompt E, and this interface is the seam
/// that keeps that decision out of the UI.
abstract interface class LocationService {
  /// The current city, or why it could not be resolved. Never throws.
  Future<LocationResult> currentCity();
}
