# Development Documentation - TFM App (Tobias)

## Tech Stack Summary
- **Framework**: Flutter 3.41.9 (Dart 3.11.5)
- **BLE**: `flutter_blue_plus` (Native) / Web Bluetooth Mock (Web)
- **HTTP**: `http` (Open-Meteo weather API)
- **ML**: `tflite_flutter` (Native) / `tflite_web` via CDN (Web)
- **Database**: `realm` (Native) / In-Memory lists (Web)
- **State Mgmt**: `flutter_riverpod` (Dependency Injection and State Notifiers)
- **Localization**: Riverpod-driven language localization dictionary

## Architecture: Cross-Platform & Conditional Exports
To run on both native device targets and web web-browsers, core service modules utilize Dart's conditional imports/exports at compile-time:
- **`lib/core/ble/ble_service.dart`**: Exports `ble_service_native.dart` (FBP based) or `ble_service_web.dart` (simulates status reads, HMAC pairing, time sync, mock telemetries, and mock inference events).
- **`lib/core/db/database_service.dart`**: Exports `database_service_native.dart` (Realm DB configuration) or `database_service_web.dart` (lightweight list arrays storing `models_web.dart` elements to prevent loading Realm dependencies).
- **`lib/logic/inference/tflite_service.dart`**: Exports `tflite_service_native.dart` (TFLite C-API bindings) or `tflite_service_web.dart` (WASM CDN-driven browser interpreter). Both feature decision rules fallback in case of loading errors.

## Data Layer: Open-Meteo Integration
### Implementation: `OpenMeteoClient`
- **Location**: `lib/core/api/open_meteo_client.dart`
- **Endpoints**:
    - Forecast: `https://api.open-meteo.com/v1/forecast`
- **Methods**:
    - `fetchForecast()`: Retrieves hourly forecast data for Today + Tomorrow (48h). Includes timeout settings and retry logic for resiliency.

### Processing: `WeatherProcessor`
- **Location**: `lib/logic/weather_processor.dart`
- **Function**: Aggregates hourly `WeatherData` into `ProcessedWeatherDay` (daily stats: Min, Max, Mean, StdDev, and Sum).

## Communication: BLE Protocol (Cesar's Protocol v=1)
- **Service UUID**: `5a71a000-0000-0000-0000-000000000001`
- **Characteristics**:
    - `0x10` (Status, Read/Notify): Uptime, version, and 16-byte random challenge nonce.
    - `0x11` (Time Sync, Write): Syncs station RTC using current epoch millisecond json payload.
    - `0x12` (Weather, Write): Pushes 24h hourly forecast temperatures.
    - `0x20` (Data Request, Write): CBOR queries for authentication (`auth` HMAC), telemetry (`get` kind `raw`/`pred`), and inference triggers (`infer`).
    - `0x21` (Data Response, Notify): Reassembles chunks (sequence, total, eof, payload) containing data responses.
- **Security Handshake**: HMAC-SHA256 Challenge-Response validation using a 128-bit Shared Secret.
- **Linux Device Scan Fix**: Override local `flutter_blue_plus_linux` package D-Bus triggers to correctly scan and update RSSI of cached/known Bluetooth devices.

## Inference Layer (Phase 4 COMPLETE)
- **Infrastructure**: `TfliteService` handles model loading and inference cycles.
- **Collaborative Edge ML**: 
    1. IoT Station (FPGA/Pico): Runs **LSTM** model for soil humidity prediction (`HS30_min_t+1`).
    2. Mobile App: Receives predicted humidity via BLE `0x21` (`hs30_forecast` / `infer_done`).
    3. Mobile App: Runs **Random Forest** (`rf_irrigation.tflite`) using Open-Meteo `radiation_sum` + FPGA forecast.
- **Verdict Verdicts**: 
    - `Class 1`: Saturation Risk. Recommendation: **DO NOT IRRIGATE** (Perjudicial).
    - `Class 0`: Healthy. Recommendation: **Irrigation Safe**.

## Database Schemas & Persistence
- **Location**: `lib/data/schemas/` and `lib/core/db/`
- **Schemas**: `SoilHumidityRecord`, `WeatherRecord`, `PredictionRecord`, `LocationSettings`, `SavedDevice`.
- **Optimization**: Write-batching via Realm `addAll` is used on native inserts to avoid transaction overhead.

## UI Navigation and Views
Adheres to two core presentation states:
- **State 0 (No Sensor)**: Scans for stations. Displays a bottom navigation bar and a central button to launch the `Device_menu` modal (contains Saved and Nearby scanner filters).
- **State 1 (Sensor Paired)**: Location & date metadata context, unified analytics chart showing history, predictions, and solar radiation, large RF recommendation card, and lazy-loaded historical list.
- **Settings View**: Lang translator toggle, permissions status, auto/manual gps configuration, and per-device database purging.

## Directory Structure
- `lib/core/` — Conditional platform services (API, BLE, DB) and localization dictionary.
- `lib/data/` — Realm schemas, conditional models, and helper repositories.
- `lib/logic/` — Riverpod providers, inference bridge, and weather processors.
- `lib/ui/` — Stylings, views (`telemetry_view.dart`, `config_view.dart`, `sync_progress_dialog.dart`), and custom chart canvas (`unified_chart.dart`).
