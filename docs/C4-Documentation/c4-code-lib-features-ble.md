# C4 Code-Level Documentation: `lib/features/ble`

## 1. Overview Section
- **Name**: BLE Feature
- **Description**: Contains logic for discovering, connecting, authenticating, and exchanging data with Bluetooth Low Energy IoT devices (specifically Savia nodes).
- **Location**: `lib/features/ble`
- **Language**: Dart
- **Purpose**: Provides a robust wrapper around BLE operations, chunk assembly, security handshakes, and translation of incoming bytes into structured data payloads for the core database.

## 2. Code Elements Section

### Classes

#### `BleConstants`
- **Description**: Centralizes all UUIDs corresponding to the BLE GATT services and characteristics exposed by the IoT hardware.
- **Location**: `lib/features/ble/ble_constants.dart`
- **Dependencies**: None.

#### `BleDataProcessor`
- **Description**: Connects `BleService` data streams with the `AppDatabase`. Parses incoming historical payloads and live telemetry and persists them.
- **Location**: `lib/features/ble/ble_controller.dart`
- **Dependencies**: `BleService`, `DatabaseService`.
- **Methods**:
  - `BleDataProcessor(this.bleService, this.db, {this.onDbUpdated})`: Creates a new processor attached to a BLE service instance.
  - `void startListening()`: Subscribes to the raw object stream from `BleService` and interprets maps.
  - `void dispose()`: Closes internal stream controllers and detaches listeners.

#### `PicoHandshakeModule`
- **Description**: Handles secure handshake routines, HMAC calculation, or challenge-response exchanges specific to the hardware protocol.
- **Location**: `lib/features/ble/ble_service.dart`
- **Dependencies**: `crypto`, `convert`.
- **Methods**:
  - `PicoHandshakeModule({this.sharedSecret = ""})`: Configures the module with a shared secret.

#### `BleService`
- **Description**: The core Bluetooth service wrapper utilizing `flutter_blue_plus`. Manages scanning, connecting, characteristic caching, writing commands, and listening to data pipelines.
- **Location**: `lib/features/ble/ble_service.dart`
- **Dependencies**: `flutter_blue_plus`, `BleChunkAssembler`, `PicoHandshakeModule`.
- **Methods**:
  - `BleService({required this.handshakeModule})`: Constructor mapping the handshake strategy.
  - `Future<void> startScan() async`: Starts discovering BLE devices matching specific filters.
  - `Future<void> stopScan() async`: Cancels ongoing discovery.
  - `Future<void> _setupDataNotifications() async`: Subscribes to the data TX characteristic.
  - `void _cacheCharacteristics(List<BluetoothService> services)`: Discovers and saves characteristic references for easy access.
  - `void _setupStateListener(BluetoothDevice device)`: Reacts to connection/disconnection events.
  - `Future<void> disconnect() async`: Safely detaches from the current device.
  - `Future<void> dispose() async`: Cleans up service resources.
  - `Future<void> syncTime(int timeOffsetHours) async`: Writes current epoch to the RTC characteristic.
  - `Future<void> sendHourlyForecast(List<double> pastTemperatures, List<double> futureTemperatures) async`: Sends Open-Meteo data to the node.
  - `Future<void> requestData(String kind, {int? from, int? to, int? limit}) async`: Commands the node to dump specific historical data.
  - `Future<void> triggerInference() async`: Requests on-device inference execution.
  - `Future<void> toggleDebugMode() async`: Toggles debug logs on the device.
  - `Future<void> sendFillAverageInstruction() async`: Commands node to backfill missing entries.
  - `Future<void> clearStorage() async`: Instructs node to wipe its local flash storage.
  - `Future<Map<String, dynamic>?> readConfig() / readStatus() / readPinmap()`: Fetches JSON payloads from static characteristics.
  - `Future<bool> changePassword(String currentPassword, String newPassword) async`: Rotates the device password.
  - `Future<void> setInferenceMode(String mode) async`: Updates inference configuration (Edge vs Host).

#### `BleChunkAssembler`
- **Description**: Helper class to handle MTU limits. Reconstructs larger JSON payloads from fragmented byte chunks delivered over BLE.
- **Location**: `lib/features/ble/chunk_assembler.dart`
- **Dependencies**: None.
- **Methods**:
  - `void reset()`: Clears the internal buffer.
  - `void processChunkBytes(List<int> bytes)`: Appends incoming bytes and checks for termination markers to emit complete payloads.
  - `void dispose()`: Clears stream controllers.

## 3. Dependencies Section
- **Internal dependencies**:
  - `BleDataProcessor` depends on `BleService` and the core `DatabaseService`.
  - `BleService` depends on `BleChunkAssembler` to reconstruct its payloads.
- **External dependencies**:
  - `package:flutter_blue_plus/flutter_blue_plus.dart`: Low-level BLE API.
  - Crypto libraries for handshake processing.

## 4. Relationships Section
The `BleService` serves as the sole bridge between the mobile app and the physical IoT nodes. It provides high-level APIs used by `home_screen.dart` and `config_screen.dart`. The raw data received is fed into `BleDataProcessor`, which translates it into domain entities and stores them via `DatabaseService`.
