import "dart:async";
import 'package:signals/signals.dart';
import '../../core/db/database_service.dart';
import 'tflite_service.dart';

class InferenceBridge {
  final DatabaseService _db;
  final TfliteService _tflite;

  // Signals for UI
  final status = signal<String>("Idle");
  final progress = signal<double>(0.0);
  final lastInferenceTime = signal<DateTime?>(null);
  final isRunning = signal<bool>(false);

  InferenceBridge(this._db, this._tflite);



  /// Runs the Random Forest classifier based on CESAR's prediction and today's radiation
  Future<void> runIrrigationRecommendation() async {
    if (!_tflite.isRfLoaded) {
      status.value = "Error: RF Model Not Loaded";
      return;
    }

    isRunning.value = true;
    progress.value = 0.2;
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
    final resultClass = _tflite.runRfInference(radSum, predHum);

    // 4. Update the recommendation in DB
    final recommendation = _generateRecommendationFromClass(resultClass);
    _db.savePrediction(
      latestPrediction.timestamp, 
      predHum, 
      recommendation
    );
    
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
