import 'dart:io';
import 'package:realm/realm.dart';
import '../../data/schemas/soil_humidity_schema.dart';
import '../../data/schemas/weather_schema.dart';
import '../../data/schemas/prediction_schema.dart';
import '../../data/schemas/location_schema.dart';
import '../../data/schemas/device_schema.dart';
import '../../data/schemas/app_settings_schema.dart';

class DatabaseService {
  late Realm _realm;

  DatabaseService() {
    final config = Configuration.local([
      SoilHumidityRecord.schema,
      WeatherRecord.schema,
      PredictionRecord.schema,
      LocationSettings.schema,
      SavedDevice.schema,
      AppSettings.schema,
    ]);
    _realm = Realm(config);
    
    // Seed default stations if empty
    if (_realm.all<SavedDevice>().isEmpty) {
      _realm.write(() {
        _realm.add(SavedDevice("00:11:22:33:44:01", "Cesar's IoT Station (0x01)"));
        _realm.add(SavedDevice("00:11:22:33:44:02", "Madrid Station Alpha"));
        _realm.add(SavedDevice("00:11:22:33:44:03", "Valencia Station Beta"));
        _realm.add(SavedDevice("00:11:22:33:44:04", "Sevilla Station Gamma"));
      });
    }

    // Seed demo data if database is empty to ensure unified chart works
    if (_realm.all<SoilHumidityRecord>().isEmpty) {
      _seedData();
    }
  }

  void _seedData() {
    _realm.write(() {
      final now = DateTime.now();
      
      // Seed 48 hours of Soil Humidity
      for (int i = 48; i >= 0; i--) {
        final ts = now.subtract(Duration(hours: i)).millisecondsSinceEpoch;
        final val = 42.0 + (i % 7) * 0.8 + ((i * 3) % 5) * 0.4;
        _realm.add(SoilHumidityRecord(ts, val), update: true);
      }

      // Seed 48 hours of Weather History
      for (int i = 48; i >= 0; i--) {
        final ts = now.subtract(Duration(hours: i)).millisecondsSinceEpoch;
        final temp = 18.0 + (i % 6) * 1.2;
        final hum = 50.0 + (i % 4) * 5.0;
        final hour = now.subtract(Duration(hours: i)).hour;
        final rad = (hour >= 8 && hour <= 20)
            ? (12 - (hour - 14).abs()) * 70.0
            : 0.0;
        _realm.add(WeatherRecord(ts, temp, hum, rad, 0.0), update: true);
      }

      // Seed 48 hours of Prediction History
      for (int i = 48; i >= 0; i--) {
        final ts = now.subtract(Duration(hours: i)).millisecondsSinceEpoch;
        final predHum = 40.0 + (i % 5) * 1.5;
        final rec = (predHum > 45.0)
            ? 'SATURATION RISK: Irrigation perjudicial tomorrow. DO NOT IRRIGATE.'
            : 'HEALTHY: Irrigation safe / Not perjudicial.';
        _realm.add(PredictionRecord(ts, predHum, rec), update: true);
      }
    });
  }

  // Location Settings
  LocationSettings getLocationSettings() {
    final settings = _realm.find<LocationSettings>(1);
    if (settings == null) {
      // Default to Madrid if not found
      final defaultSettings = LocationSettings(1, 40.4168, -3.7038, false);
      _realm.write(() => _realm.add(defaultSettings));
      return defaultSettings;
    }
    return settings;
  }

  void saveLocationSettings(double lat, double lon, bool isGps) {
    _realm.write(() {
      _realm.add(LocationSettings(1, lat, lon, isGps), update: true);
    });
  }

  LocationSettings getGpsConfig() {
    final settings = _realm.find<LocationSettings>(3);
    if (settings == null) {
      final defaultGps = LocationSettings(3, 40.4168, -3.7038, true);
      _realm.write(() => _realm.add(defaultGps));
      return defaultGps;
    }
    return settings;
  }

  void saveGpsConfig(double lat, double lon) {
    _realm.write(() {
      _realm.add(LocationSettings(3, lat, lon, true), update: true);
    });
  }

