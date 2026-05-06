import '../../core/db/database_service.dart';
import '../../data/models/processed/daily_weather.dart';
import 'tflite_service.dart';

class InferenceBridge {
  final DatabaseService _db;
  final TfliteService _tflite;

  InferenceBridge(this._db, this._tflite);

  /// Prepares data and runs inference
  /// Target: Predict next soil humidity based on last 10 readings + weather context
  Future<double> predictNextHumidity(ProcessedWeatherDay? weather) async {
    if (!_tflite.isLoaded) {
      print('InferenceBridge: Model not loaded, skipping.');
      return -1.0;
    }

    // 1. Fetch last 10 soil humidity readings from Realm
    final history = _db.getSoilHumidityHistory();
    if (history.length < 10) {
      print('InferenceBridge: Insufficient data (need 10, have ${history.length}).');
      return -1.0;
    }

    // Take the 10 most recent and sort by timestamp ascending
    final last10 = history.sublist(history.length - 10)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final sequence = last10.map((e) => e.value).toList();

    // 2. Data Fusion (Simplified PoC)
    // In a production model, weather means would be concatenated or used as exogenous features.
    // For now, we follow the [1, 10, 1] structure defined in the notebooks.
    
    print('InferenceBridge: Running inference on sequence: $sequence');
    final result = _tflite.runInference(sequence);
    
    // 3. Save prediction to DB
    if (result != -1.0) {
      _db.savePrediction(
        DateTime.now().millisecondsSinceEpoch, 
        result, 
        _generateRecommendation(result)
      );
    }

    return result;
  }

  String _generateRecommendation(double predictedHumidity) {
    if (predictedHumidity < 30.0) {
      return 'CRITICAL: Irrigation required immediately.';
    } else if (predictedHumidity < 45.0) {
      return 'WARNING: Low humidity trend. Scheduled irrigation recommended.';
    } else {
      return 'OPTIMAL: No irrigation needed.';
    }
  }
}
