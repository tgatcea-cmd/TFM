import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:tfm_app/features/ble/ble_service.dart';
import 'package:tfm_app/core/database/app_database.dart';

class BleDataProcessor {
  final BleService bleService;
  final DatabaseService db;
  final VoidCallback? onDbUpdated;

  final _streamController = StreamController<void>.broadcast();
  Stream<void> get onPredictedHumidityProcessed => _streamController.stream;

  BleDataProcessor(this.bleService, this.db, {this.onDbUpdated});

  void startListening() {
    // Dummy implementation to satisfy the compiler
  }
}

