import 'package:isar_community/isar.dart';

part 'app_settings.g.dart';

@collection
class AppSettings {
  Id id = 1; // Singleton

  // App settings
  bool isFirstTime = true;
  String themeMode = 'system'; // 'system', 'light', 'dark'
  
  // Server settings
  String tfmServerScheme = 'http';
  String tfmServerUrl = 'localhost';
  int tfmServerPort = 3000;
  String tfmServerApiKey = 'secret_tfm_token';
  int syncScheduleHours = 24; // auto sync schedule

  // Inference & behavior settings
  String selectedTfliteModel = 'random_forest.dart';
  bool invertModelOutput = false;
  bool permitOpenMeteoFill = true;
  bool alwaysForceInference = false;

  // Agronomic configuration
  int agronomicDayStart = 19; // Default 19hrs
  int agronomicDayEnd = 9; // Default 9hrs
  double minHumidity = 60.0;

  // Location settings (Manual)
  double manualLat = 40.4168;
  double manualLon = -3.7038;

  // Location settings (GPS)
  double gpsLat = 40.4168;
  double gpsLon = -3.7038;
  bool isGpsEnabled = true;
}
