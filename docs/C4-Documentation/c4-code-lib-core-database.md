# 1. Overview Section

- **Name:** Core Database Module
- **Description:** Service module responsible for managing local database operations and synchronizing local database records with the cloud API.
- **Location:** `lib/core/database/`
- **Language:** Dart
- **Purpose:** Provides an abstraction over local database interactions, including web support fallbacks via in-memory storage. It also handles syncing locally modified records (telemetry, predictions, metadata) to the cloud and pulling remote data updates to keep the local storage consistent.

# 2. Code Elements Section

## Classes/Modules

### `DatabaseService`
- **Description:** Service class responsible for managing local database operations using Isar. It provides an abstraction over database interactions, including web support fallbacks.
- **Location:** `lib/core/database/app_database.dart`
- **Dependencies:** `Isar`, `path_provider`, `Device`, `AppSettings`, `LocationSettings`, `WeatherData`, `RfModel`.
- **Methods:**
  - `Future<void> init()`: Initializes the local database (Isar on native, in-memory on web).
  - `Future<void> saveDevice(Device device)`: Saves or updates a full `Device` entity.
  - `void saveDeviceBasic(String id, String name, {double? lat, double? lon, bool isFromCloud = false})`: Saves or updates basic device info (name, location).
  - `AppSettings getAppSettings()`: Retrieves current application settings.
  - `void saveAppSettings({...})`: Updates specific fields in the application settings.
  - `LocationSettings getLocationSettings()`: Retrieves user-configured manual location settings.
  - `void saveLocationSettings(double lat, double lon, bool isGps)`: Saves manual location settings.
  - `LocationSettings getGpsConfig()`: Retrieves the device's actual GPS location.
  - `void saveGpsConfig(double lat, double lon)`: Saves actual GPS location.
  - `double getMinHumidity()`: Retrieves the minimum humidity threshold.
  - `void saveMinHumidity(double value)`: Saves the minimum humidity threshold.
  - `List<Device> getSavedDevices()`: Retrieves all saved devices.
  - `void deleteDevice(String id)`: Deletes a device by its ID.
  - `bool upsertTelemetry(String deviceId, List<HistoricValue> newValues, {bool isFromCloud = false})`: Upserts telemetry records based on a composite key.
  - `void appendTelemetry(String deviceId, List<HistoricValue> newValues)`: Appends telemetry data to a device.
  - `List<HistoricValue> getDeviceTelemetry(String deviceId, {String? kind, double? depthCm, int? sinceMs})`: Retrieves filtered telemetry data.
  - `DateTime getReferenceTime(String deviceId, {bool isConnected = false})`: Calculates a valid reference timestamp of local device info.
  - `void sanitizeCorruptedFutureData(String deviceId)`: Prunes any corrupted future telemetry entries.
  - `void markDeviceSynced(String deviceId)`: Marks a device as synchronized with the cloud.
  - `void updateDeviceStatus(String deviceId, Map<String, dynamic> status, {bool isFromCloud = false})`: Updates a device's runtime status (e.g., location).
  - `void updateDeviceConfig(String deviceId, Map<String, dynamic> config)`: Updates a device's configuration capabilities.
  - `void updatePredictions(String deviceId, List<Prediction> predictions, {bool isFromCloud = false})`: Updates ML model predictions.
  - `void saveWeatherForecast(String deviceId, WeatherData weatherData)`: Saves external weather forecast data as telemetry.
  - `void clearAllData()`: Clears all stored device data.
  - `void close()`: Closes the database connection.
  - `List<RfModel> getSavedRfModels()`: Retrieves all saved Random Forest models.
  - `RfModel? getActiveRfModel()`: Retrieves the currently active RF model.
  - `void saveRfModel(Map<String, dynamic> metadata, String treeDataJson)`: Saves a new RF model.
  - `void setActiveRfModel(String modelId)`: Sets an RF model as active.
  - `void deleteRfModel(String modelId)`: Deletes an RF model by ID.
  - `Device? findDevice(String? deviceId)`: Finds a specific device by ID.
  - `void updateDeviceSync(Device device)`: Synchronously updates a device record.
  - `Future<List<Device>> getDirtyDevices()`: Retrieves devices with local changes not yet synchronized.
  - `Future<void> saveDevices(List<Device> devices)`: Bulk saves multiple devices.

### `SyncService`
- **Description:** Service responsible for synchronizing local database records with the cloud API. Handles pushing dirty local records and pulling new remote telemetry and predictions.
- **Location:** `lib/core/database/db_sync.dart`
- **Dependencies:** `DatabaseService`, `ApiClient`, `http`, `Device`.
- **Methods:**
  - `SyncService({required this.db, required this.api})`: Constructor.
  - `Future<void> syncDirtyDevices()`: Pushes all locally modified devices (telemetry, predictions, metadata) to the server.
  - `Future<void> pushStationLocationToCloud(String deviceId, double lat, double lon)`: Updates the station's location on the cloud server.
  - `Future<void> pullTelemetry(String deviceId, int sinceMs)`: Pulls new telemetry data from the server and merges it locally.
  - `Future<void> pullPredictions(String deviceId, int sinceMs)`: Pulls new prediction records from the server and merges them locally.
  - `Future<void> discoverAndSyncCloudDevices()`: Discovers registered stations from the cloud API and repopulates the local Isar database.

# 3. Dependencies Section

## Internal Dependencies
- `tfm_app/core/models/device.dart`: Device and sub-models (`HistoricValue`, `Prediction`).
- `tfm_app/core/models/app_settings.dart`: Application settings model.
- `tfm_app/core/models/app_rf_model.dart`: Random Forest ML model entity.
- `tfm_app/features/location/location_settings.dart`: Location settings wrapper.
- `tfm_app/features/weather/weather_data.dart`: Weather forecast wrapper.
- `tfm_app/core/network/cloud_api.dart`: API client for remote cloud operations.

## External Dependencies
- `isar_community/isar.dart`: NoSQL database engine used for local persistence.
- `path_provider/path_provider.dart`: Fetches the application documents directory on native platforms to store the DB file.
- `flutter/foundation.dart`: Provides `kIsWeb` to branch logic between native (Isar) and web (in-memory).
- `http/http.dart`: Used within `SyncService` for direct HTTP requests.

# 4. Relationships Section
- **`SyncService` -> `DatabaseService`:** `SyncService` uses `DatabaseService` to query dirty devices, update metadata upon sync, upsert pulled telemetry, and mark devices as successfully synced.
- **`SyncService` -> `ApiClient`:** `SyncService` delegates to `ApiClient` to push and pull domain-specific sync endpoints, as well as fetch registered cloud devices.
- **`DatabaseService` -> `Isar`:** Directly manages the local NoSQL storage instance and executes transactions to persist objects locally.
- **Entities:** Both services closely interact with and manipulate shared entities like `Device`, `HistoricValue`, `Prediction`, and `AppSettings`.
