import "dart:async";
import '../core/ble/ble_service.dart';
import '../core/ble/cbor_helper.dart';
import '../core/db/database_service.dart';
import '../data/schemas/soil_humidity_schema.dart';

class BleDataProcessor {
  final BleService _bleService;
  final DatabaseService _dbService;
  StreamSubscription? _subscription;
  


  final _onPredictedHumidityProcessed = StreamController<double>.broadcast();
  Stream<double> get onPredictedHumidityProcessed => _onPredictedHumidityProcessed.stream;

  BleDataProcessor(this._bleService, this._dbService);

  void startListening() {
    _subscription = _bleService.dataStream.listen(_handleData);
  }

  void stopListening() {
    _subscription?.cancel();
  }

  void _handleData(Object data) {
    if (data is Map) {
      final map = CborHelper.asMap(data);
      if (map != null) {
        _processMapPayload(map);
      }
    } else if (data is List) {
      final List<Map<String, dynamic>> soilHumidityRecords = [];
      final List<Map<String, dynamic>> predictionRecords = [];

      for (var item in data) {
        final map = CborHelper.asMap(item);
        if (map == null) continue;
        
        final String? kind = map['kind'] as String?;
        if (kind == 'soil_moisture') {
          soilHumidityRecords.add(map);
        } else if (kind == 'hs30_forecast') {
          predictionRecords.add(map);
        }
      }

      if (soilHumidityRecords.isNotEmpty) {
        _processSoilMoistureBatch(soilHumidityRecords);
      }
      if (predictionRecords.isNotEmpty) {
        _processPredictionBatch(predictionRecords);
      }
    }
  }

  void _processMapPayload(Map<String, dynamic> map) {
    final String? op = map['op'] as String?;
    if (op == 'infer_done') {
      final bool ok = map['ok'] as bool? ?? false;
      if (ok) {
        final double? hs30Min = (map['hs30_min'] as num?)?.toDouble();
        if (hs30Min != null) {
          final double predictedHumidity = hs30Min * 100.0;
          print('BleDataProcessor: Real-time inference complete. Predicted: $predictedHumidity%');
          _dbService.savePrediction(
            DateTime.now().millisecondsSinceEpoch,
            predictedHumidity,
            "Calculating recommendation..."
          );
          _onPredictedHumidityProcessed.add(predictedHumidity);
        }
      } else {
        print('BleDataProcessor: Real-time inference failed on Pico!');
      }
    }
  }

  void _processSoilMoistureBatch(List<Map<String, dynamic>> records) {
    final List<SoilHumidityRecord> dbRecords = [];
    for (var r in records) {
      final int? tsMs = r['ts_ms'] as int?;
      final double? val = (r['value'] as num?)?.toDouble();
      if (tsMs != null && val != null) {
        // Convert fraction (0-1) to percentage (0-100)
        dbRecords.add(SoilHumidityRecord(tsMs, val * 100.0));
      }
    }

    if (dbRecords.isNotEmpty) {
      print('BleDataProcessor: Batch writing ${dbRecords.length} soil moisture readings to Realm...');
      _dbService.saveSoilHumidityBatch(dbRecords);
    }
  }

  void _processPredictionBatch(List<Map<String, dynamic>> records) {
    double? latestVal;
    for (var r in records) {
      final int? tsMs = r['ts_ms'] as int?;
      final double? val = (r['value'] as num?)?.toDouble();
      if (tsMs != null && val != null) {
        final double predictedHumidity = val * 100.0;
        latestVal = predictedHumidity;
        _dbService.savePrediction(
          tsMs,
          predictedHumidity,
          "Calculating recommendation..."
        );
      }
    }

    if (latestVal != null) {
      _onPredictedHumidityProcessed.add(latestVal);
    }
  }
}
