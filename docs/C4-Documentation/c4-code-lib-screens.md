# C4 Code-Level Documentation: `lib/screens`

## 1. Overview Section
- **Name**: Application Screens
- **Description**: Contains the primary presentation layer components (views) of the Savia mobile application.
- **Location**: `lib/screens`
- **Language**: Dart
- **Purpose**: Implements the main UI views for the app, handling state management, user interactions, and integration with the underlying core logic and hardware services.

## 2. Code Elements Section

### Classes

#### `ConfigScreen`
- **Description**: A stateful widget that allows users to adjust app-wide settings including location, APIs, agronomic preferences, and ML model management.
- **Location**: `lib/screens/config_screen.dart`
- **Dependencies**: `DatabaseService`, UI utility classes, Location services.
- **Methods**:
  - `_handleAutoGpsLocation()`: Fetches live GPS coordinates and updates config.
  - `_checkOpenMeteo()`, `_checkCloudPing()`: Diagnostics for external APIs.
  - `_saveConfiguration()`: Persists user-defined settings into `AppDatabase`.
  - `_showMlModelManager()`: Opens `MlModelManagerSheet` to manage dynamic ML models.

#### `MlModelManagerSheet`
- **Description**: A bottom sheet for downloading, activating, and deleting OTA ML models from a cloud repository.
- **Location**: `lib/screens/config_screen.dart`

#### `HomeScreen`
- **Description**: The primary dashboard of the app showing live BLE telemetry, a debug console, and the latest AI irrigation recommendations.
- **Location**: `lib/screens/home_screen.dart`
- **Dependencies**: `BleService`, `DatabaseService`, `InferenceCard`.
- **Methods**:
  - `_fetchDeviceStatus()`: Polls the connected BLE node for status.
  - `_handleSyncTime()`: Injects the mobile device's time into the IoT node RTC.
  - `Widget _buildDebugPanel(...)`: Renders raw BLE JSON messages.
  - `Widget _buildPredictionCard(...)`: Renders the `InferenceCard` with ML outputs.

#### `NearbyScreen`
- **Description**: Manages BLE discovery, scanning for Savia nodes, handling permissions, and managing the security handshake for connecting to devices.
- **Location**: `lib/screens/nearby_screen.dart`
- **Dependencies**: `BleService`, `flutter_blue_plus`, Location permissions.
- **Methods**:
  - `_checkLocationStatus()`: Enforces Bluetooth and Location permissions.
  - `_searchNearby()`: Triggers the BLE scanner.
  - `_promptConnection(ScanResult result)`: Prompts the user for a password, performs cryptographic handshake, and connects via `BleService`.

#### `StorageScreen`
- **Description**: Manages historical data, unified offline storage, and chart visualizations. Also triggers the `InferenceBridge` and Cloud Sync manually.
- **Location**: `lib/screens/storage_screen.dart`
- **Dependencies**: `DatabaseService`, `InferenceBridge`, `CloudSyncEngine`, Chart Widgets.
- **Methods**:
  - `_loadUnifiedData()`: Aggregates historical payloads from the database.
  - `_handleSync()`: Triggers upload of stored metrics to the Savia Cloud endpoint.
  - `_handleLocalInference(UnifiedStation station)`: Manually triggers the LSTM model run via `InferenceBridge`.
  - `_handleCloudEmulation(UnifiedStation station)`: Requests inference from a cloud endpoint.

## 3. Dependencies Section
- **Internal dependencies**:
  - `BleService` is used by `HomeScreen` and `NearbyScreen`.
  - `DatabaseService` is used by `ConfigScreen`, `HomeScreen`, and `StorageScreen`.
  - `InferenceBridge` is used by `StorageScreen`.
  - Widgets from `lib/screens/widgets/` and `lib/features/charts/` are embedded within these views.
- **External dependencies**:
  - Flutter UI framework.

## 4. Relationships Section
The screens orchestrate the interaction between the user and the system's core capabilities. They depend on the business logic layers (like `BleService` and `InferenceBridge`) to fetch state, execute procedures, and display the resulting data models to the user.
