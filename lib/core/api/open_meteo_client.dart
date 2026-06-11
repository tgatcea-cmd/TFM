import "dart:async";
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/weather_data.dart';

class OpenMeteoClient {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const String _archiveUrl = 'https://archive-api.open-meteo.com/v1/archive';

  final double latitude;
  final double longitude;

  OpenMeteoClient({required this.latitude, required this.longitude});

  /// Helper method to perform HTTP GET with retries and timeout
  Future<http.Response> _getWithRetry(Uri url, {int retries = 3, Duration timeout = const Duration(seconds: 10)}) async {
    int attempts = 0;
    while (attempts < retries) {
      try {
        attempts++;
        return await http.get(url).timeout(timeout);
      } on TimeoutException catch (e) {
        if (attempts >= retries) {
          throw Exception('Request timed out after $retries attempts: $e');
        }
        print('Request timed out. Retrying attempt $attempts/$retries in ${attempts * 2}s...');
        await Future.delayed(Duration(seconds: attempts * 2));
      } catch (e) {
        if (attempts >= retries) {
          throw Exception('Request failed after $retries attempts: $e');
        }
        print('Request failed: $e. Retrying attempt $attempts/$retries in ${attempts * 2}s...');
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
    throw Exception('Request failed unexpectedly');
  }

  /// Fetches historical data for the last 24h lag.
  /// As per instructions: if it's 19:00, fetch from 18:00 yesterday to 18:59 today.
  Future<WeatherData> fetchHistoricalLag() async {
    final now = DateTime.now();
    final endTime = now.subtract(const Duration(minutes: 1)); // 18:59 if now is 19:00
    final startTime = endTime.subtract(const Duration(hours: 23)); // 24 hours total

    final startStr = startTime.toIso8601String().split('T')[0];
    final endStr = endTime.toIso8601String().split('T')[0];

    final url = Uri.parse(
      '$_archiveUrl?latitude=$latitude&longitude=$longitude'
      '&start_date=$startStr&end_date=$endStr'
      '&hourly=temperature_2m,relative_humidity_2m,shortwave_radiation,precipitation'
    );

    final response = await _getWithRetry(url);
    if (response.statusCode == 200) {
      return WeatherData.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load historical weather: ${response.statusCode} - ${response.body}');
    }
  }

  /// Fetches forecast data for Today and Tomorrow.
  Future<WeatherData> fetchForecast() async {
    final url = Uri.parse(
      '$_baseUrl?latitude=$latitude&longitude=$longitude'
      '&forecast_days=2'
      '&hourly=temperature_2m,relative_humidity_2m,shortwave_radiation,precipitation'
    );

    final response = await _getWithRetry(url);
    if (response.statusCode == 200) {
      return WeatherData.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load forecast weather: ${response.statusCode} - ${response.body}');
    }
  }
}
