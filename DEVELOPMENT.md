# Development Documentation - TFM App (Tobias)

## Tech Stack Summary
- **Framework**: Flutter 3.41.9 (Dart 3.11.5)
- **BLE**: `flutter_blue_plus` (Station comms)
- **HTTP**: `http` (Open-Meteo API)
- **ML**: `tflite_flutter` (LSTM + RF Inference)
- **Database**: `realm` (Device local sync)
- **State Mgmt**: `flutter_riverpod` + `signals` (Reactive UX)

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

## Communication: BLE Protocol (Cesar's Protocol v=1)
- **Status**: SUCCESS. Implementation aligned with Cesar's Protocol and secure authentication.
- **Service UUID**: `5a71a000-0000-0000-0000-000000000001`
- **Characteristics**:
    - `0x10` (Status, Read/Notify): Firmware version, uptime, and 16-byte random Challenge Nonce.
    - `0x11` (Time Sync, Write): App writes current epoch milliseconds to sync station's RTC.
    - `0x12` (Weather, Write): Pushes 24-48h Open-Meteo temperature forecast array.
    - `0x20` (Data Request, Write): Command interface for authentication (`auth` with 32-byte HMAC), data requests (`get`), and inference triggers (`infer`).
    - `0x21` (Data Response, Notify): Returns reassembled sliced chunks containing raw readings, statistics, or predictions.
- **Data Encoding**: CBOR (Concise Binary Object Representation).
- **Security Handshake**: HMAC-SHA256 Challenge-Response validation using a 128-bit Shared Secret.

## Inference Layer (Phase 4 COMPLETE)
### Architecture: Collaborative ML
- **Infrastructure**: `TfliteService` manages multiple interpreters (LSTM + RF).
- **Reactive State**: `signals` package used for real-time inference tracking (`status`, `progress`, `isRunning`).
- **Data Fusion**: 
    - IoT Station (FPGA): Runs LSTM for soil humidity prediction (`HS30_min_t+1`).
    - App: Receives prediction via BLE `0x12`.
    - App: Runs Random Forest (`rf_irrigation.tflite`) using `radiacion_sum_t0` (Meteo) + FPGA result.
- **Conversion Path**: Sklearn -> Hummingbird (Torch) -> ONNX -> TFLite (`onnx2tf`).
- **Verdict Logic**: 
    - `Class 1`: Saturation Risk (Perjudicial). Recommendation: **DO NOT IRRIGATE**.
    - `Class 0`: Healthy. Recommendation: **Irrigation Safe**.

### Implementation: `TfliteService`
- **Output Handling**: Supports multi-output models (label + probabilities) and `Int64` tensor types (required by Hummingbird models).

## Data Persistence: Realm DB
- **Location**: `lib/data/schemas/` and `lib/core/db/`
- **Schemas**: `SoilHumidityRecord`, `WeatherRecord`, `PredictionRecord`, `LocationSettings`.
- **Service**: `DatabaseService` manages the Realm instance.

## Implementation Status (2026-05-07)
- [x] BLE Handshake & Connectivity.
- [x] Linux BLE First-class Support (Verified May 2026).
- [x] Realm DB Persistence (Soil Humidity, Weather, Predictions, Location).
- [x] Dashboard UI (Scan, Connect, Sync, Inference).
- [x] TFLite Infrastructure (LSTM + RF).
- [x] Automated Weather Data bridge (0x02 - 24h temperature sequence).
- [x] Automated Inference Triggering (0x12 -> RF -> Verdict).
- [x] Location Management (GPS + OSM Picker).
- [x] Signals Integration (Reactive UX).

## Directory Structure
- `lib/core/`: API clients, BLE service, TFLite wrapper.
- `lib/data/`: Models, Realm schemas, repositories.
- `lib/logic/`: Riverpod providers, Business logic, Inference bridge.
- `lib/ui/`: Screens, widgets, charts.
