/// Configuration model for location-specific settings.
///
/// Encapsulates geographic coordinates and a flag indicating whether
/// these coordinates were obtained via GPS or manually set.
class LocationSettings {
  /// The latitude coordinate of the location.
  final double latitude;

  /// The longitude coordinate of the location.
  final double longitude;

  /// Indicates if the location was determined using GPS (true) or
  /// provided manually (false).
  final bool isGps;

  /// Creates a new [LocationSettings] instance.
  ///
  /// Parameters:
  /// - [latitude]: The latitude coordinate.
  /// - [longitude]: The longitude coordinate.
  /// - [isGps]: Whether the location was sourced from GPS.
  LocationSettings(this.latitude, this.longitude, this.isGps);
}
