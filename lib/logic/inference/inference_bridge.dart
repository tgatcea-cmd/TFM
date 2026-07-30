import "dart:async";
import 'package:signals/signals.dart';
import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';

import '../../core/db/database_service.dart';
import '../../core/ml/random_forest.dart' as rf;
import '../../data/models/device.dart';

class InferenceBridge {
  final DatabaseService _db;
  final VoidCallback? onDbUpdated;

  final status = signal<String>("Idle");
  final progress = signal<double>(0.0);
  final lastInferenceTime = signal<DateTime?>(null);
  final isRunning = signal<bool>(false);

  InferenceBridge(this._db, {this.onDbUpdated});

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
    final predHum = latestPrediction.value ?? 0.0;

    progress.value = 0.8;
    status.value = "Running RF Classifier...";

    final weatherHistory = _db.getWeatherHistory();
    final double radSum = weatherHistory.isNotEmpty
        ? weatherHistory.fold(0.0, (sum, record) => sum + record.radiation)
        : 0.0;
    
    final probs = rf.score([radSum, predHum]);
    int resultClass = (probs.length > 1 && probs[1] > probs[0]) ? 1 : 0;

    if (settings.invertModelOutput) {
      resultClass = resultClass == 1 ? 0 : 1;
    }

    final recommendation = _generateRecommendationFromClass(resultClass);
    
    // Save back to device
    _db.isar.writeTxnSync(() {
       latestPrediction.kind = recommendation;
       _db.isar.devices.putSync(device!);
    });

    onDbUpdated?.call();
    
    progress.value = 1.0;
    status.value = "Verdict: ${resultClass == 1 ? 'Perjudicial' : 'Healthy'}";
    lastInferenceTime.value = DateTime.now();
    isRunning.value = false;

    print('InferenceBridge: RF TFLite result Class $resultClass -> $recommendation');
  }

  String _generateRecommendationFromClass(int resultClass) {
    if (resultClass == 1) {
      return 'SATURATION RISK: Irrigation perjudicial tomorrow. DO NOT IRRIGATE.';
    } else {
      return 'HEALTHY: Irrigation safe / Not perjudicial.';
    }
  }
}

