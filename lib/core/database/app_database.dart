import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:tfm_app/core/models/device.dart';
import 'package:tfm_app/core/models/app_settings.dart';
import 'package:tfm_app/features/location/location_settings.dart';
import 'package:tfm_app/features/weather/weather_data.dart';

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

  void saveDeviceBasic(String id, String name, {double? lat, double? lon, bool isFromCloud = false}) {
    isar.writeTxnSync(() {
      final existing = isar.devices.where().deviceIdentifierEqualTo(id).findFirstSync();
      if (existing != null) {
        // Preserve BLE/customized names: only update if existing is generic/default/ID
        final isGenericExisting = existing.name == "Unknown Station" || 
            existing.name == id || 
            existing.name.startsWith("Pico ");
        if (isGenericExisting && name.isNotEmpty) {
          existing.name = name;
        }
        if (lat != null) existing.latitude = lat;
        if (lon != null) existing.longitude = lon;
        if (isFromCloud) existing.isSynced = true;
        isar.devices.putSync(existing);
      } else {
        final d = Device()
          ..deviceIdentifier = id
          ..name = name
          ..latitude = lat
          ..longitude = lon
          ..handshakePassword = ''
          ..isSynced = isFromCloud;
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

  /// Upserts telemetry records by (tsMs, depthCm).
  /// Prevents duplicates and updates existing values if modified.
  bool upsertTelemetry(String deviceId, List<HistoricValue> newValues, {bool isFromCloud = false}) {
    bool hasChanges = false;
    isar.writeTxnSync(() {
      var dev = isar.devices.where().deviceIdentifierEqualTo(deviceId).findFirstSync();
      if (dev == null) {
        // ponytail: auto-create device entry if missing so it is persisted & displayed in local DB
        dev = Device()
          ..deviceIdentifier = deviceId
          ..name = deviceId
          ..handshakePassword = ''
          ..isSynced = isFromCloud;
        hasChanges = true;
      }
      final existingList = List<HistoricValue>.from(dev.historicValues);
      
      for (var incoming in newValues) {
        if (incoming.tsMs == null) continue;
        
        final index = existingList.indexWhere((e) =>
            e.tsMs == incoming.tsMs && e.depthCm == incoming.depthCm && e.kind == incoming.kind);
        
        if (index != -1) {
          if (existingList[index].value != incoming.value) {
            existingList[index].value = incoming.value;
            existingList[index].kind = incoming.kind ?? existingList[index].kind;
            existingList[index].port = incoming.port ?? existingList[index].port;
            hasChanges = true;
          }
        } else {
          existingList.add(incoming);
          hasChanges = true;
        }
      }

      if (hasChanges || isFromCloud) {
        dev.historicValues = existingList;
        dev.updatedAt = DateTime.now();
        if (!isFromCloud) {
          dev.isSynced = false;
        } else {
          dev.isSynced = true;
        }
        isar.devices.putSync(dev);
      }
    });
    return hasChanges;
  }

  void appendTelemetry(String deviceId, List<HistoricValue> newValues) {
    upsertTelemetry(deviceId, newValues, isFromCloud: false);
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

  /// Calculates the reference timestamp of local device information.
  /// Prioritizes live real-time (DateTime.now()) if connected or recently synced,
  /// otherwise falls back to historical telemetry timestamps.
  DateTime getReferenceTime(String deviceId, {bool isConnected = false}) {
    final dev = isar.devices.where().deviceIdentifierEqualTo(deviceId).findFirstSync();
    if (dev == null) return DateTime.now();

    final now = DateTime.now();
    // ponytail: prioritize live time if connected or synced within last 2 hours
    if (isConnected || (dev.latestSynchronizedTime != null && now.difference(dev.latestSynchronizedTime!).inHours < 2)) {
      return now;
    }

    int? maxTs;
    for (var h in dev.historicValues) {
      if (h.tsMs != null && (maxTs == null || h.tsMs! > maxTs)) {
        maxTs = h.tsMs;
      }
    }

    if (maxTs != null) {
      final ref = DateTime.fromMillisecondsSinceEpoch(maxTs);
      return ref.isAfter(now) ? now : ref;
    }
    return dev.latestSynchronizedTime ?? dev.updatedAt;
  }

  void markDeviceSynced(String deviceId) {
    isar.writeTxnSync(() {
      var dev = isar.devices.where().deviceIdentifierEqualTo(deviceId).findFirstSync();
      // ponytail: auto-create device entry if missing
      dev ??= Device()
        ..deviceIdentifier = deviceId
        ..name = deviceId
        ..handshakePassword = '';
      dev.isSynced = true;
      dev.latestSynchronizedTime = DateTime.now();
      dev.updatedAt = DateTime.now();
      isar.devices.putSync(dev);
    });
  }

  void updateDeviceStatus(String deviceId, Map<String, dynamic> status, {bool isFromCloud = false}) {
    isar.writeTxnSync(() {
      var dev = isar.devices.where().deviceIdentifierEqualTo(deviceId).findFirstSync();
      // ponytail: auto-create device entry if missing
      dev ??= Device()
        ..deviceIdentifier = deviceId
        ..name = deviceId
        ..handshakePassword = ''
        ..isSynced = isFromCloud;

      final lat = (status['lat'] ?? status['latitude'] as num?)?.toDouble();
      final lon = (status['lon'] ?? status['longitude'] as num?)?.toDouble();
      if (lat != null) dev.latitude = lat;
      if (lon != null) dev.longitude = lon;
      dev.latestSynchronizedTime = DateTime.now();
      dev.updatedAt = DateTime.now();
      if (isFromCloud) {
        dev.isSynced = true;
      } else {
        dev.isSynced = false;
      }
      isar.devices.putSync(dev);
    });
  }

  void updateDeviceConfig(String deviceId, Map<String, dynamic> config) {
    isar.writeTxnSync(() {
      var dev = isar.devices.where().deviceIdentifierEqualTo(deviceId).findFirstSync();
      // ponytail: auto-create device entry if missing
      dev ??= Device()
        ..deviceIdentifier = deviceId
        ..name = deviceId
        ..handshakePassword = ''
        ..isSynced = false;

      dev.localInferenceCapabilities = config['infer_dev'] == true || config['local_inference'] == true;
      dev.loraEnabled = config['lora_enabled'] == true;
      dev.updatedAt = DateTime.now();
      dev.isSynced = false;
      isar.devices.putSync(dev);
    });
  }

  void updatePredictions(String deviceId, List<Prediction> predictions, {bool isFromCloud = false}) {
    isar.writeTxnSync(() {
      var dev = isar.devices.where().deviceIdentifierEqualTo(deviceId).findFirstSync();
      // ponytail: auto-create device entry if missing
      dev ??= Device()
        ..deviceIdentifier = deviceId
        ..name = deviceId
        ..handshakePassword = ''
        ..isSynced = isFromCloud;

      dev.previousPredictions = List.from(dev.newPredictions);
      dev.newPredictions = predictions;
      dev.latestInferenceTriggerDate = DateTime.now();
      dev.updatedAt = DateTime.now();
      if (isFromCloud) {
        dev.isSynced = true;
      } else {
        dev.isSynced = false;
      }
      isar.devices.putSync(dev);
    });
  }

  void saveWeatherForecast(String deviceId, WeatherData weatherData) {
    final List<HistoricValue> values = [];
    for (int i = 0; i < weatherData.time.length; i++) {
      final ts = weatherData.time[i].millisecondsSinceEpoch;
      values.add(HistoricValue()
        ..tsMs = ts
        ..kind = 'temperature'
        ..value = weatherData.temperature2m[i]);
      values.add(HistoricValue()
        ..tsMs = ts
        ..kind = 'humidity'
        ..value = weatherData.relativeHumidity2m[i]);
      values.add(HistoricValue()
        ..tsMs = ts
        ..kind = 'radiation'
        ..value = weatherData.shortwaveRadiation[i]);
      values.add(HistoricValue()
        ..tsMs = ts
        ..kind = 'precipitation'
        ..value = weatherData.precipitation[i]);
    }
    upsertTelemetry(deviceId, values, isFromCloud: false);
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

