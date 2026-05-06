# Development Documentation - TFM App (Tobias)

## Tech Stack Summary
- **Framework**: Flutter 3.41.9 (Dart 3.11.5)
- **BLE**: `flutter_blue_plus` (Station comms)
- **HTTP**: `http` (Open-Meteo API)
- **ML**: `tflite_flutter` (LSTM/GRU Inference)
- **Database**: `realm` (Device local sync)
- **State Mgmt**: `flutter_riverpod`

## Data Layer: Open-Meteo Integration
### Implementation: `OpenMeteoClient`
- **Location**: `lib/core/api/open_meteo_client.dart`
- **Endpoints**:
    - Forecast: `https://api.open-meteo.com/v1/forecast`
    - Archive: `https://archive-api.open-meteo.com/v1/archive`
- **Methods**:
    - `fetchHistoricalLag()`: Retrieves hourly data for the last 24h (from T-24h to T-1m).
    - `fetchForecast()`: Retrieves hourly data for Today + Tomorrow (48h).

### Processing: `WeatherProcessor`
- **Location**: `lib/logic/weather_processor.dart`
- **Function**: Aggregates `WeatherData` (hourly) into `ProcessedWeatherDay` (daily stats).
- **Statistics calculated**: Min, Max, Mean, StdDev, Sum (for accumulated variables).
- **Target Variables**: Temperature (2m), Humidity (2m), Shortwave Radiation, Precipitation.

## Communication: BLE Protocol
### PoC v1.0 Results (2026-05-06)
- **Status**: SUCCESS. Verified bidirectional flow with RPi Pico 2 W.
- **Service UUID**: `ffe0` (normalized by Android/FBP).
- **Handshake (ffe1)**: App writes `0xDEADBEEF`. Verified authorized state in Pico.
- **Commands (ffe2)**:
    - `0x01` (Sync): Triggers Pico to send historical/sample data.
    - `0x02` (Env): Sends environmental data to station (Aggregated stats).
- **Data (ffe3 - Notify)**:
    - `0x11` (Soil Humidity): `[0x11, hour_offset, hum_hi, hum_lo]`. Parsed and persisted to Realm.

### Implementation: `BleService`
- **Location**: `lib/core/ble/ble_service.dart`
- **Architecture**: Modular and interface-based to facilitate replacement of handshake logic.
- **Components**:
    - `IHandshakeModule`: Interface for authentication protocols.
    - `PicoHandshakeModule`: Target implementation for Raspberry Pi Pico 2 W.
    - `BleConstants`: UUID definitions for Services and Characteristics.
    - `BleService`: Handles scanning, connection, characteristic caching, and command sending.
    - `BleDataProcessor`: Parses incoming byte streams (e.g., Soil Humidity) and persists to DB.

## Inference Layer (Phase 4)
- **Infrastructure**: `TfliteService` manages the interpreter lifecycle.
- **Data Fusion**: `InferenceBridge` gathers last 10 soil humidity records from Realm.
- **Input Pipeline**: Normalizes/Packs into `[1, 10, 1]` Float32 tensor.
- **Output**: Predicts next humidity value and generates irrigation recommendations.
- **Status**: Model-ready logic; requires real `.tflite` weights to replace placeholders.

## Data Persistence: Realm DB
- **Location**: `lib/data/schemas/` and `lib/core/db/`
- **Schemas**: `SoilHumidityRecord`, `WeatherRecord`, `PredictionRecord`.
- **Service**: `DatabaseService` manages the Realm instance and provides type-safe CRUD.
- **Generation**: Run `dart run realm generate` after schema changes.

## Testing Strategy

### 1. BLE & Protocol Verification
Since testing with real hardware is hardware-dependent:
- **Mocking**: Use `mockito` to mock `BluetoothDevice` and `BluetoothCharacteristic`.
- **Parser Isolation**: Test `BleDataProcessor._handleData` with raw byte arrays to verify correct conversion to `double` and `DateTime`.
- **Handshake**: Verify `PicoHandshakeModule` writes the expected auth bytes (`0xDEADBEEF`) on connection.

### 2. Database Tests
- **Integrity**: Ensure `DatabaseService` handles Primary Key conflicts (using `update: true`).
- **Timestamp Handling**: Verify millisecond precision when saving/retrieving history.

### 3. Integration flow
- **Meteo -> DB**: Verify `OpenMeteoClient` data reaches `DatabaseService`.
- **BLE -> DB**: Verify `BleDataProcessor` saves records correctly upon receiving characteristic notifications.

## Data Models
- `WeatherData`: Raw hourly response from Open-Meteo.
- `DailyStats`: Container for statistical aggregates (Min/Max/Mean/StdDev/Sum).
- `ProcessedWeatherDay`: Daily container for all meteorological variables' stats.

## Implementation Status (2026-05-06)
- [x] BLE Handshake & Connectivity.
- [x] Realm DB Persistence (Soil Humidity, Weather, Predictions).
- [x] Dashboard UI (Scan, Connect, Sync, Inference).
- [x] TFLite Infrastructure (Service + Bridge).
- [x] Automated Weather Data bridge (0x02).

## Directory Structure
- `lib/core/`: API clients, BLE service, TFLite wrapper.
- `lib/data/`: Models, Realm schemas, repositories.
- `lib/logic/`: Riverpod providers, Business logic, Inference bridge.
- `lib/ui/`: Screens, widgets, charts.
