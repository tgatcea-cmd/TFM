import "dart:async";
import '../core/ble/ble_service.dart';
import '../core/ble/cbor_helper.dart';
import '../core/db/database_service.dart';
import '../data/models/models.dart';
import 'package:flutter/material.dart';

class BleDataProcessor {
  final BleService _bleService;
  final DatabaseService _dbService;
  final VoidCallback? onDbUpdated;
  StreamSubscription? _subscription;
  


  final _onPredictedHumidityProcessed = StreamController<double>.broadcast();
  Stream<double> get onPredictedHumidityProcessed => _onPredictedHumidityProcessed.stream;

  BleDataProcessor(this._bleService, this._dbService, {this.onDbUpdated});

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
        final List<dynamic>? vector = map['hs30_vector'] as List<dynamic>?;
        if (vector != null && vector.isNotEmpty) {
          final nowMs = DateTime.now().millisecondsSinceEpoch;
          double? lastLstmValue;
          int targetIndex = -1;

          for (int i = 0; i < vector.length; i++) {
            double val = (vector[i] as num).toDouble();
            double predictedHumidity = val * 100.0;
            int tsMs = nowMs + (i + 1) * 3600000;
            _dbService.savePrediction(
              tsMs,
              predictedHumidity,
              "Calculating recommendation..."
            );

            DateTime dt = DateTime.fromMillisecondsSinceEpoch(tsMs);
            if (dt.hour == 19 && targetIndex == -1) {
              targetIndex = i;
              lastLstmValue = predictedHumidity;
            }
          }

          if (lastLstmValue == null) {
            lastLstmValue = (vector.last as num).toDouble() * 100.0;
          }

          print('BleDataProcessor: Real-time inference complete. 24h vector processed. Predicted at 19:00: $lastLstmValue%');
          onDbUpdated?.call();
          _onPredictedHumidityProcessed.add(lastLstmValue);
        } else {
          final double? hs30Min = (map['hs30_min'] as num?)?.toDouble();
          if (hs30Min != null) {
            final double predictedHumidity = hs30Min * 100.0;
            print('BleDataProcessor: Real-time inference complete. Predicted: $predictedHumidity%');
            _dbService.savePrediction(
              DateTime.now().millisecondsSinceEpoch,
              predictedHumidity,
              "Calculating recommendation..."
            );
            onDbUpdated?.call();
            _onPredictedHumidityProcessed.add(predictedHumidity);
          }
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
      onDbUpdated?.call();
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
      onDbUpdated?.call();
    //   _onPredictedHumidityProcessed.add(latestVal);
    }
  }
}
