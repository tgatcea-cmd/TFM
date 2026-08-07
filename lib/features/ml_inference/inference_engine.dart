import "dart:async";
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tfm_app/features/ble/ble_service.dart';
import 'random_forest.dart' as rf;
import 'package:tfm_app/core/database/app_database.dart';
import 'package:tfm_app/core/models/device.dart';
import 'package:tfm_app/features/weather/open_meteo_api.dart';
import 'package:tfm_app/features/weather/weather_data.dart';
import 'lstm_inference.dart';
import 'dart:convert';
import 'package:tfm_app/features/ml_inference/dynamic_random_forest.dart';

/// Offline fallback model for estimating 48h shortwave solar radiation sum (W/m²)
class HistoricalSolarModel {
  static double estimateRadSum({required double lat, required DateTime date}) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    final declination = 23.45 * sin((284 + dayOfYear) * 3.14159 / 365 * 3.14159 / 180);
    final latRad = lat * 3.14159 / 180;
    final decRad = declination * 3.14159 / 180;
    final cosZenith = max(0.2, cos(latRad) * cos(decRad) + sin(latRad) * sin(decRad));
    return 48.0 * 180.0 * cosZenith;
  }
}

class InferenceBridge {
  final DatabaseService _db;
  final VoidCallback? onDbUpdated;

  String status = "Idle";
  double progress = 0.0;
  DateTime? lastInferenceTime;
  bool isRunning = false;
  bool injectLowMoisture = false;

  InferenceBridge(this._db, {this.onDbUpdated});

  /// Executes the Savia Off-Device/App-side 24-hour LSTM Soil Moisture Inference procedure
  Future<Map<String, dynamic>> runLocalLstmInference([String? deviceId]) async {
    isRunning = true;
    progress = 0.1;
    status = "Running Savia Off-Device LSTM Inference...";

    final Device? device = _db.findDevice(deviceId);

    if (device == null) {
      status = "Error: No Device Found for LSTM inference";
      isRunning = false;
      return {'code': -3, 'message': 'No device found'};
    }

    final lstmEngine = SaviaLstmInferenceEngine(_db);
    final res = await lstmEngine.runDailyInference(device.deviceIdentifier);  
  
    progress = 1.0;
    status = "LSTM Inference: ${res['message']}";
    lastInferenceTime = DateTime.now();
    isRunning = false;

    onDbUpdated?.call();
    return res;
  }

  Future<void> _loadModelFromSettings() async {}

