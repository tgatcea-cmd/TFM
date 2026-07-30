import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/models.dart';
import '../../data/models/device.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/location_settings.dart';

class DatabaseService {
  late final Isar isar;

  Future<void> init() async {
    if (!kIsWeb) {
      try {
        await Isar.initializeIsarCore(download: true);
      } catch (_) {}
    }

    String dirPath = '.';
    try {
      final dir = await getApplicationDocumentsDirectory();
      dirPath = dir.path;
    } catch (_) {}

    isar = await Isar.open(
      [DeviceSchema, AppSettingsSchema],
      directory: dirPath, 
    );
    
    // Initialize default settings if missing
    if (isar.appSettings.countSync() == 0) {
      isar.writeTxnSync(() {
        isar.appSettings.putSync(AppSettings());
      });
    }
  }

  // Helper method: Write with auto-retry for unique IDs
  Future<void> saveDevice(Device device) async {
    device.updatedAt = DateTime.now();
    device.isSynced = false;

    await isar.writeTxn(() async {
      final existing = await isar.devices.where().deviceIdentifierEqualTo(device.deviceIdentifier).findFirst();
      if (existing != null) device.id = existing.id;
      await isar.devices.put(device);
    });
  }

  void saveDeviceBasic(String id, String name) {
    isar.writeTxnSync(() {
      final existing = isar.devices.where().deviceIdentifierEqualTo(id).findFirstSync();
      if (existing != null) {
        existing.name = name;
        isar.devices.putSync(existing);
      } else {
        final d = Device()
          ..deviceIdentifier = id
          ..name = name
          ..handshakePassword = '';
        isar.devices.putSync(d);
      }
    });
  }
  
  // Backwards compatibility methods for main.dart
  
  AppSettings getAppSettings() {
    return isar.appSettings.getSync(1) ?? AppSettings();
  }
  
  void saveAppSettings({
    bool? isFirstTime,
    String? themeMode,
    String? tfmServerScheme,
    String? tfmServerUrl,
    int? tfmServerPort,
    String? tfmServerApiKey,
    int? syncScheduleHours,
    String? selectedTfliteModel,
    bool? invertModelOutput,
    bool? permitOpenMeteoFill,
    bool? alwaysForceInference,
    int? agronomicDayStart,
    int? agronomicDayEnd,
  }) {
    isar.writeTxnSync(() {
      final s = getAppSettings();
      if (isFirstTime != null) s.isFirstTime = isFirstTime;
      if (themeMode != null) s.themeMode = themeMode;
      if (tfmServerScheme != null) s.tfmServerScheme = tfmServerScheme;
      if (tfmServerUrl != null) s.tfmServerUrl = tfmServerUrl;
      if (tfmServerPort != null) s.tfmServerPort = tfmServerPort;
      if (tfmServerApiKey != null) s.tfmServerApiKey = tfmServerApiKey;
      if (syncScheduleHours != null) s.syncScheduleHours = syncScheduleHours;
      if (selectedTfliteModel != null) s.selectedTfliteModel = selectedTfliteModel;
      if (invertModelOutput != null) s.invertModelOutput = invertModelOutput;
      if (permitOpenMeteoFill != null) s.permitOpenMeteoFill = permitOpenMeteoFill;
      if (alwaysForceInference != null) s.alwaysForceInference = alwaysForceInference;
      if (agronomicDayStart != null) s.agronomicDayStart = agronomicDayStart;
      if (agronomicDayEnd != null) s.agronomicDayEnd = agronomicDayEnd;
      isar.appSettings.putSync(s);
    });
  }

  LocationSettings getLocationSettings() {
    final s = getAppSettings();
    return LocationSettings(s.manualLat, s.manualLon, s.isGpsEnabled);
  }

  void saveLocationSettings(double lat, double lon, bool isGps) {
    isar.writeTxnSync(() {
      final s = getAppSettings();
      s.manualLat = lat;
      s.manualLon = lon;
      s.isGpsEnabled = isGps;
      isar.appSettings.putSync(s);
    });
  }

  LocationSettings getGpsConfig() {
    final s = getAppSettings();
    return LocationSettings(s.gpsLat, s.gpsLon, true);
  }

  void saveGpsConfig(double lat, double lon) {
    isar.writeTxnSync(() {
      final s = getAppSettings();
      s.gpsLat = lat;
      s.gpsLon = lon;
      isar.appSettings.putSync(s);
    });
  }

  double getMinHumidity() {
    return getAppSettings().minHumidity;
  }

  void saveMinHumidity(double value) {
    isar.writeTxnSync(() {
      final s = getAppSettings();
      s.minHumidity = value;
      isar.appSettings.putSync(s);
    });
  }

  List<Device> getSavedDevices() {
    return isar.devices.where().findAllSync();
  }
  
  void deleteDevice(String id) {
    isar.writeTxnSync(() {
      final dev = isar.devices.where().deviceIdentifierEqualTo(id).findFirstSync();
      if (dev != null) isar.devices.deleteSync(dev.id);
    });
  }

  // --- Telemetry & Prediction Helpers for New Architecture ---

  void appendTelemetry(String deviceId, List<HistoricValue> newValues) {
    isar.writeTxnSync(() {
      final dev = isar.devices.where().deviceIdentifierEqualTo(deviceId).findFirstSync();
      if (dev != null) {
        dev.historicValues = List.from(dev.historicValues)..addAll(newValues);
        dev.updatedAt = DateTime.now();
        dev.isSynced = false;
        isar.devices.putSync(dev);
      }
    });
  }

  List<HistoricValue> getDeviceTelemetry(String deviceId, {String? kind, double? depthCm, int? sinceMs}) {
    final dev = isar.devices.where().deviceIdentifierEqualTo(deviceId).findFirstSync();
    if (dev == null) return [];
    
    // ponytail: filter in-memory since lists are small enough (YAGNI complex Isar relations)
    return dev.historicValues.where((v) {
      if (kind != null && v.kind != kind) return false;
      if (depthCm != null && v.depthCm != depthCm) return false;
      if (sinceMs != null && v.tsMs != null && v.tsMs! < sinceMs) return false;
      return true;
    }).toList();
  }

  void updatePredictions(String deviceId, List<Prediction> predictions) {
    isar.writeTxnSync(() {
      final dev = isar.devices.where().deviceIdentifierEqualTo(deviceId).findFirstSync();
      if (dev != null) {
        dev.previousPredictions = dev.newPredictions;
        dev.newPredictions = predictions;
        dev.updatedAt = DateTime.now();
        dev.isSynced = false;
        isar.devices.putSync(dev);
      }
    });
  }

  void clearAllData() {
    isar.writeTxnSync(() {
      isar.devices.clearSync();
    });
  }

  void close() {
    isar.close();
  }

  // --- STUBS for deprecated global methods to keep UI compiling ---
  void saveWeather(int timestamp, double temp, double hum, double rad, double prec) {}
  List<WeatherRecord> getWeatherHistory() => [];
  List<SoilHumidityRecord> getSoilHumidityHistory() => [];
  int getSoilHumidityCount(int sinceMs) => 0;
  int getWeatherCount(int sinceMs) => 0;
  List<PredictionRecord> getPredictionHistory() => [];
  void savePrediction(int ts, double predHum, String rec) {}
}
