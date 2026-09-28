# C4 Code-Level Documentation: `lib/features/ml_inference`

## 1. Overview Section
- **Name**: ML Inference Feature
- **Description**: Contains logic for executing offline predictive models such as Random Forest and LSTM for soil moisture forecasting and irrigation recommendation.
- **Location**: `lib/features/ml_inference`
- **Language**: Dart
- **Purpose**: Provides offline execution of ML models, evaluating recent historical sensor data and weather forecasts to generate irrigation recommendations and predict soil moisture curves.

## 2. Code Elements Section

### Classes

#### `HistoricalSolarModel`
- **Description**: An offline fallback model for estimating the 48-hour shortwave solar radiation sum when live weather data is unavailable.
- **Location**: `lib/features/ml_inference/inference_engine.dart`
- **Dependencies**: None.
- **Methods**:
  - `static double estimateRadSum({required double lat, required DateTime date})`: Estimates solar radiation sum based on geographic location and time of year.

#### `InferenceBridge`
- **Description**: Bridges the database and ML inference models to orchestrate data fetching, feature preparation, and execution of LSTM and Random Forest models.
- **Location**: `lib/features/ml_inference/inference_engine.dart`
- **Dependencies**: `DatabaseService`, `Device`, `SaviaLstmInferenceEngine`, `OpenMeteoClient`, `WeatherData`.
- **Methods**:
  - `Future<Map<String, dynamic>> runLocalLstmInference([String? deviceId]) async`: Orchestrates the execution of the 24-hour LSTM inference procedure.
  - `Future<void> _loadModelFromSettings() async`: Loads the ML model settings.
  - `Future<Map<String, dynamic>> runIrrigationRecommendation({...}) async`: Executes the irrigation recommendation procedure.
  - `Map<String, dynamic> evaluateRecommendation({...})`: Evaluates model output to provide a structured recommendation.

#### `SaviaLstmErrorCode`
- **Description**: Defines error and diagnostic codes used by the LSTM inference engine to align with Savia C firmware specifications.
- **Location**: `lib/features/ml_inference/lstm_inference.dart`

#### `SaviaLstmScaler`
- **Description**: Provides standard scaling utilities (mean and std dev) for LSTM input features based on the training dataset.
- **Location**: `lib/features/ml_inference/lstm_inference.dart`
- **Methods**:
  - `static double scaleHs30(double val)`, `unscaleHs30`, `scaleTa`, `unscaleTa`, `scaleHs10`, `unscaleHs10`, `scaleRadiation`: Standardizes or reverts normalization of features.

#### `LstmInputSample`
- **Description**: Encapsulates air temperature and soil moisture readings required for a single time step in the LSTM sequence.
- **Location**: `lib/features/ml_inference/lstm_inference.dart`
- **Methods**:
  - `List<double> toScaledTensorRow()`: Scales inputs into the expected tensor row format.

#### `SaviaLstmInferenceEngine`
- **Description**: Implements the LSTM Soil Moisture Inference Engine off-device logic, executing the 24-step Unrolled LSTM Forecast Procedure.
- **Location**: `lib/features/ml_inference/lstm_inference.dart`
- **Dependencies**: `DatabaseService`, `Device`, `OpenMeteoClient`.
- **Methods**:
  - `Future<Map<String, dynamic>> runDailyInference(String deviceId, {DateTime? targetRefDate}) async`: Runs the daily inference logic for the device.
  - `Future<Map<String, dynamic>> _gatherInputs(Device device, DateTime refDate) async`: Gathers and fills historical samples.
  - `List<double> _executeLstmModel(List<List<double>> pastTensor, List<double> futureTensor)`: Executes the forecasting mathematical procedure.
  - `void _persistPredictions(Device device, DateTime refDate, List<double> predictions)`: Stores the prediction curve in the database.

#### `Random Forest Decision Trees`
- **Description**: Includes hardcoded decision tree thresholds and logic generated from ML pipelines.
- **Location**: `lib/features/ml_inference/random_forest.dart`, `lib/features/ml_inference/dynamic_random_forest.dart`
- **Methods**: Implement combinations of mathematical array functions such as `addVectors` and `mulVectorNumber`.

## 3. Dependencies Section
- **Internal dependencies**:
  - `DatabaseService` for historical values.
  - `Device` data structures for parameters.
  - `OpenMeteoClient` for weather forecast and historical extraction.
- **External dependencies**: None directly outside the scope of internal libraries except `dart:math`.

## 4. Relationships Section
`InferenceBridge` and `SaviaLstmInferenceEngine` act as core computational handlers that are invoked by the presentation layer (UI) or background task schedulers. They depend heavily on `DatabaseService` to gather historical values and update predictions. They complement standard data paths with intelligence features.
