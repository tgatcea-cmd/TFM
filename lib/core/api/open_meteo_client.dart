import "dart:async";
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/weather_data.dart';

class OpenMeteoClient {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  final double latitude;
  final double longitude;

  OpenMeteoClient({required this.latitude, required this.longitude});



  /// Fetches forecast data for Today and Tomorrow, plus past 48 hours.
  Future<WeatherData> fetchForecast() async {
    final url = Uri.parse(
      '$_baseUrl?latitude=$latitude&longitude=$longitude'
      '&forecast_days=2'
      '&past_days=2'
      '&hourly=temperature_2m,relative_humidity_2m,shortwave_radiation,precipitation'
    );

    final response = await http.get(url).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      return WeatherData.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load forecast weather: ${response.statusCode} - ${response.body}');
    }
  }
}
