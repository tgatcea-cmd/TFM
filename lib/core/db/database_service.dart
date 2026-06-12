import 'package:realm/realm.dart';
import '../../data/schemas/soil_humidity_schema.dart';
import '../../data/schemas/weather_schema.dart';
import '../../data/schemas/prediction_schema.dart';
import '../../data/schemas/location_schema.dart';

class DatabaseService {
  late Realm _realm;

  DatabaseService() {
    final config = Configuration.local([
      SoilHumidityRecord.schema,
      WeatherRecord.schema,
      PredictionRecord.schema,
      LocationSettings.schema,
    ]);
    _realm = Realm(config);
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

  // Soil Humidity
  void saveSoilHumidity(int timestamp, double value) {
    _realm.write(() {
      _realm.add(SoilHumidityRecord(timestamp, value), update: true);
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

  // Predictions
  void savePrediction(int timestamp, double predictedHumidity, String recommendation) {
    _realm.write(() {
      _realm.add(PredictionRecord(timestamp, predictedHumidity, recommendation), update: true);
    });
  }

  List<PredictionRecord> getPredictionHistory() {
    return _realm.all<PredictionRecord>().toList();
  }

  void clearDatabase() {
    _realm.write(() {
      _realm.deleteAll<SoilHumidityRecord>();
      _realm.deleteAll<WeatherRecord>();
      _realm.deleteAll<PredictionRecord>();
    });
  }

  void close() {
    _realm.close();
  }
}
