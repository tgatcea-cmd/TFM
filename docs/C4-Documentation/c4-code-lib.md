# 1. Overview Section
- **Name:** lib
- **Description:** Root directory of the `lib` folder in the TFM_APP project. It contains the entry point of the Flutter application and the central CLI routines module which acts as the main facade for business logic, BLE communication, API interaction, database usage, and machine learning inference.
- **Location:** `lib/`
- **Language:** Dart
- **Purpose:** To serve as the core structural basis for the application, initializing configurations, bringing together all domain modules through a central facade, and launching the Flutter UI shell.

# 2. Code Elements Section

## `lib/main.dart`

### Classes
- **`DashboardShell`**
  - **Description:** The main shell/container widget (StatefulWidget) for the application's dashboard. Handles navigation between different screens (Home, Nearby, Storage, Config) and displays a responsive layout.
  - **Methods:**
    - `State<DashboardShell> createState()`: Returns `_DashboardShellState`.
  - **Dependencies:** `CliRoutines`, `StorageScreen`, `ConfigScreen`, `HomeScreen`, `NearbyScreen`.

- **`_DashboardShellState`**
  - **Description:** State for `DashboardShell`. Manages the currently selected tab, listens to BLE connection state changes to update the global status bar, and builds the responsive UI structure.
  - **Methods:**
    - `void initState()`: Initializes the widget state and subscribes to the BLE connection state stream.
    - `void dispose()`: Disposes of the widget and cancels the BLE connection stream subscription.
    - `void _setStatus(String msg)`: Updates the status message in the state.
    - `Widget _buildCurrentScreen()`: Returns the correct screen widget based on the selected navigation index and platform (web or mobile).
    - `Widget _buildMainContent()`: Builds the main column containing the active screen and the bottom status bar.
    - `Widget build(BuildContext context)`: Builds the main `Scaffold`, utilizing a `NavigationRail` for desktop devices or a `BottomNavigationBar` for mobile devices.
  - **Dependencies:** `AppLocalizations`, `AppStyles`, `CliRoutines`.

### Functions
- **`void main() async`**
  - **Description:** Entry point of the TFM App. Initializes Flutter bindings, starts the background routines (`CliRoutines`), and runs the root `MaterialApp` containing theme and localization setup.
  - **Location:** `lib/main.dart`
  - **Dependencies:** `CliRoutines`, `AppStyles`, `AppLocalizations`, `DashboardShell`.

## `lib/cli_routines.dart`

### Classes
- **`CliRoutines`**
  - **Description:** Central facade that initializes all architectural modules. Ready to be consumed by a CLI interface or a UI.
  - **Methods:**
    - `Future<void> init() async`: Initializes the entire application state, including Database, Secure Storage, Network API, BLE Domain, and Inference Domain.
      - **Dependencies:** `FlutterBluePlus`, `Geolocator`, `DatabaseService`, `ApiClient`, `BleService`, `BleDataProcessor`, `InferenceBridge`.
    - `Future<void> pushTelemetry(String deviceId) async`: Pushes device telemetry from the local database to the cloud.
      - **Dependencies:** `cloudApi`, `db`.
    - `Future<Map<String, dynamic>> runLocalInference(String deviceId, {bool forceAllow = false, WeatherData? preloadedWeatherData, bool persistResults = true}) async`: Runs local machine learning inference, performing agronomic schedule checks beforehand.
      - **Dependencies:** `inferenceBridge`, `db`.
    - `void searchNearbyDevices()`: Starts a BLE scan for nearby devices.
      - **Dependencies:** `bleService`.
    - `Future<bool> connectToDevice(BluetoothDevice device, String sharedSecret) async`: Stops active scans and connects to a BLE device using a shared secret via `PicoHandshakeModule`.
      - **Dependencies:** `bleService`, `db`, `PicoHandshakeModule`.
    - `Future<Map<String, dynamic>?> readStationStatus() async`: Reads station status from the connected BLE device and updates the local DB.
      - **Dependencies:** `bleService`, `db`.
    - `Future<Map<String, dynamic>?> readStationConfig() async`: Reads station configuration from the connected BLE device and updates the local DB.
      - **Dependencies:** `bleService`, `db`.
    - `Future<Object?> requestStationData(String kind, {int? limit = 150}) async`: Requests station telemetry data of a specific kind and saves it into the local DB.
      - **Dependencies:** `bleService`, `db`.
    - `Future<void> sendHourlyForecast({DateTime? targetReferenceDate}) async`: Fetches weather forecast from Open-Meteo API, persists it, and sends it to the BLE station.
      - **Dependencies:** `bleService`, `db`, `OpenMeteoClient`.
    - `Future<String> fetchLatestPredictionFromConnectedDevice() async`: Requests and reads the latest prediction directly stored in the connected BLE device, saving it locally.
      - **Dependencies:** `bleService`, `db`.
    - `Future<Map<String, dynamic>> triggerStationInference() async`: Triggers LSTM inference based on station mode ('forward' vs 'local'), executes the Random Forest recommendation, and extracts minimums.
      - **Dependencies:** `bleService`, `db`, `inferenceBridge`, `OpenMeteoClient`.
    - `Future<Map<String, dynamic>> emulateCloudRecommendationInMemory(String deviceId) async`: Performs Cloud Emulation purely in RAM without mutating local Isar DB by evaluating LSTM (if needed) and RF models.
      - **Dependencies:** `cloudApi`, `db`, `OpenMeteoClient`, `SaviaLstmInferenceEngine`, `inferenceBridge`.
    - `void clearLocalDatabase()`: Clears all local database records.
      - **Dependencies:** `db`.
    - `void close()`: Cleans up resources.
      - **Dependencies:** `db`, `bleService`.
    - **Facade Methods:** `getAppSettings`, `saveAppSettings`, `getLocationSettings`, `saveLocationSettings`, `getActiveRfModel`, `getSavedRfModels`, `setActiveRfModel`, `deleteRfModel`, `saveRfModel`, `getAvailableRfModels`, `downloadRfModel`, `getRegisteredCloudDevices`, `updateCloudEndpoint`, `setCloudApiKey`, `syncCloudAndLocal`, `syncCloudTelemetry`, `testCloudConnection`, `testCloudPing`, `testWeatherConnection`, `getBleSecret`, `saveBleSecret`, `stopBleScan`, `disconnectBle`, `forceBleMock`, `clearBleStorage`, `saveDeviceBasic`, `getSavedDevices`, `pushStationLocationToCloud`, `syncBleTime`.
      - **Dependencies:** `db`, `cloudApi`, `FlutterSecureStorage`, `bleService`, `SyncService`, `http`.

