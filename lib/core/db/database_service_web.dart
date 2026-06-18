import '../../data/models/models.dart';

class DatabaseService {
  final List<SoilHumidityRecord> _soilHumidityHistory = [];
  final List<WeatherRecord> _weatherHistory = [];
  final List<PredictionRecord> _predictionHistory = [];
  final List<SavedDevice> _savedDevices = [];
  late LocationSettings _locationSettings;
  late LocationSettings _gpsConfig;

  DatabaseService() {
    _locationSettings = LocationSettings(1, 40.4168, -3.7038, false);
    _gpsConfig = LocationSettings(3, 40.4168, -3.7038, true);
    
    // Seed default stations
    _savedDevices.add(SavedDevice("00:11:22:33:44:01", "Cesar's IoT Station (0x01)"));
    _savedDevices.add(SavedDevice("00:11:22:33:44:02", "Madrid Station Alpha"));
    _savedDevices.add(SavedDevice("00:11:22:33:44:03", "Valencia Station Beta"));
    _savedDevices.add(SavedDevice("00:11:22:33:44:04", "Sevilla Station Gamma"));
    
    _seedData();
  }

  void _seedData() {
    final now = DateTime.now();
    
    // Seed 48 hours of Soil Humidity (once per hour)
    for (int i = 48; i >= 0; i--) {
      final ts = now.subtract(Duration(hours: i)).millisecondsSinceEpoch;
      // Fluctuating soil humidity around 45%
      final val = 42.0 + (i % 7) * 0.8 + ((i * 3) % 5) * 0.4;
      _soilHumidityHistory.add(SoilHumidityRecord(ts, val));
    }

    // Seed 48 hours of Weather History
    for (int i = 48; i >= 0; i--) {
      final ts = now.subtract(Duration(hours: i)).millisecondsSinceEpoch;
      final temp = 18.0 + (i % 6) * 1.2;
      final hum = 50.0 + (i % 4) * 5.0;
      // Radiation peaks during the day (e.g. noon)
      final hour = now.subtract(Duration(hours: i)).hour;
      final rad = (hour >= 8 && hour <= 20)
          ? (12 - (hour - 14).abs()) * 70.0
          : 0.0;
      _weatherHistory.add(WeatherRecord(ts, temp, hum, rad, 0.0));
    }

    // Seed 48 hours of Prediction History
    for (int i = 48; i >= 0; i--) {
      final ts = now.subtract(Duration(hours: i)).millisecondsSinceEpoch;
      final predHum = 40.0 + (i % 5) * 1.5;
      final rec = (predHum > 45.0)
          ? 'SATURATION RISK: Irrigation perjudicial tomorrow. DO NOT IRRIGATE.'
          : 'HEALTHY: Irrigation safe / Not perjudicial.';
      _predictionHistory.add(PredictionRecord(ts, predHum, rec));
    }
  }

  // Location Settings
  LocationSettings getLocationSettings() {
    return _locationSettings;
  }

  void saveLocationSettings(double lat, double lon, bool isGps) {
    _locationSettings = LocationSettings(1, lat, lon, isGps);
  }

  LocationSettings getGpsConfig() {
    return _gpsConfig;
  }

  void saveGpsConfig(double lat, double lon) {
    _gpsConfig = LocationSettings(3, lat, lon, true);
  }

  // Soil Humidity
  void saveSoilHumidity(int timestamp, double value) {
    // Overwrite existing or add new
    _soilHumidityHistory.removeWhere((r) => r.timestamp == timestamp);
    _soilHumidityHistory.add(SoilHumidityRecord(timestamp, value));
  }

  void saveSoilHumidityBatch(List<SoilHumidityRecord> records) {
    for (var rec in records) {
      saveSoilHumidity(rec.timestamp, rec.value);
    }
  }

  List<SoilHumidityRecord> getSoilHumidityHistory() {
    return List.from(_soilHumidityHistory);
  }

  // Weather
  void saveWeather(int timestamp, double temp, double hum, double rad, double prec) {
    _weatherHistory.removeWhere((r) => r.timestamp == timestamp);
    _weatherHistory.add(WeatherRecord(timestamp, temp, hum, rad, prec));
  }

  List<WeatherRecord> getWeatherHistory() {
    return List.from(_weatherHistory);
  }

  double getTodayRadiationSum() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final records = _weatherHistory.where((r) => r.timestamp >= startOfDay);
    
    if (records.isEmpty) return 0.0;
    return records.map((r) => r.radiation).reduce((a, b) => a + b);
  }

  // Predictions
  void savePrediction(int timestamp, double predictedHumidity, String recommendation) {
    _predictionHistory.removeWhere((r) => r.timestamp == timestamp);
    _predictionHistory.add(PredictionRecord(timestamp, predictedHumidity, recommendation));
  }

  List<PredictionRecord> getPredictionHistory() {
    return List.from(_predictionHistory);
  }

  void clearAllData() {
    _soilHumidityHistory.clear();
    _weatherHistory.clear();
    _predictionHistory.clear();
  }

  // Saved Devices
  List<SavedDevice> getSavedDevices() {
    return List.from(_savedDevices);
  }

  void saveDevice(String id, String name) {
    _savedDevices.removeWhere((d) => d.id == id);
    _savedDevices.add(SavedDevice(id, name));
  }

  void deleteDevice(String id) {
    _savedDevices.removeWhere((d) => d.id == id);
  }

  void close() {}
}
