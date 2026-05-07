import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'ble_constants.dart';
import '../../data/models/processed/daily_weather.dart';

/// Abstract interface for Handshake to allow easy replacement.
abstract class IHandshakeModule {
  Future<bool> performHandshake(BluetoothDevice device, BluetoothCharacteristic? handshakeChar);
}

/// Initial implementation for RPi Pico 2 W (placeholder logic).
class PicoHandshakeModule implements IHandshakeModule {
  @override
  Future<bool> performHandshake(BluetoothDevice device, BluetoothCharacteristic? handshakeChar) async {
    if (handshakeChar == null) return false;
    // TODO: Implement actual challenge-response with Pico 2 W
    print('Performing handshake with Pico 2 W...');
    // Example: Write an app ID to verify
    await handshakeChar.write([0xDE, 0xAD, 0xBE, 0xEF]);
    return true; 
  }
}

class BleService {
  final IHandshakeModule handshakeModule;
  BluetoothDevice? _connectedDevice;
  StreamSubscription<BluetoothConnectionState>? _stateSubscription;
  
  BluetoothCharacteristic? _handshakeChar;
  BluetoothCharacteristic? _commandChar;
  BluetoothCharacteristic? _dataChar;

  final _dataController = StreamController<List<int>>.broadcast();
  Stream<List<int>> get dataStream => _dataController.stream;

  BleService({required this.handshakeModule});

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;
  bool get isConnected => _connectedDevice != null;

  Future<void> startScan() async {
    if (await FlutterBluePlus.isSupported == false) {
      print('BLE not supported on this platform');
      return;
    }
    
    // Check adapter state
    var state = await FlutterBluePlus.adapterState.first;
    print('Current adapter state: $state');
    if (state != BluetoothAdapterState.on) {
      print('Bluetooth adapter is not ON. State: $state');
      return;
    }

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<bool> connect(BluetoothDevice device) async {
    try {
      print('Connecting to ${device.platformName}...');
      await device.connect(autoConnect: false, license: License.free);

      print('Discovering services...');
      List<BluetoothService> services = await device.discoverServices();

      print('Caching characteristics...');
      _cacheCharacteristics(services);

      if (_handshakeChar == null) {
        print('Error: Handshake characteristic not found!');
        await device.disconnect();
        return false;
      }

      print('Initiating handshake...');
      bool authenticated = await handshakeModule.performHandshake(device, _handshakeChar);

      if (authenticated) {
        print('Handshake successful!');
        _connectedDevice = device;
        _setupStateListener(device);
        await _setupDataNotifications();
        return true;
      } else {
        print('Handshake failed!');
        await device.disconnect();
        return false;
      }
    } catch (e) {
      print('Connection error: $e');
      return false;
    }
  }


  Future<void> _setupDataNotifications() async {
    if (_dataChar == null) return;
    await _dataChar!.setNotifyValue(true);
    _dataChar!.lastValueStream.listen((value) {
      if (value.isNotEmpty) {
        _dataController.add(value);
      }
    });
  }

  void _cacheCharacteristics(List<BluetoothService> services) {
    for (var service in services) {
      String sUuid = service.uuid.toString().toLowerCase();
      print('Found Service: $sUuid');
      
      // Check if it matches our service (handling both short and long formats)
      if (sUuid == BleConstants.serviceUuid.toLowerCase() || sUuid.contains('ffe0')) {
        print('Target Service Matches!');
        for (var char in service.characteristics) {
          String cUuid = char.uuid.toString().toLowerCase();
          print('Found Char: $cUuid');
          
          if (cUuid == BleConstants.handshakeUuid.toLowerCase() || cUuid.contains('ffe1')) {
            print('Handshake Char Found');
            _handshakeChar = char;
          } else if (cUuid == BleConstants.commandUuid.toLowerCase() || cUuid.contains('ffe2')) {
            print('Command Char Found');
            _commandChar = char;
          } else if (cUuid == BleConstants.dataUuid.toLowerCase() || cUuid.contains('ffe3')) {
            print('Data Char Found');
            _dataChar = char;
          }
        }
      }
    }
  }

  void _setupStateListener(BluetoothDevice device) {
    _stateSubscription = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _connectedDevice = null;
        _handshakeChar = null;
        _commandChar = null;
        _dataChar = null;
        _stateSubscription?.cancel();
      }
    });
  }

  Future<void> disconnect() async {
    await _connectedDevice?.disconnect();
    _connectedDevice = null;
  }

  /// Sends a command byte and waits for response (simplified).
  Future<void> sendCommand(List<int> bytes) async {
    if (_commandChar == null) return;
    await _commandChar!.write(bytes);
  }

  /// Request soil humidity sync from station
  Future<void> requestSync() async {
    await sendCommand([0x01]); // 0x01 = Sync Request
  }

  /// Send aggregated daily weather data to station
  /// Protocol: [0x02, ...payload]
  /// We pack mean values for Temp, Hum, Rad, and sum for Prec as 16-bit uints (scale 100)
  Future<void> sendProcessedWeatherData(ProcessedWeatherDay day) async {
    final bd = ByteData(9);
    bd.setUint8(0, 0x02);
    bd.setUint16(1, (day.temperature.mean * 100).toInt(), Endian.big);
    bd.setUint16(3, (day.humidity.mean * 100).toInt(), Endian.big);
    bd.setUint16(5, (day.radiation.mean * 100).toInt(), Endian.big);
    bd.setUint16(7, (day.precipitation.sum * 100).toInt(), Endian.big);

    await sendCommand(bd.buffer.asUint8List());
    print('Sent Env Data: T:${day.temperature.mean} H:${day.humidity.mean} R:${day.radiation.mean} P:${day.precipitation.sum}');
  }
}
