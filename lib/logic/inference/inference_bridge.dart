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

    // TODO: implement proper radiation sum from new weather models
    const radSum = 0.0; 
    
    final probs = rf.score([radSum, predHum]);
    int resultClass = (probs.length > 1 && probs[1] > probs[0]) ? 1 : 0;

    final settings = _db.getAppSettings();
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