# 3. Dependencies Section
## Internal Dependencies
- `tfm_app/core/database/app_database.dart`, `tfm_app/core/database/db_sync.dart`
- `tfm_app/core/models/device.dart`, `tfm_app/core/models/app_settings.dart`, `tfm_app/core/models/app_rf_model.dart`
- `tfm_app/core/network/cloud_api.dart`
- `tfm_app/features/ble/ble_service.dart`, `tfm_app/features/ble/ble_controller.dart`
- `tfm_app/features/ml_inference/inference_engine.dart`, `tfm_app/features/ml_inference/lstm_inference.dart`
- `tfm_app/features/weather/open_meteo_api.dart`, `tfm_app/features/weather/weather_data.dart`
- `tfm_app/features/location/location_settings.dart`
- `tfm_app/core/theme/app_styles.dart`
- `tfm_app/core/utils/l10n/app_localizations.dart`
- `tfm_app/screens/home_screen.dart`, `tfm_app/screens/nearby_screen.dart`, `tfm_app/screens/config_screen.dart`, `tfm_app/screens/storage_screen.dart`

## External Dependencies
- `package:flutter/material.dart`, `package:flutter/foundation.dart`
- `package:flutter_localizations/flutter_localizations.dart`
- `package:flutter_blue_plus/flutter_blue_plus.dart`
- `package:geolocator/geolocator.dart`
- `package:flutter_secure_storage/flutter_secure_storage.dart`
- `package:http/http.dart`
- `dart:async`, `dart:convert`

# 4. Relationships Section
- **`main.dart` -> `CliRoutines`**: The Flutter UI acts as a consumer of the `CliRoutines` facade. `main.dart` initializes `CliRoutines` and passes it down the widget tree through `DashboardShell` to all the main screens (Home, Nearby, Storage, Config), ensuring a single source of truth for business logic and state.
- **`CliRoutines` -> Core/Features modules**: `CliRoutines` sits at the center of the application architecture, integrating various independent domains:
  - **Database (`DatabaseService`)**: For local data persistence and settings management.
  - **Network (`ApiClient`)**: For telemetry sync, model downloads, and cloud interactions.
  - **BLE (`BleService`, `BleDataProcessor`)**: For station communication and data exchange.
  - **Inference (`InferenceBridge`, `SaviaLstmInferenceEngine`)**: For evaluating predictions locally and coordinating with weather APIs.
  - **Weather (`OpenMeteoClient`)**: For fetching hourly forecasts required by the inference models.