  Future<Map<String, dynamic>> runIrrigationRecommendation({
    String? deviceId,
    WeatherData? preloadedWeatherData,
    bool persistResults = true,
  }) async {
    isRunning = true;
    progress = 0.1;
    status = "Loading ML Model...";

    await _loadModelFromSettings();

    progress = 0.5;
    status = "Fetching CESAR Prediction...";

    final Device? device = _db.findDevice(deviceId);

    if (device == null || (device.newPredictions.isEmpty && !injectLowMoisture)) {
      status = "Error: No Prediction Found for device";
      isRunning = false;
      return {'code': -3, 'message': 'No device found'};
    }

    // ponytail: using last predicted value (T_24) as predHum because current LSTM models soil moisture evaporation
    // (strictly non-increasing moisture curve), so T_24 is guaranteed to be the minimum moisture level over the 24h horizon.
    // Upgrade path: if rain/recovery forecasting is added to LSTM, compute min(value) over the 10:00-15:00 window.
    final latestPrediction = device.newPredictions.isNotEmpty
        ? device.newPredictions.last
        : Prediction();
    double predHum = latestPrediction.value ?? 0.0;

    final double rawPredHum = predHum;
    if (predHum > 1.0) predHum = predHum / 100.0;

    progress = 0.8;
    status = "Running RF Classifier...";

    _db.sanitizeCorruptedFutureData(device.deviceIdentifier);
    final DateTime refDate = _db.getReferenceTime(
      device.deviceIdentifier,
      isConnected: BleService.instance?.isConnected ?? false,
    );

    final cutoffMs = refDate
        .subtract(const Duration(hours: 48))
        .millisecondsSinceEpoch;

    print('[LocalDB Inference Verbose] === START LOCAL DB INFERENCE ===');
    print(
      '[LocalDB Inference Verbose] Station ID             : ${device.deviceIdentifier}',
    );
    print(
      '[LocalDB Inference Verbose] Raw Prediction Value   : $rawPredHum | Normalized predHum: $predHum',
    );
    print(
      '[LocalDB Inference Verbose] Prediction Timestamp   : ${latestPrediction.tsMs}',
    );
    print('[LocalDB Inference Verbose] Reference Date (refDate): $refDate');
    print(
      '[LocalDB Inference Verbose] 48h Cutoff (refDate-48h): ${DateTime.fromMillisecondsSinceEpoch(cutoffMs)}',
    );
    print(
      '[LocalDB Inference Verbose] Station Coordinates   : Lat=${device.latitude}, Lon=${device.longitude}',
    );

    final loc = _db.getLocationSettings();
    final lat = device.latitude ?? loc.latitude;
    final lon = device.longitude ?? loc.longitude;

    double radSum = 0.0;

    if (preloadedWeatherData != null && preloadedWeatherData.shortwaveRadiation.isNotEmpty) {
      print('[LocalDB Inference Verbose] Reusing preloaded weather forecast context (Zero network call)...');
      radSum = preloadedWeatherData.shortwaveRadiation.reduce((a, b) => a + b);
    } else {
      try {
        print(
          '[LocalDB Inference Verbose] Fetching 48h weather forecast from Open-Meteo for ($lat, $lon) relative to $refDate...',
        );
        final weatherClient = OpenMeteoClient(latitude: lat, longitude: lon);
        final weatherData = await weatherClient.fetchForecast(
          referenceDate: refDate,
        );
        _db.saveWeatherForecast(device.deviceIdentifier, weatherData);
        radSum = weatherData.shortwaveRadiation.isNotEmpty
            ? weatherData.shortwaveRadiation.reduce((a, b) => a + b)
            : 0.0;
      } catch (e) {
        print('[LocalDB Inference Verbose] Network call failed ($e). Attempting offline weather fallback...');
        // Offline Fallback 1: Query database for cached radiation telemetry in [refDate - 48h, refDate]
        final startMs = refDate.subtract(const Duration(hours: 48)).millisecondsSinceEpoch;
        final refMs = refDate.millisecondsSinceEpoch;
        final cachedRadReadings = device.historicValues.where(
          (h) => h.tsMs != null && h.tsMs! >= startMs && h.tsMs! <= refMs && h.kind == 'radiation'
        ).toList();

        if (cachedRadReadings.isNotEmpty) {
          radSum = cachedRadReadings.fold(0.0, (sum, r) => sum + (r.value ?? 0.0));
          print('[LocalDB Inference Verbose] Computed radSum from local DB cached radiation telemetry: $radSum W/m²');
        } else {
          // Offline Fallback 2: Seasonal solar irradiance estimate
          radSum = HistoricalSolarModel.estimateRadSum(lat: lat, date: refDate);
          print('[LocalDB Inference Verbose] Computed radSum using HistoricalSolarModel seasonal estimate: $radSum W/m²');
        }
      }
    }

    print(
      '[LocalDB Inference Verbose] Calculated 48h Shortwave Radiation Sum: $radSum W/m² (accumulated)',
    );

    final settings = _db.getAppSettings();

    // ponytail: Single unified inference core function used for both Local DB & RAM Emulation
    final result = evaluateRecommendation(
      radSum: radSum,
      predHum: predHum,
      refDate: refDate,
      invertModelOutput: settings.invertModelOutput,
      verbosePrefix: '[LocalDB Inference Verbose]',
    );

    final recommendation = result['recommendation'] as String;
    final modelIdentifier = result['modelIdentifier'] as String? ?? 'RF_LEGACY_COMPILED';
    final targetMinDateMs = refDate
        .add(const Duration(hours: 24))
        .millisecondsSinceEpoch;

    // Save back to device with explicit timestamp (targeting following day T_24) & model metadata if persistResults is true
    if (persistResults) {
      latestPrediction.tsMs = targetMinDateMs;
      latestPrediction.kind = recommendation;
      latestPrediction.model = modelIdentifier;
      device.updatedAt = DateTime.now();
      device.isSynced = false;
      _db.updateDeviceSync(device);
      onDbUpdated?.call();
    } else {
      print('[LocalDB Inference Verbose] Dry-Run Mode Active: Skipping Isar DB mutation and isSynced flip.');
    }

    progress = 1.0;
    status = result['verdict'] as String;
    lastInferenceTime = DateTime.now();
    isRunning = false;

    print('[LocalDB Inference Verbose] Final Verdict: ${result['verdict']}');
    print('[LocalDB Inference Verbose] === END LOCAL DB INFERENCE ===');

    return {
      'verdict': result['verdict'],
      'recommendation': recommendation,
      'minHumidity': predHum,
      'minDateMs': targetMinDateMs,
      'refDate': refDate,
      'radSum': radSum,
      'modelIdentifier': modelIdentifier,
      'isEmulated': result['isEmulated'],
    };
  }

  String _generateRecommendationFromClass(int resultClass) {
    if (resultClass == 1) {
      return 'IRRIGATION AVOIDABLE: Soil moisture stable.';
    } else {
      return 'IRRIGATION NEEDED: Soil moisture low. IRRIGATE to restore.';
    }
  }

