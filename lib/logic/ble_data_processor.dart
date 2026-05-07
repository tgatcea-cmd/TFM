import "dart:async";
// import 'dart:typed_data';
import '../core/ble/ble_service.dart';
import '../core/db/database_service.dart';

class BleDataProcessor {
  final BleService _bleService;
  final DatabaseService _dbService;
  StreamSubscription? _subscription;
  
  final _onDataProcessed = StreamController<void>.broadcast();
  Stream<void> get onDataProcessed => _onDataProcessed.stream;

  BleDataProcessor(this._bleService, this._dbService);

  void startListening() {
    _subscription = _bleService.dataStream.listen(_handleData);
  }

  void stopListening() {
    _subscription?.cancel();
  }

  void _handleData(List<int> data) {
    if (data.isEmpty) return;

    // Protocol interpretation:
    // First byte could be data type
    final int type = data[0];
    
    switch (type) {
      case 0x11: // Soil Humidity Data packet
        _processSoilHumidity(data.sublist(1));
        break;
      default:
        print('Unknown data type: $type');
    }
  }

  void _processSoilHumidity(List<int> payload) {
    // Assuming payload: [hour_offset, humidity_high_byte, humidity_low_byte]
    if (payload.length < 3) return;

    final int hourOffset = payload[0];
    final int humidityRaw = (payload[1] << 8) | payload[2];
    final double humidity = humidityRaw / 100.0; // Example: scaling

    print('Received Soil Humidity: $humidity% (Offset: $hourOffset)');
    
    // Calculate timestamp based on current time minus offset
    final DateTime timestamp = DateTime.now().subtract(Duration(hours: hourOffset));
    
    _dbService.saveSoilHumidity(timestamp.millisecondsSinceEpoch, humidity);
    _onDataProcessed.add(null);
  }
}
