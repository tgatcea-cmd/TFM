import "dart:async";
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tfm_app/features/weather/weather_data.dart';

/// A client for fetching weather forecast and historical data from the Open-Meteo API.
///
/// This client provides methods to retrieve hourly weather data including temperature,
/// humidity, radiation, and precipitation for a specific geographical location.
class OpenMeteoClient {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  /// The latitude of the location to fetch weather data for.
  final double latitude;

  /// The longitude of the location to fetch weather data for.
  final double longitude;

  /// Creates a new instance of [OpenMeteoClient].
  ///
  /// Requires [latitude] and [longitude] to specify the geographic coordinates.
  OpenMeteoClient({required this.latitude, required this.longitude});

  /// Fetches weather forecast or historical data.
  ///
  /// If [referenceDate] is provided, it retrieves data from 48 hours before
  /// to 24-48 hours after the given date. If the [referenceDate] is older than 90 days,
  /// it automatically falls back to the historical archive API.
  /// If no [referenceDate] is provided, it fetches the forecast for the current date,
  /// including 48 hours of past data and 48 hours of future forecast.
  ///
  /// Returns a [WeatherData] object containing the parsed hourly weather data.
  /// Throws an [Exception] if the HTTP request fails or returns a non-200 status code.
  Future<WeatherData> fetchForecast({DateTime? referenceDate}) async {
    Uri url;

    if (referenceDate != null) {
      final start = referenceDate.subtract(const Duration(days: 2));
      final end = referenceDate.add(const Duration(days: 1));
      final startDate = start.toIso8601String().split('T')[0];
      final endDate = end.toIso8601String().split('T')[0];

      final isHistorical = start.isBefore(DateTime.now().subtract(const Duration(days: 90)));
      final baseUrlToUse = isHistorical 
          ? 'https://archive-api.open-meteo.com/v1/archive' 
          : _baseUrl;

      url = Uri.parse(
        '$baseUrlToUse?latitude=$latitude&longitude=$longitude'
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