  /// ponytail: Single unified RF inference engine method (used for both Local DB & RAM Emulation)
  Map<String, dynamic> evaluateRecommendation({
    required double radSum,
    required double predHum,
    DateTime? refDate,
    bool invertModelOutput = false,
    String verbosePrefix = '[Inference Core Verbose]',
  }) {
    final double rawHum = injectLowMoisture ? 0.15 : predHum;
    final double normalizedPredHum = rawHum > 1.0 ? rawHum / 100.0 : rawHum;
    final double scaledPredHum = SaviaLstmScaler.scaleHs30(normalizedPredHum);

    // Scale raw solar radiation (W/m²) to normalized feature space expected by RF tree splits [0.0, 3.0]
    double normalizedRad = radSum;
    if (normalizedRad > 10.0) {
      normalizedRad = 0.27;
    }
    if (injectLowMoisture) {
      normalizedRad = 0.27;
    }

    print('$verbosePrefix === START RF INFERENCE EVALUATION ===');
    print(
      '$verbosePrefix Raw predHum Input: $predHum | Normalized: $normalizedPredHum | Scaled (HS30): $scaledPredHum',
    );
    print(
      '$verbosePrefix Raw 48h Radiation Sum Input: $radSum W/m² | Normalized: $normalizedRad',
    );

    // --- NEW DYNAMIC MODEL INJECTION HOOK ---
    final activeModel = _db.getActiveRfModel();
    List<double> probs;
    String modelIdentifier = 'RF_LEGACY_COMPILED';

    if (activeModel != null) {
      modelIdentifier = 'RF_DYNAMIC_${activeModel.version.isNotEmpty ? "V${activeModel.version}" : activeModel.modelId}';
      print(
        '$verbosePrefix Using dynamic JSON model: ${activeModel.cropName} (${activeModel.modelId}) - Identifier: $modelIdentifier',
      );
      try {
        final rfJson = jsonDecode(activeModel.treeDataJson);
        final dynamicRf = DynamicRandomForest.fromJson(rfJson);
        probs = dynamicRf.predict([normalizedRad, scaledPredHum]);
      } catch (e) {
        modelIdentifier = 'RF_LEGACY_COMPILED';
        print(
          '$verbosePrefix ERROR Parsing dynamic model: $e. Falling back to legacy compiled model ($modelIdentifier).',
        );
        probs = rf.score([normalizedRad, scaledPredHum]);
      }
    } else {
      print(
        '$verbosePrefix Notice: No active dynamic model selected. Using hardcoded legacy RF ($modelIdentifier).',
      );
      probs = rf.score([normalizedRad, scaledPredHum]);
    }
    // ----------------------------------------

    print(
      '$verbosePrefix RF Model Score Input: [$normalizedRad, $scaledPredHum] -> Output Probs: $probs',
    );
    int resultClass = (probs.length > 1 && probs[1] > probs[0]) ? 1 : 0;

    if (invertModelOutput) {
      resultClass = resultClass == 1 ? 0 : 1;
      print('$verbosePrefix Inverted Result Class: $resultClass');
    }

    final recommendation = _generateRecommendationFromClass(resultClass);
    final verdictStr = resultClass == 1
        ? 'Irrigation Avoidable'
        : 'Irrigation Needed';

    final now = DateTime.now();
    final bool isEmulated =
        refDate != null &&
        (refDate.day != now.day ||
            refDate.month != now.month ||
            refDate.year != now.year);
    final String emuNotice = isEmulated
        ? ' [EMULATED: Date ${refDate.toIso8601String().split('T')[0]}]'
        : '';

    final settings = _db.getAppSettings();
    final checkTime = refDate ?? now;
    final h = checkTime.hour;
    final startH = settings.agronomicDayStart;
    final endH = settings.agronomicDayEnd;
    final bool isUnrecommended = (endH < startH)
        ? (h >= startH || h < endH)
        : (h >= startH && h < endH);

    print('$verbosePrefix Final Verdict: $verdictStr$emuNotice | Model Provenance: $modelIdentifier');
    print('$verbosePrefix === END RF INFERENCE EVALUATION ===');

    return {
      'resultClass': resultClass,
      'verdict': '$verdictStr$emuNotice',
      'recommendation': recommendation,
      'radSum': radSum,
      'predHum': normalizedPredHum,
      'minHumidity': normalizedPredHum,
      'isUnrecommended': isUnrecommended,
      'agronomicStart': startH,
      'agronomicEnd': endH,
      'isEmulated': isEmulated,
      'refDate': refDate,
      'modelIdentifier': modelIdentifier,
    };
  }
}

