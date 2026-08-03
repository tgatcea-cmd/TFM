import "dart:async";
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tfm_app/features/weather/weather_data.dart';

class OpenMeteoClient {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  final double latitude;
  final double longitude;

  OpenMeteoClient({required this.latitude, required this.longitude});



  /// Fetches forecast data relative to referenceDate (or current date if null).
  /// Slices 48 hours past and 24-48 hours future relative to the referenceDate.
  Future<WeatherData> fetchForecast({DateTime? referenceDate}) async {
    Uri url;

    // ponytail: timezone=auto ensures hourly weather arrays match local solar time at (lat, lon)
    if (referenceDate != null) {
      final startDate = referenceDate.subtract(const Duration(days: 2)).toIso8601String().split('T')[0];
      final endDate = referenceDate.add(const Duration(days: 1)).toIso8601String().split('T')[0];
      url = Uri.parse(
        '$_baseUrl?latitude=$latitude&longitude=$longitude'
        '&start_date=$startDate&end_date=$endDate'
        '&hourly=temperature_2m,relative_humidity_2m,shortwave_radiation,precipitation'
        '&timezone=auto'
      );
    } else {
      url = Uri.parse(
        '$_baseUrl?latitude=$latitude&longitude=$longitude'
        '&forecast_days=2'
        '&past_days=2'
        '&hourly=temperature_2m,relative_humidity_2m,shortwave_radiation,precipitation'
        '&timezone=auto'
      );
    }

    final response = await http.get(url).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      return WeatherData.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load forecast weather: ${response.statusCode} - ${response.body}');
    }
  }
}

