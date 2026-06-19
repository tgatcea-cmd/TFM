import "dart:async";
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:signals/signals.dart';
import 'package:flutter/material.dart';

import '../../core/db/database_service.dart';
import '../../core/api/tfm_server_client.dart';
import 'tflite_service.dart';

class InferenceBridge {
  final DatabaseService _db;
  final TfliteService _tflite;
  final VoidCallback? onDbUpdated;

  // Signals for UI
  final status = signal<String>("Idle");
  final progress = signal<double>(0.0);
  final lastInferenceTime = signal<DateTime?>(null);
  final isRunning = signal<bool>(false);

  InferenceBridge(this._db, this._tflite, {this.onDbUpdated});

  Future<void> _loadModelFromSettings() async {
    final settings = _db.getAppSettings();
    final modelName = settings.selectedTfliteModel;
    
    String modelPath = 'assets/models/rf_irrigation.tflite';
    if (modelName != 'rf_irrigation.tflite' && modelName.isNotEmpty) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        modelPath = p.join(dir.path, modelName);
      } catch (e) {
        print('InferenceBridge: Error getting app documents directory: $e');
      }
    }
    await _tflite.loadRfModel(modelPath);
  }

  Future<void> _uploadDatabaseToServer() async {
    try {
      final settings = _db.getAppSettings();
      if (settings.tfmServerUrl.isNotEmpty && 
          settings.tfmServerUrl != 'http://localhost' &&
          settings.tfmServerUrl != 'http://10.0.2.2') {
        final dbPath = _db.getDatabasePath();
        if (dbPath.isNotEmpty) {
          final client = TfmServerClient(
            serverUrl: settings.tfmServerUrl,
            port: settings.tfmServerPort,
            apiKey: settings.tfmServerApiKey,
          );
          print('InferenceBridge: Attempting database upload to server...');
          final ok = await client.uploadDatabase(dbPath);
          print('InferenceBridge: Server database sync success = $ok');
        }
      }
    } catch (e) {
      print('InferenceBridge: Error uploading database to server: $e');
    }
  }

  /// Runs the Random Forest classifier based on CESAR's prediction and today's radiation
  Future<void> runIrrigationRecommendation() async {
    isRunning.value = true;
    progress.value = 0.1;
    status.value = "Loading ML Model...";

    await _loadModelFromSettings();

    if (!_tflite.isRfLoaded) {
      status.value = "Error: RF Model Not Loaded";
      isRunning.value = false;
      return;
    }

    progress.value = 0.3;
    status.value = "Calculating Radiation Sum...";

    final radSum = _db.getTodayRadiationSum();

    progress.value = 0.5;
    status.value = "Fetching CESAR Prediction...";

    final predictions = _db.getPredictionHistory();
    if (predictions.isEmpty) {
      status.value = "Error: No Prediction Found";
      isRunning.value = false;
      return;
    }

    final latestPrediction = predictions.last;
    final predHum = latestPrediction.predictedHumidity;

    progress.value = 0.8;
    status.value = "Running RF TFLite...";

    // Run Random Forest Inference (TFLite)
    int resultClass = _tflite.runRfInference(radSum, predHum);

    // Apply output inversion if setting is active
    final settings = _db.getAppSettings();
    if (settings.invertModelOutput) {
      resultClass = resultClass == 1 ? 0 : 1;
    }

    // 4. Update the recommendation in DB
    final recommendation = _generateRecommendationFromClass(resultClass);
    _db.savePrediction(
      latestPrediction.timestamp, 
      predHum, 
      recommendation
    );

    onDbUpdated?.call();
    
    progress.value = 0.9;
    status.value = "Syncing with Server...";
    
    // Sync database to server asynchronously
    unawaited(_uploadDatabaseToServer());
    
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