  // App Settings
  AppSettings getAppSettings() {
    final settings = _realm.find<AppSettings>(1);
    if (settings == null) {
      final defaultSettings = AppSettings(
        1,
        'http://10.0.2.2', // default local TFM server IP (e.g. Android Emulator host loopback)
        3000,
        '',
        'random_forest.dart',
        false,
        true,
        false,
      );
      _realm.write(() => _realm.add(defaultSettings));
      return defaultSettings;
    }
    return settings;
  }

  // ponytail: local file storage for custom minHumidity config
  double getMinHumidity() {
    try {
      final file = File('.min_humidity');
      if (file.existsSync()) {
        return double.tryParse(file.readAsStringSync()) ?? 60.0;
      }
    } catch (_) {}
    return 60.0;
  }

  void saveMinHumidity(double value) {
    try {
      final file = File('.min_humidity');
      file.writeAsStringSync(value.toString());
    } catch (_) {}
  }

  void saveAppSettings({
    required String tfmServerUrl,
    required int tfmServerPort,
    required String tfmServerApiKey,
    required String selectedTfliteModel,
    required bool invertModelOutput,
    required bool permitOpenMeteoFill,
    required bool alwaysForceInference,
  }) {
    _realm.write(() {
      _realm.add(
        AppSettings(
          1,
          tfmServerUrl,
          tfmServerPort,
          tfmServerApiKey,
          selectedTfliteModel,
          invertModelOutput,
          permitOpenMeteoFill,
          alwaysForceInference,
        ),
        update: true,
      );
    });
  }

  // Soil Humidity
  void saveSoilHumidity(int timestamp, double value) {
    _realm.write(() {
      _realm.add(SoilHumidityRecord(timestamp, value), update: true);
    });
  }

  void saveSoilHumidityBatch(List<SoilHumidityRecord> records) {
    _realm.write(() {
      _realm.addAll(records, update: true);
    });
  }

  List<SoilHumidityRecord> getSoilHumidityHistory() {
    return _realm.all<SoilHumidityRecord>().toList();
  }

  // Weather
  void saveWeather(int timestamp, double temp, double hum, double rad, double prec) {
    _realm.write(() {
      _realm.add(WeatherRecord(timestamp, temp, hum, rad, prec), update: true);
    });
  }

  List<WeatherRecord> getWeatherHistory() {
    return _realm.all<WeatherRecord>().toList();
  }

  double getTodayRadiationSum() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final records = _realm.all<WeatherRecord>().query('timestamp >= $startOfDay');
    
    if (records.isEmpty) return 0.0;
    return records.map((r) => r.radiation).reduce((a, b) => a + b);
  }

  int getSoilHumidityCount(int sinceMs) {
    return _realm.all<SoilHumidityRecord>().query('timestamp >= $sinceMs').length;
  }

  int getWeatherCount(int sinceMs) {
    return _realm.all<WeatherRecord>().query('timestamp >= $sinceMs').length;
  }


  // Predictions
  void savePrediction(int timestamp, double predictedHumidity, String recommendation) {
    _realm.write(() {
      _realm.add(PredictionRecord(timestamp, predictedHumidity, recommendation), update: true);
    });
  }

  List<PredictionRecord> getPredictionHistory() {
    return _realm.all<PredictionRecord>().toList();
  }

  void clearAllData() {
    _realm.write(() {
      _realm.deleteAll<SoilHumidityRecord>();
      _realm.deleteAll<WeatherRecord>();
      _realm.deleteAll<PredictionRecord>();
    });
  }

  String getDatabasePath() {
    return _realm.config.path;
  }


  // Saved Devices
  List<SavedDevice> getSavedDevices() {
    return _realm.all<SavedDevice>().toList();
  }

  void saveDevice(String id, String name) {
    _realm.write(() {
      _realm.add(SavedDevice(id, name), update: true);
    });
  }

  void deleteDevice(String id) {
    _realm.write(() {
      final dev = _realm.find<SavedDevice>(id);
      if (dev != null) {
        _realm.delete(dev);
      }
    });
  }

  void close() {
    _realm.close();
  }
}
