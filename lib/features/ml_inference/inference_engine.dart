import "dart:async";
import 'package:signals/signals.dart';
import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';
import 'package:tfm_app/features/ble/ble_service.dart';
import 'random_forest.dart' as rf;
import 'package:tfm_app/core/database/app_database.dart';
import 'package:tfm_app/core/models/device.dart';
import 'package:tfm_app/features/weather/open_meteo_api.dart';
import 'lstm_inference.dart';

class InferenceBridge {
  final DatabaseService _db;
  final VoidCallback? onDbUpdated;

  final status = signal<String>("Idle");
  final progress = signal<double>(0.0);
  final lastInferenceTime = signal<DateTime?>(null);
  final isRunning = signal<bool>(false);

  InferenceBridge(this._db, {this.onDbUpdated});

  /// Executes the Savia Off-Device/App-side 24-hour LSTM Soil Moisture Inference procedure
  Future<Map<String, dynamic>> runLocalLstmInference([String? deviceId]) async {
    isRunning.value = true;
    progress.value = 0.1;
    status.value = "Running Savia Off-Device LSTM Inference...";

    Device? device;
    if (deviceId != null) {
      device = _db.isar.devices.where().deviceIdentifierEqualTo(deviceId).findFirstSync();
    } else {
      device = _db.isar.devices.where().findFirstSync();
    }

    if (device == null) {
      status.value = "Error: No Device Found for LSTM inference";
      isRunning.value = false;
      return {'code': -3, 'message': 'No device found'};
    }

    final lstmEngine = SaviaLstmInferenceEngine(_db);
    final res = await lstmEngine.runDailyInference(device.deviceIdentifier);

    progress.value = 1.0;
    status.value = "LSTM Inference: ${res['message']}";
    lastInferenceTime.value = DateTime.now();
    isRunning.value = false;

    onDbUpdated?.call();
    return res;
  }

  Future<void> _loadModelFromSettings() async {}

  Future<void> runIrrigationRecommendation([String? deviceId]) async {
    final settings = _db.getAppSettings();
    final now = DateTime.now();
    final h = now.hour;
    final startH = settings.agronomicDayStart; // e.g. 19
    final endH = settings.agronomicDayEnd;     // e.g. 9

    final bool isYellowZone = (endH < startH) 
        ? (h >= endH && h < startH)
        : (h >= endH || h < startH);

    if (isYellowZone && !settings.alwaysForceInference) {
      status.value = "Restricted: Yellow Zone (Gathering). Inference allowed only in Green Zone ($startH:00 - $endH:00).";
      isRunning.value = false;
      return;
    }

    isRunning.value = true;
    progress.value = 0.1;
    status.value = "Loading ML Model...";

    await _loadModelFromSettings();

    progress.value = 0.5;
    status.value = "Fetching CESAR Prediction...";

    Device? device;
    if (deviceId != null) {
      device = _db.isar.devices.where().deviceIdentifierEqualTo(deviceId).findFirstSync();
    } else {
      device = _db.isar.devices.where().findFirstSync();
    }

    if (device == null || device.newPredictions.isEmpty) {
      status.value = "Error: No Prediction Found for device";
      isRunning.value = false;
      return;
    }

    final latestPrediction = device.newPredictions.last;
    double predHum = latestPrediction.value ?? 0.0;
    final double rawPredHum = predHum;
    if (predHum > 1.0) predHum = predHum / 100.0;

    progress.value = 0.8;
    status.value = "Running RF Classifier...";

    _db.sanitizeCorruptedFutureData(device.deviceIdentifier);
    DateTime refDate = _db.getReferenceTime(
      device.deviceIdentifier,
      isConnected: BleService.instance?.isConnected ?? false,
    );
        
    final cutoffMs = refDate.subtract(const Duration(hours: 48)).millisecondsSinceEpoch;

    print('[LocalDB Inference Verbose] === START LOCAL DB INFERENCE ===');
    print('[LocalDB Inference Verbose] Station ID             : ${device.deviceIdentifier}');
    print('[LocalDB Inference Verbose] Raw Prediction Value   : $rawPredHum | Normalized predHum: $predHum');
    print('[LocalDB Inference Verbose] Prediction Timestamp   : ${latestPrediction.tsMs}');
    print('[LocalDB Inference Verbose] Reference Date (refDate): $refDate');
    print('[LocalDB Inference Verbose] 48h Cutoff (refDate-48h): ${DateTime.fromMillisecondsSinceEpoch(cutoffMs)}');
    print('[LocalDB Inference Verbose] Station Coordinates   : Lat=${device.latitude}, Lon=${device.longitude}');

    final loc = _db.getLocationSettings();
    final lat = device.latitude ?? loc.latitude;
    final lon = device.longitude ?? loc.longitude;

    print('[LocalDB Inference Verbose] Fetching 48h weather forecast from Open-Meteo for ($lat, $lon) relative to $refDate...');
    final weatherClient = OpenMeteoClient(latitude: lat, longitude: lon);
    final weatherData = await weatherClient.fetchForecast(referenceDate: refDate);
    _db.saveWeatherForecast(device.deviceIdentifier, weatherData);

    final double radSum = weatherData.shortwaveRadiation.isNotEmpty
        ? weatherData.shortwaveRadiation.reduce((a, b) => a + b)
        : 0.0;

    print('[LocalDB Inference Verbose] Calculated 48h Shortwave Radiation Sum: $radSum W/m² (accumulated)');

    // ponytail: Single unified inference core function used for both Local DB & RAM Emulation
    final result = evaluateRecommendation(
      radSum: radSum,
      predHum: predHum,
      refDate: refDate,
      invertModelOutput: settings.invertModelOutput,
      verbosePrefix: '[LocalDB Inference Verbose]',
    );

    final recommendation = result['recommendation'] as String;
    // ignore: unused_local_variable
    final resultClass = result['resultClass'] as int;

    // Save back to device with explicit timestamp & model metadata
    _db.isar.writeTxnSync(() {
       latestPrediction.tsMs ??= refDate.millisecondsSinceEpoch;
       latestPrediction.kind = recommendation;
       latestPrediction.model = 'RandomForest';
       device!.updatedAt = DateTime.now();
       device.isSynced = false;
       _db.isar.devices.putSync(device);
    });

    onDbUpdated?.call();
    
    progress.value = 1.0;
    status.value = "Verdict: ${result['verdict']}";
    lastInferenceTime.value = DateTime.now();
    isRunning.value = false;

    print('[LocalDB Inference Verbose] Final Verdict: Verdict: ${result['verdict']}');
    print('[LocalDB Inference Verbose] === END LOCAL DB INFERENCE ===');
  }

