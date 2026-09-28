# C4 Code-Level Documentation: `lib/features/weather`

## 1. Overview Section
- **Name**: Weather Feature
- **Description**: Handles the retrieval and parsing of weather forecast and historical data from the Open-Meteo API.
- **Location**: `lib/features/weather`
- **Language**: Dart
- **Purpose**: Provides a robust client and data structures to interface with external weather services, fetching essential environmental metrics like temperature, humidity, radiation, and precipitation.

## 2. Code Elements Section

### Classes

#### `OpenMeteoClient`
- **Description**: A client for fetching weather forecast and historical data from the Open-Meteo API. Provides methods to retrieve hourly weather data for a specific geographical location.
- **Location**: `lib/features/weather/open_meteo_api.dart`
- **Dependencies**: `http` (external), `WeatherData` (internal)
- **Methods**:
  - `OpenMeteoClient({required this.latitude, required this.longitude})`: Creates a new instance specifying geographic coordinates.
  - `Future<WeatherData> fetchForecast({DateTime? referenceDate})`: Fetches weather forecast or historical data depending on the `referenceDate`. Automatically switches to the archive API if the date is older than 90 days. Returns a `WeatherData` object.

#### `WeatherData`
- **Description**: Represents a collection of hourly weather data. Contains arrays of timestamps and corresponding environmental metrics.
- **Location**: `lib/features/weather/weather_data.dart`
- **Dependencies**: None.
- **Methods**:
  - `WeatherData(...)`: Creates a new `WeatherData` instance with the specified environmental data series.
  - `factory WeatherData.fromJson(Map<String, dynamic> json)`: Creates a `WeatherData` instance by parsing a JSON map from the API response.

## 3. Dependencies Section
- **Internal dependencies**:
  - `WeatherData` is used by `OpenMeteoClient`.
- **External dependencies**:
  - `package:http/http.dart`: Used for making HTTP requests to the Open-Meteo API.
  - **Open-Meteo API**: The remote service used to retrieve meteorological data.

## 4. Relationships Section
The `OpenMeteoClient` is utilized by the ML inference and core data processing modules to supplement local sensor data with meteorological context. `WeatherData` objects are passed to these downstream consumers to form complete datasets for prediction models.
