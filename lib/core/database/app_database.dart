import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:tfm_app/core/models/device.dart';
import 'package:tfm_app/core/models/app_settings.dart';
import 'package:tfm_app/features/location/location_settings.dart';
import 'package:tfm_app/features/weather/weather_data.dart';
import 'package:tfm_app/core/models/app_rf_model.dart';

class DatabaseService {
  late final Isar isar;

  // Web Fallbacks
  late AppSettings _webSettings;
  final List<Device> _webDevices = [];
  final List<RfModel> _webRfModels = [];

  Future<void> init() async {
    if (!kIsWeb) {
      try {
        await Isar.initializeIsarCore(download: true);
      } catch (_) {}

      String dirPath = '.';
      try {
        final dir = await getApplicationDocumentsDirectory();
        dirPath = dir.path;
      } catch (_) {}

      isar = await Isar.open([
        DeviceSchema,
        AppSettingsSchema,
        RfModelSchema,
      ], directory: dirPath);

      // Initialize default settings if missing
      if (isar.appSettings.countSync() == 0) {
        isar.writeTxnSync(() {
          isar.appSettings.putSync(AppSettings());
        });
      }
    } else {
      _webSettings = AppSettings();
    }
  }

  // Helper method: Write with auto-retry for unique IDs
  Future<void> saveDevice(Device device) async {
    device.updatedAt = DateTime.now();
    device.isSynced = false;

    if (kIsWeb) {
      final idx = _webDevices.indexWhere((d) => d.deviceIdentifier == device.deviceIdentifier);
      if (idx != -1) {
        _webDevices[idx] = device;
      } else {
        _webDevices.add(device);
      }
      return;
    }

    await isar.writeTxn(() async {
      final existing = await isar.devices
          .where()
          .deviceIdentifierEqualTo(device.deviceIdentifier)
          .findFirst();
      if (existing != null) device.id = existing.id;
      await isar.devices.put(device);
    });
  }

