import 'package:isar_community/isar.dart';

part 'app_settings.g.dart';

/// Singleton configuration class for the application stored in the Isar database.
/// 
/// `AppSettings` holds all persistent global configurations for the app, including
/// UI preferences, server connection details, inference model settings, agronomic 
/// parameters, and location data. Since it acts as a singleton, its `id` is always 1.
@collection
class AppSettings {
  /// Singleton identifier. Fixed to 1 to ensure only one settings instance exists.
  Id id = 1;

  /// Indicates if this is the first time the app is being launched.
  bool isFirstTime = true;
  
  /// The UI theme mode of the application. 
  /// Accepted values are: 'system', 'light', or 'dark'.
  String themeMode = 'system';
  
  /// The protocol scheme used to connect to the TFM backend server (e.g., 'http' or 'https').
  String tfmServerScheme = 'http';
  
  /// The hostname or IP address of the TFM backend server.
  String tfmServerUrl = 'localhost';
  
  /// The port number used to connect to the TFM backend server.
  int tfmServerPort = 3000;
  
  /// The authentication token or API key required by the TFM backend server.
  String tfmServerApiKey = 'secret_tfm_token';
  
  /// The frequency, in hours, at which the app automatically synchronizes data with the server.
  int syncScheduleHours = 24;

  /// The name or identifier of the selected TensorFlow Lite or Random Forest model for inference.
  String selectedTfliteModel = 'random_forest.dart';
  
  /// Flag to invert the output of the model if the specific model predicts the opposite meaning.
  bool invertModelOutput = false;
  
  /// Flag to permit using OpenMeteo as a fallback service to fill in missing weather data.
  bool permitOpenMeteoFill = true;
  
  /// Flag to always force the inference process, bypassing caching or schedule restrictions.
  bool alwaysForceInference = false;

  /// The hour (0-23) defining the start of the agronomic day for calculations.
  int agronomicDayStart = 19;
  
  /// The hour (0-23) defining the end of the agronomic day for calculations.
  int agronomicDayEnd = 10;
  
  /// The minimum acceptable soil humidity percentage threshold.
  double minHumidity = 60.0;

  /// The manually entered latitude coordinate.
  double manualLat = 40.4168;
  
  /// The manually entered longitude coordinate.
  double manualLon = -3.7038;

  /// The latitude coordinate acquired via GPS.
  double gpsLat = 40.4168;
  
  /// The longitude coordinate acquired via GPS.
  double gpsLon = -3.7038;
  
  /// Flag indicating whether the application should use GPS-provided location data
  /// instead of the manually configured location.
  bool isGpsEnabled = true;
}