  String _generateRecommendationFromClass(int resultClass) {
    if (resultClass == 1) {
      return 'SATURATION RISK: Irrigation perjudicial tomorrow. DO NOT IRRIGATE.';
    } else {
      return 'HEALTHY: Irrigation safe / Not perjudicial.';
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
    final double normalizedPredHum = predHum > 1.0 ? predHum / 100.0 : predHum;

    print('$verbosePrefix === START RF INFERENCE EVALUATION ===');
    print('$verbosePrefix Raw predHum Input: $predHum | Normalized: $normalizedPredHum');
    print('$verbosePrefix 48h Radiation Sum Input: $radSum W/m²');
    print('$verbosePrefix Reference Date: $refDate');

    final probs = rf.score([radSum, normalizedPredHum]);
    print('$verbosePrefix RF Model Score Input: [$radSum, $normalizedPredHum] -> Output Probs: $probs');

    int resultClass = (probs.length > 1 && probs[1] > probs[0]) ? 1 : 0;
    print('$verbosePrefix Raw Result Class: $resultClass | Invert Setting: $invertModelOutput');

    if (invertModelOutput) {
      resultClass = resultClass == 1 ? 0 : 1;
      print('$verbosePrefix Inverted Result Class: $resultClass');
    }

    final recommendation = _generateRecommendationFromClass(resultClass);
    final verdictStr = resultClass == 1 ? 'Perjudicial' : 'Healthy';

    final now = DateTime.now();
    final bool isEmulated = refDate != null &&
        (refDate.day != now.day || refDate.month != now.month || refDate.year != now.year);
    final String emuNotice = isEmulated
        ? ' [EMULATED: Date ${refDate.toIso8601String().split('T')[0]}]'
        : '';

    print('$verbosePrefix Final Verdict: $verdictStr$emuNotice');
    print('$verbosePrefix === END RF INFERENCE EVALUATION ===');

    return {
      'resultClass': resultClass,
      'verdict': '$verdictStr$emuNotice',
      'recommendation': recommendation,
      'radSum': radSum,
      'predHum': normalizedPredHum,
      'isEmulated': isEmulated,
      'refDate': refDate,
    };
  }
}


