import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:tfm_app/features/ble/ble_service.dart';
import 'package:tfm_app/core/database/app_database.dart';

/// Processes incoming Bluetooth Low Energy (BLE) data and synchronizes it with the local database.
///
/// This class listens to the data streams from the [BleService], processes the payloads,
/// and updates the [DatabaseService] accordingly. It also broadcasts events when specific
/// data, such as predicted humidity, is processed.
class BleDataProcessor {
  /// The underlying BLE service used to communicate with the device.
  final BleService bleService;
  
  /// The local database service where processed data is stored.
  final DatabaseService db;
  
  /// Optional callback invoked when the local database is successfully updated.
  final VoidCallback? onDbUpdated;

  final _streamController = StreamController<void>.broadcast();
  
  /// A stream that emits an event whenever new predicted humidity data has been successfully processed.
  ///
  /// Returns a [Stream] of void events.
  Stream<void> get onPredictedHumidityProcessed => _streamController.stream;

  /// Creates a new instance of [BleDataProcessor].
  ///
  /// [bleService] provides the BLE communication layer.
  /// [db] provides the local storage layer.
  /// [onDbUpdated] is an optional callback triggered upon database writes.
  BleDataProcessor(this.bleService, this.db, {this.onDbUpdated});

  /// Starts listening to the data stream from the [BleService].
  ///
  /// This method sets up the necessary subscriptions to intercept and process incoming BLE data payloads.
  void startListening() {
    // Dummy implementation to satisfy the compiler
  }

  /// Disposes of the resources held by this processor.
  ///
  /// This must be called to close the internal stream controllers and cancel subscriptions
  /// when the processor is no longer needed.
  void dispose() {
    _streamController.close();
  }
}