  void saveDeviceBasic(
    String id,
    String name, {
    double? lat,
    double? lon,
    bool isFromCloud = false,
  }) {
    if (kIsWeb) {
      final existingIdx = _webDevices.indexWhere((d) => d.deviceIdentifier == id);
      if (existingIdx != -1) {
        final existing = _webDevices[existingIdx];
        final isGenericExisting =
            existing.name == "Unknown Station" ||
            existing.name == id ||
            existing.name.startsWith("Pico ");
        if (isGenericExisting && name.isNotEmpty) {
          existing.name = name;
        }
        if (lat != null) existing.latitude = lat;
        if (lon != null) existing.longitude = lon;
        if (isFromCloud) existing.isSynced = true;
      } else {
        final d = Device()
          ..deviceIdentifier = id
          ..name = name
          ..latitude = lat
          ..longitude = lon
          ..handshakePassword = ''
          ..isSynced = isFromCloud;
        _webDevices.add(d);
      }
      return;
    }

    isar.writeTxnSync(() {
      final existing = isar.devices
          .where()
          .deviceIdentifierEqualTo(id)
          .findFirstSync();
      if (existing != null) {
        // Preserve BLE/customized names: only update if existing is generic/default/ID
        final isGenericExisting =
            existing.name == "Unknown Station" ||
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

  AppSettings getAppSettings() {
    if (kIsWeb) return _webSettings;
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
    if (kIsWeb) {
      final s = _webSettings;
      if (isFirstTime != null) s.isFirstTime = isFirstTime;
      if (themeMode != null) s.themeMode = themeMode;
      if (tfmServerScheme != null) s.tfmServerScheme = tfmServerScheme;
      if (tfmServerUrl != null) s.tfmServerUrl = tfmServerUrl;
      if (tfmServerPort != null) s.tfmServerPort = tfmServerPort;
      if (tfmServerApiKey != null) s.tfmServerApiKey = tfmServerApiKey;
      if (syncScheduleHours != null) s.syncScheduleHours = syncScheduleHours;
      if (selectedTfliteModel != null) {
        s.selectedTfliteModel = selectedTfliteModel;
      }
      if (invertModelOutput != null) {
        s.invertModelOutput = invertModelOutput;
      }
      if (permitOpenMeteoFill != null) {
        s.permitOpenMeteoFill = permitOpenMeteoFill;
      }
      if (alwaysForceInference != null) {
        s.alwaysForceInference = alwaysForceInference;
      }
      if (agronomicDayStart != null) s.agronomicDayStart = agronomicDayStart;
      if (agronomicDayEnd != null) s.agronomicDayEnd = agronomicDayEnd;
      return;
    }

    isar.writeTxnSync(() {
      final s = getAppSettings();
      if (isFirstTime != null) s.isFirstTime = isFirstTime;
      if (themeMode != null) s.themeMode = themeMode;
      if (tfmServerScheme != null) s.tfmServerScheme = tfmServerScheme;
      if (tfmServerUrl != null) s.tfmServerUrl = tfmServerUrl;
      if (tfmServerPort != null) s.tfmServerPort = tfmServerPort;
      if (tfmServerApiKey != null) s.tfmServerApiKey = tfmServerApiKey;
      if (syncScheduleHours != null) s.syncScheduleHours = syncScheduleHours;
      if (selectedTfliteModel != null) {
        s.selectedTfliteModel = selectedTfliteModel;
      }
      if (invertModelOutput != null) {
        s.invertModelOutput = invertModelOutput;
      }
      if (permitOpenMeteoFill != null) {
        s.permitOpenMeteoFill = permitOpenMeteoFill;
      }
      if (alwaysForceInference != null) {
        s.alwaysForceInference = alwaysForceInference;
      }
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
    if (kIsWeb) {
      final s = _webSettings;
      s.manualLat = lat;
      s.manualLon = lon;
      s.isGpsEnabled = isGps;
      return;
    }
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
    if (kIsWeb) {
      final s = _webSettings;
      s.gpsLat = lat;
      s.gpsLon = lon;
      return;
    }
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
    if (kIsWeb) {
      _webSettings.minHumidity = value;
      return;
    }
    isar.writeTxnSync(() {
      final s = getAppSettings();
      s.minHumidity = value;
      isar.appSettings.putSync(s);
    });
  }

  List<Device> getSavedDevices() {
    if (kIsWeb) return _webDevices;
    return isar.devices.where().findAllSync();
  }

  void deleteDevice(String id) {
    if (kIsWeb) {
      _webDevices.removeWhere((d) => d.deviceIdentifier == id);
      return;
    }
    isar.writeTxnSync(() {
      final dev = isar.devices
          .where()
          .deviceIdentifierEqualTo(id)
          .findFirstSync();
      if (dev != null) isar.devices.deleteSync(dev.id);
    });
  }

  // --- Telemetry & Prediction Helpers for New Architecture ---

  /// Upserts telemetry records by (tsMs, depthCm, kind).
  /// Prevents duplicates and updates existing values if modified.
  bool upsertTelemetry(
    String deviceId,
    List<HistoricValue> newValues, {
    bool isFromCloud = false,
  }) {
    if (kIsWeb) {
      bool hasChanges = false;
      final devIdx = _webDevices.indexWhere((d) => d.deviceIdentifier == deviceId);
      Device dev;
      if (devIdx == -1) {
        dev = Device()
          ..deviceIdentifier = deviceId
          ..name = deviceId
          ..handshakePassword = ''
          ..isSynced = isFromCloud;
        _webDevices.add(dev);
        hasChanges = true;
      } else {
        dev = _webDevices[devIdx];
      }
      final existingList = List<HistoricValue>.from(dev.historicValues);

      // Build fast index map for O(1) duplicate checks: key = 'ts_depth_kind'
      final Map<String, int> indexMap = {
        for (int i = 0; i < existingList.length; i++)
          '${existingList[i].tsMs}_${existingList[i].depthCm}_${existingList[i].kind}':
              i,
      };

      for (var incoming in newValues) {
        if (incoming.tsMs == null) continue;

        final key = '${incoming.tsMs}_${incoming.depthCm}_${incoming.kind}';
        final index = indexMap[key];

        if (index != null) {
          if (existingList[index].value != incoming.value) {
            existingList[index].value = incoming.value;
            existingList[index].kind =
                incoming.kind ?? existingList[index].kind;
            existingList[index].port =
                incoming.port ?? existingList[index].port;
            hasChanges = true;
          }
        } else {
          existingList.add(incoming);
          indexMap[key] = existingList.length - 1;
          hasChanges = true;
        }
      }

      if (hasChanges || isFromCloud) {
        dev.historicValues = existingList;
        dev.updatedAt = DateTime.now();
        dev.isSynced = isFromCloud;
      }
      return hasChanges;
    }

    bool hasChanges = false;
    isar.writeTxnSync(() {
      var dev = isar.devices
          .where()
          .deviceIdentifierEqualTo(deviceId)
          .findFirstSync();
      if (dev == null) {
        dev = Device()
          ..deviceIdentifier = deviceId
          ..name = deviceId
          ..handshakePassword = ''
          ..isSynced = isFromCloud;
        hasChanges = true;
      }
      final existingList = List<HistoricValue>.from(dev.historicValues);

      // Build fast index map for O(1) duplicate checks: key = 'ts_depth_kind'
      final Map<String, int> indexMap = {
        for (int i = 0; i < existingList.length; i++)
          '${existingList[i].tsMs}_${existingList[i].depthCm}_${existingList[i].kind}':
              i,
      };

      for (var incoming in newValues) {
        if (incoming.tsMs == null) continue;

        final key = '${incoming.tsMs}_${incoming.depthCm}_${incoming.kind}';
        final index = indexMap[key];

        if (index != null) {
          if (existingList[index].value != incoming.value) {
            existingList[index].value = incoming.value;
            existingList[index].kind =
                incoming.kind ?? existingList[index].kind;
            existingList[index].port =
                incoming.port ?? existingList[index].port;
            hasChanges = true;
          }
        } else {
          existingList.add(incoming);
          indexMap[key] = existingList.length - 1;
          hasChanges = true;
        }
      }

      if (hasChanges || isFromCloud) {
        dev.historicValues = existingList;
        dev.updatedAt = DateTime.now();
        dev.isSynced = isFromCloud;
        isar.devices.putSync(dev);
      }
    });
    return hasChanges;
  }

  void appendTelemetry(String deviceId, List<HistoricValue> newValues) {
    upsertTelemetry(deviceId, newValues, isFromCloud: false);
  }

  List<HistoricValue> getDeviceTelemetry(
    String deviceId, {
    String? kind,
    double? depthCm,
    int? sinceMs,
  }) {
    if (kIsWeb) {
      final devIdx = _webDevices.indexWhere((d) => d.deviceIdentifier == deviceId);
      if (devIdx == -1) return [];
      final dev = _webDevices[devIdx];
      return dev.historicValues.where((v) {
        if (kind != null && v.kind != kind) return false;
        if (depthCm != null && v.depthCm != depthCm) return false;
        if (sinceMs != null && v.tsMs != null && v.tsMs! < sinceMs) return false;
        return true;
      }).toList();
    }

    final dev = isar.devices
        .where()
        .deviceIdentifierEqualTo(deviceId)
        .findFirstSync();
    if (dev == null) return [];

    // ponytail: filter in-memory since lists are small enough (YAGNI complex Isar relations)
    return dev.historicValues.where((v) {
      if (kind != null && v.kind != kind) return false;
      if (depthCm != null && v.depthCm != depthCm) return false;
      if (sinceMs != null && v.tsMs != null && v.tsMs! < sinceMs) return false;
      return true;
    }).toList();
  }

  /// Calculates the valid reference timestamp of local device information.
  /// Ignores corrupted/future timestamps (> DateTime.now()).
  /// Uses the latest valid past telemetry timestamp from historicValues <= now,
  /// falling back to live time if connected or recently synced.
  DateTime getReferenceTime(String deviceId, {bool isConnected = false}) {
    if (kIsWeb) {
      final devIdx = _webDevices.indexWhere((d) => d.deviceIdentifier == deviceId);
      if (devIdx == -1) return DateTime.now();
      final dev = _webDevices[devIdx];
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      int? maxValidPastTs;
      for (var h in dev.historicValues) {
        if (h.tsMs != null && h.tsMs! <= nowMs) {
          if (maxValidPastTs == null || h.tsMs! > maxValidPastTs) {
            maxValidPastTs = h.tsMs!;
          }
        }
      }

      if (maxValidPastTs != null) {
        return DateTime.fromMillisecondsSinceEpoch(maxValidPastTs);
      }

      if (isConnected ||
          (dev.latestSynchronizedTime != null &&
              DateTime.now().difference(dev.latestSynchronizedTime!).inHours <
                  2)) {
        return DateTime.now();
      }

      return dev.latestSynchronizedTime ?? dev.updatedAt;
    }

    final dev = isar.devices
        .where()
        .deviceIdentifierEqualTo(deviceId)
        .findFirstSync();
    if (dev == null) {
      return DateTime.now();
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // Filter out corrupted future timestamps (> now)
    int? maxValidPastTs;
    for (var h in dev.historicValues) {
      if (h.tsMs != null && h.tsMs! <= nowMs) {
        if (maxValidPastTs == null || h.tsMs! > maxValidPastTs) {
          maxValidPastTs = h.tsMs!;
        }
      }
    }

    if (maxValidPastTs != null) {
      return DateTime.fromMillisecondsSinceEpoch(maxValidPastTs);
    }

    // If connected or recently synced, fall back to live time
    if (isConnected ||
        (dev.latestSynchronizedTime != null &&
            DateTime.now().difference(dev.latestSynchronizedTime!).inHours <
                2)) {
      return DateTime.now();
    }

    return dev.latestSynchronizedTime ?? dev.updatedAt;
  }

  /// Automatically prunes any corrupted future telemetry entries (> DateTime.now())
  void sanitizeCorruptedFutureData(String deviceId) {
    if (kIsWeb) {
      final devIdx = _webDevices.indexWhere((d) => d.deviceIdentifier == deviceId);
      if (devIdx != -1) {
        final dev = _webDevices[devIdx];
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        final cleanHistoric = dev.historicValues
            .where((h) => h.tsMs != null && h.tsMs! <= nowMs)
            .toList();
        if (cleanHistoric.length != dev.historicValues.length) {
          print(
            '[DB Sanitizer] Pruned ${dev.historicValues.length - cleanHistoric.length} corrupted future telemetry entries.',
          );
          dev.historicValues = cleanHistoric;
        }
      }
      return;
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    isar.writeTxnSync(() {
      final dev = isar.devices
          .where()
          .deviceIdentifierEqualTo(deviceId)
          .findFirstSync();
      if (dev != null) {
        final cleanHistoric = dev.historicValues
            .where((h) => h.tsMs != null && h.tsMs! <= nowMs)
            .toList();
        if (cleanHistoric.length != dev.historicValues.length) {
          print(
            '[DB Sanitizer] Pruned ${dev.historicValues.length - cleanHistoric.length} corrupted future telemetry entries.',
          );
          dev.historicValues = cleanHistoric;
          isar.devices.putSync(dev);
        }
      }
    });
  }

  void markDeviceSynced(String deviceId) {
    if (kIsWeb) {
      final devIdx = _webDevices.indexWhere((d) => d.deviceIdentifier == deviceId);
      Device dev;
      if (devIdx == -1) {
        dev = Device()
          ..deviceIdentifier = deviceId
          ..name = deviceId
          ..handshakePassword = '';
        _webDevices.add(dev);
      } else {
        dev = _webDevices[devIdx];
      }
      dev.isSynced = true;
      dev.latestSynchronizedTime = DateTime.now();
      dev.updatedAt = DateTime.now();
      return;
    }

    isar.writeTxnSync(() {
      var dev = isar.devices
          .where()
          .deviceIdentifierEqualTo(deviceId)
          .findFirstSync();
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

  void updateDeviceStatus(
    String deviceId,
    Map<String, dynamic> status, {
    bool isFromCloud = false,
  }) {
    if (kIsWeb) {
      final devIdx = _webDevices.indexWhere((d) => d.deviceIdentifier == deviceId);
      Device dev;
      if (devIdx == -1) {
        dev = Device()
          ..deviceIdentifier = deviceId
          ..name = deviceId
          ..handshakePassword = ''
          ..isSynced = isFromCloud;
        _webDevices.add(dev);
      } else {
        dev = _webDevices[devIdx];
      }

      final lat = (status['lat'] ?? status['latitude'] as num?)?.toDouble();
      final lon = (status['lon'] ?? status['longitude'] as num?)?.toDouble();
      if (lat != null) dev.latitude = lat;
      if (lon != null) dev.longitude = lon;
      dev.latestSynchronizedTime = DateTime.now();
      if (isFromCloud) {
        dev.isSynced = true;
      }
      return;
    }

    isar.writeTxnSync(() {
      var dev = isar.devices
          .where()
          .deviceIdentifierEqualTo(deviceId)
          .findFirstSync();
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
      if (isFromCloud) {
        dev.isSynced = true;
      }
      isar.devices.putSync(dev);
    });
  }

  void updateDeviceConfig(String deviceId, Map<String, dynamic> config) {
    if (kIsWeb) {
      final devIdx = _webDevices.indexWhere((d) => d.deviceIdentifier == deviceId);
      Device dev;
      if (devIdx == -1) {
        dev = Device()
          ..deviceIdentifier = deviceId
          ..name = deviceId
          ..handshakePassword = ''
          ..isSynced = false;
        _webDevices.add(dev);
      } else {
        dev = _webDevices[devIdx];
      }

      dev.localInferenceCapabilities =
          config['infer_dev'] == true || config['local_inference'] == true;
      dev.loraEnabled = config['lora_enabled'] == true;
      dev.updatedAt = DateTime.now();
      dev.isSynced = false;
      return;
    }

    isar.writeTxnSync(() {
      var dev = isar.devices
          .where()
          .deviceIdentifierEqualTo(deviceId)
          .findFirstSync();
      dev ??= Device()
        ..deviceIdentifier = deviceId
        ..name = deviceId
        ..handshakePassword = ''
        ..isSynced = false;

      dev.localInferenceCapabilities =
          config['infer_dev'] == true || config['local_inference'] == true;
      dev.loraEnabled = config['lora_enabled'] == true;
      dev.updatedAt = DateTime.now();
      dev.isSynced = false;
      isar.devices.putSync(dev);
    });
  }

  void updatePredictions(
    String deviceId,
    List<Prediction> predictions, {
    bool isFromCloud = false,
  }) {
    if (kIsWeb) {
      final devIdx = _webDevices.indexWhere((d) => d.deviceIdentifier == deviceId);
      Device dev;
      if (devIdx == -1) {
        dev = Device()
          ..deviceIdentifier = deviceId
          ..name = deviceId
          ..handshakePassword = ''
          ..isSynced = isFromCloud;
        _webDevices.add(dev);
      } else {
        dev = _webDevices[devIdx];
      }

      dev.previousPredictions = List.from(dev.newPredictions);
      dev.newPredictions = predictions;
      dev.latestInferenceTriggerDate = DateTime.now();
      dev.updatedAt = DateTime.now();
      dev.isSynced = isFromCloud;
      return;
    }

    isar.writeTxnSync(() {
      var dev = isar.devices
          .where()
          .deviceIdentifierEqualTo(deviceId)
          .findFirstSync();
      dev ??= Device()
        ..deviceIdentifier = deviceId
        ..name = deviceId
        ..handshakePassword = ''
        ..isSynced = isFromCloud;

      dev.previousPredictions = List.from(dev.newPredictions);
      dev.newPredictions = predictions;
      dev.latestInferenceTriggerDate = DateTime.now();
      dev.updatedAt = DateTime.now();
      dev.isSynced = isFromCloud;
      isar.devices.putSync(dev);
    });
  }

  void saveWeatherForecast(String deviceId, WeatherData weatherData) {
    final List<HistoricValue> values = [];
    for (int i = 0; i < weatherData.time.length; i++) {
      final ts = weatherData.time[i].millisecondsSinceEpoch;
      values.add(
        HistoricValue()
          ..tsMs = ts
          ..kind = 'temperature'
          ..value = weatherData.temperature2m[i],
      );
      values.add(
        HistoricValue()
          ..tsMs = ts
          ..kind = 'humidity'
          ..value = weatherData.relativeHumidity2m[i],
      );
      values.add(
        HistoricValue()
          ..tsMs = ts
          ..kind = 'radiation'
          ..value = weatherData.shortwaveRadiation[i],
      );
      values.add(
        HistoricValue()
          ..tsMs = ts
          ..kind = 'precipitation'
          ..value = weatherData.precipitation[i],
      );
    }
    upsertTelemetry(deviceId, values, isFromCloud: false);
  }

  void clearAllData() {
    if (kIsWeb) {
      _webDevices.clear();
      return;
    }
    isar.writeTxnSync(() {
      isar.devices.clearSync();
    });
  }

  void close() {
    if (kIsWeb) return;
    isar.close();
  }

  // --- ML Model Management Hooks ---
  List<RfModel> getSavedRfModels() {
    if (kIsWeb) return _webRfModels;
    return isar.rfModels.where().findAllSync();
  }

  RfModel? getActiveRfModel() {
    if (kIsWeb) {
      for (var m in _webRfModels) {
        if (m.isActive) return m;
      }
      return null;
    }
    return isar.rfModels.filter().isActiveEqualTo(true).findFirstSync();
  }

  void saveRfModel(Map<String, dynamic> metadata, String treeDataJson) {
    if (kIsWeb) {
      final model = RfModel()
        ..modelId = metadata['model_id']
        ..cropName = metadata['crop_name'] ?? 'Unknown'
        ..version = metadata['version'] ?? '1.0'
        ..description = metadata['description'] ?? ''
        ..treeDataJson = treeDataJson
        ..updatedAt = DateTime.now()
        ..isActive = false;
      _webRfModels.add(model);
      return;
    }

    isar.writeTxnSync(() {
      final model = RfModel()
        ..modelId = metadata['model_id']
        ..cropName = metadata['crop_name'] ?? 'Unknown'
        ..version = metadata['version'] ?? '1.0'
        ..description = metadata['description'] ?? ''
        ..treeDataJson = treeDataJson
        ..updatedAt = DateTime.now()
        ..isActive = false;
      isar.rfModels.putSync(model);
    });
  }

  void setActiveRfModel(String modelId) {
    if (kIsWeb) {
      for (var m in _webRfModels) {
        m.isActive = (m.modelId == modelId);
      }
      return;
    }

    isar.writeTxnSync(() {
      final all = isar.rfModels.where().findAllSync();
      for (var m in all) {
        m.isActive = (m.modelId == modelId);
        isar.rfModels.putSync(m);
      }
    });
  }

  void deleteRfModel(String modelId) {
    if (kIsWeb) {
      _webRfModels.removeWhere((m) => m.modelId == modelId);
      return;
    }

    isar.writeTxnSync(() {
      isar.rfModels.where().modelIdEqualTo(modelId).deleteAllSync();
    });
  }

  // --- Web Native Helper Methods to encapsulate direct `.isar` accesses ---

  Device? findDevice(String? deviceId) {
    if (kIsWeb) {
      if (deviceId != null) {
        for (var d in _webDevices) {
          if (d.deviceIdentifier == deviceId) return d;
        }
        return null;
      }
      return _webDevices.isNotEmpty ? _webDevices.first : null;
    }
    if (deviceId != null) {
      return isar.devices.where().deviceIdentifierEqualTo(deviceId).findFirstSync();
    }
    return isar.devices.where().findFirstSync();
  }

  void updateDeviceSync(Device device) {
    if (kIsWeb) {
      final idx = _webDevices.indexWhere((d) => d.deviceIdentifier == device.deviceIdentifier);
      if (idx != -1) {
        _webDevices[idx] = device;
      } else {
        _webDevices.add(device);
      }
      return;
    }
    isar.writeTxnSync(() {
      isar.devices.putSync(device);
    });
  }

  Future<List<Device>> getDirtyDevices() async {
    if (kIsWeb) {
      return _webDevices.where((d) => !d.isSynced).toList();
    }
    return isar.devices.filter().isSyncedEqualTo(false).findAll();
  }

  Future<void> saveDevices(List<Device> devices) async {
    if (kIsWeb) {
      for (var device in devices) {
        final idx = _webDevices.indexWhere((d) => d.deviceIdentifier == device.deviceIdentifier);
        if (idx != -1) {
          _webDevices[idx] = device;
        } else {
          _webDevices.add(device);
        }
      }
      return;
    }
    await isar.writeTxn(() async {
      for (var device in devices) {
        final existing = await isar.devices
            .where()
            .deviceIdentifierEqualTo(device.deviceIdentifier)
            .findFirst();
        if (existing != null) device.id = existing.id;
        await isar.devices.put(device);
      }
    });
  }
}
