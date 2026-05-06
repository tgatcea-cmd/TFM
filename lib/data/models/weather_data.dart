class WeatherData {
  final List<DateTime> time;
  final List<double> temperature2m;
  final List<double> relativeHumidity2m;
  final List<double> shortwaveRadiation;
  final List<double> precipitation;

  WeatherData({
    required this.time,
    required this.temperature2m,
    required this.relativeHumidity2m,
    required this.shortwaveRadiation,
    required this.precipitation,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final hourly = json['hourly'];
    return WeatherData(
      time: (hourly['time'] as List).map((t) => DateTime.parse(t)).toList(),
      temperature2m: (hourly['temperature_2m'] as List).map((v) => (v as num).toDouble()).toList(),
      relativeHumidity2m: (hourly['relative_humidity_2m'] as List).map((v) => (v as num).toDouble()).toList(),
      shortwaveRadiation: (hourly['shortwave_radiation'] as List).map((v) => (v as num).toDouble()).toList(),
      precipitation: (hourly['precipitation'] as List).map((v) => (v as num).toDouble()).toList(),
    );
  }
}
