# 1. Overview Section

- **Name**: Core Models
- **Description**: Contains data models and schemas used across the application. This includes database entities for local persistence via Isar, as well as transient models for mapping chart data and intermediate structures (weather, humidity, predictions).
- **Location**: `lib/core/models/`
- **Language**: Dart
- **Purpose**: Defines the central data structures representing application settings, random forest machine learning models, remote devices/stations, historical telemetry, predictions, and charting data.

# 2. Code Elements Section

### `lib/core/models/app_rf_model.dart`
- **Class `RfModel`**
  - **Description**: Database schema for storing downloaded Random Forest models in the local Isar database. It represents a machine learning model, used for local on-device inference, storing metadata and serialized model payload.
  - **Dependencies**: `package:isar_community/isar.dart`
  - **Attributes**:
    - `Id id = Isar.autoIncrement`
    - `String modelId` (@Index unique and replace)
    - `String cropName`
    - `String version`
    - `String description`
    - `String treeDataJson`
    - `bool isActive`
    - `DateTime updatedAt`

### `lib/core/models/app_settings.dart`
- **Class `AppSettings`**
  - **Description**: Singleton configuration class for the application stored in the Isar database. Holds all persistent global configurations (UI preferences, server details, agronomic parameters, location data).
  - **Dependencies**: `package:isar_community/isar.dart`
  - **Attributes**:
    - `Id id = 1`
    - `bool isFirstTime`
    - `String themeMode`
    - `String tfmServerScheme`
    - `String tfmServerUrl`
    - `int tfmServerPort`
    - `String tfmServerApiKey`
    - `int syncScheduleHours`
    - `String selectedTfliteModel`
    - `bool invertModelOutput`
    - `bool permitOpenMeteoFill`
    - `bool alwaysForceInference`
    - `int agronomicDayStart`
    - `int agronomicDayEnd`
    - `double minHumidity`
    - `double manualLat`, `double manualLon`, `double gpsLat`, `double gpsLon`
    - `bool isGpsEnabled`

### `lib/core/models/chart_data_point.dart`
- **Class `ChartDataPoint`**
  - **Description**: Represents a single data point in a time-series chart used across the application.
  - **Dependencies**: None.
  - **Constructors**:
    - `ChartDataPoint({required this.timestamp, required this.value})`
  - **Attributes**:
    - `final DateTime timestamp`
    - `final double value`

### `lib/core/models/device.dart`
- **Class `Device`**
  - **Description**: Represents a remote or local agricultural device (e.g., weather station or soil sensor node). Stored in the local Isar database. Contains device metadata, sync status, and embedded historical sensor readings and ML predictions.
  - **Dependencies**: `package:isar_community/isar.dart`
  - **Methods & Getters**:
    - `bool get enoughForInference`: Determines if there is enough recent historical data to perform a new inference. Returns `true` if outside typical daylight hours (10:00 to 19:00) and if there is at least one sensor reading at 30cm depth within the last 48 hours.
  - **Attributes**:
    - `Id id = Isar.autoIncrement`
    - `String deviceIdentifier` (@Index unique)
    - `String name`
    - `double? latitude`, `double? longitude`
    - `String handshakePassword`
    - `bool localInferenceCapabilities`, `bool loraEnabled`, `bool isSynced`
    - `DateTime? latestSynchronizedTime`, `DateTime? latestInferenceTriggerDate`, `DateTime updatedAt`
    - `List<HistoricValue> historicValues`
    - `List<Prediction> previousPredictions`, `List<Prediction> newPredictions`

- **Class `HistoricValue`** (@embedded)
  - **Description**: Represents a single historical sensor reading embedded within a `Device`.
  - **Attributes**: `int? tsMs`, `int? port`, `String? kind`, `double? value`, `double? depthCm`

- **Class `Prediction`** (@embedded)
  - **Description**: Represents a machine learning prediction embedded within a `Device`.
  - **Attributes**: `int? tsMs`, `String? model`, `String? kind`, `int? port`, `double? value`, `double? depthCm`, `double? confidence`

- **Class `WeatherRecord`**
  - **Description**: A transient model for holding weather data records.
  - **Constructors**: `WeatherRecord({required this.timestamp, required this.temp, required this.hum, required this.radiation, required this.prec})`
  - **Attributes**: `final int timestamp`, `final double temp`, `final double hum`, `final double radiation`, `final double prec`

- **Class `SoilHumidityRecord`**
  - **Description**: A transient model for holding soil humidity sensor records.
  - **Constructors**: `SoilHumidityRecord({required this.timestamp, required this.value})`
  - **Attributes**: `final int timestamp`, `final double value`

- **Class `PredictionRecord`**
  - **Description**: A transient model holding structured prediction outputs and agronomic recommendations.
  - **Constructors**: `PredictionRecord({required this.timestamp, required this.predictedHumidity, required this.recommendation})`
  - **Attributes**: `final int timestamp`, `final double predictedHumidity`, `final String recommendation`

# 3. Dependencies Section

- **Internal Dependencies**: 
  - The models in this module generally do not depend on other internal application features. They serve as base entities. 
  - `Device` embeds the `HistoricValue` and `Prediction` classes within the same file context.
- **External Dependencies**:
  - `package:isar_community/isar.dart`: Provides database annotations (`@collection`, `@embedded`, `Id`, `@Index`, `@ignore`) and generated code mechanics (e.g., `part ...g.dart`) for schema reflection and local persistence.
  - Dart Core Libraries (`DateTime`, `List`, `String`, etc.)

# 4. Relationships Section

- **Composition**: 
  - A `Device` *contains* multiple `HistoricValue` objects as an embedded list (`historicValues`).
  - A `Device` *contains* multiple `Prediction` objects as embedded lists (`previousPredictions` and `newPredictions`).
- **Isar Database Entities**: `AppSettings`, `Device`, and `RfModel` represent distinct top-level Isar collections managed by the local database engine.
- **Data Transfer Objects**: `ChartDataPoint`, `WeatherRecord`, `SoilHumidityRecord`, and `PredictionRecord` are transient, non-persisted objects utilized to transfer and format structured data for UI rendering or intermediate logic processing outside the Isar persistence lifecycle.
