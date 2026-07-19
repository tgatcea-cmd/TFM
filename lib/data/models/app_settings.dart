import 'package:isar_community/isar.dart';

part 'app_settings.g.dart';

@collection
class AppSettings {
  Id id = 1; // Singleton

  // App settings
  String tfmServerUrl = 'http://10.0.2.2';
  int tfmServerPort = 3000;
  String tfmServerApiKey = '';
  String selectedTfliteModel = 'random_forest.dart';
  bool invertModelOutput = false;
  bool permitOpenMeteoFill = true;
  bool alwaysForceInference = false;

  // Location settings (Manual)
  double manualLat = 40.4168;
  double manualLon = -3.7038;

  // Location settings (GPS)
  double gpsLat = 40.4168;
  double gpsLon = -3.7038;
  bool isGpsEnabled = true;

  // Global settings
  double minHumidity = 60.0;
}
