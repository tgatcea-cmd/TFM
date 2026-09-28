/// Represents a collection of hourly weather data.
///
/// Contains arrays of timestamps and corresponding environmental metrics
/// such as temperature, humidity, solar radiation, and precipitation.
class WeatherData {
  /// The list of timestamps corresponding to each hourly measurement.
  final List<DateTime> time;

  /// The list of temperature measurements at 2 meters above ground level, in Celsius.
  final List<double> temperature2m;

  /// The list of relative humidity measurements at 2 meters above ground level, as percentages.
  final List<double> relativeHumidity2m;

  /// The list of shortwave radiation measurements, in W/m².
  final List<double> shortwaveRadiation;

  /// The list of precipitation measurements, in millimeters.
  final List<double> precipitation;

  /// Creates a new [WeatherData] instance containing the specified environmental data series.
  WeatherData({
    required this.time,
    required this.temperature2m,
    required this.relativeHumidity2m,
    required this.shortwaveRadiation,
    required this.precipitation,
  });

  /// Creates a [WeatherData] instance by parsing a JSON map.
  ///
  /// The JSON map must contain an 'hourly' key with arrays for 'time',
  /// 'temperature_2m', 'relative_humidity_2m', 'shortwave_radiation', and 'precipitation'.
  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final hourly = json['hourly'];
    return WeatherData(
      time: (hourly['time'] as List).map((t) {
        final s = t.toString();
        return DateTime.parse(s.endsWith('Z') ? s : '${s}Z').toLocal();
      }).toList(),
      temperature2m: (hourly['temperature_2m'] as List).map((v) => (v as num).toDouble()).toList(),
      relativeHumidity2m: (hourly['relative_humidity_2m'] as List).map((v) => (v as num).toDouble()).toList(),
      shortwaveRadiation: (hourly['shortwave_radiation'] as List).map((v) => (v as num).toDouble()).toList(),
      precipitation: (hourly['precipitation'] as List).map((v) => (v as num).toDouble()).toList(),
    );
  }
}
