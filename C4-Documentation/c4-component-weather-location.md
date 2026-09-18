# C4 Component Architecture: Weather & Location Services

## 1. Overview Section
The Weather and Location services form the environmental context engine of the smart irrigation decision support system. Located in `lib/features/weather` and `lib/features/location`, these modules are responsible for providing standardized geographic coordinate structures and leveraging them to fetch, parse, and serve meteorological data (both forecasts and historical metrics).

## 2. Purpose Section
The primary purpose of this component is to acquire accurate, location-specific weather data essential for the application's machine learning and deep learning inference engines. It acts as a gateway to external weather APIs (Open-Meteo), converting raw JSON meteorological data into strongly-typed time-series arrays that align with the local solar cycle. The Location module supports this by providing a unified data transfer object for geographic coordinates.

## 3. Software Features Section
- **Location-Aware Querying**: Utilizes WGS-84 geographic coordinates (`latitude`, `longitude`) to query location-specific weather.
- **Meteorological Data Ingestion**: Fetches hourly metrics including ambient temperature (2m), relative humidity (2m), shortwave solar radiation, and precipitation.
- **Flexible Temporal Windows**: Supports live forecasts (rolling 48h past and 48h future) and reference-anchored queries for historical replay or back-testing.
- **Timezone Synchronization**: Requests automated solar timezone alignment (`timezone=auto`) to harmonize UTC weather arrays with station-local solar cycles.
- **Data Normalization**: Transforms flat JSON parallel arrays into strongly-typed Dart DTOs (`WeatherData`) optimized for vector math used in ML inference.
- **Location Tracking**: Provides a unified `LocationSettings` DTO to track coordinates and their acquisition source (GPS vs. manual).

## 4. Code Elements Section

### 4.1 Weather Module (`lib/features/weather`)
- **`OpenMeteoClient`**: Service class encapsulating HTTP communication, URI parameter composition, request timeouts (10s), and response decoding for the Open-Meteo REST API.
- **`WeatherData`**: Domain Value Object / DTO encapsulating parallel time-series arrays for hourly weather metrics (time, temperature, humidity, radiation, precipitation). Includes a `fromJson` factory that handles date parsing, local time conversion, and safe numeric type coercion.

### 4.2 Location Module (`lib/features/location`)
- **`LocationSettings`**: A simple immutable data class holding `latitude` (double), `longitude` (double), and `isGps` (bool) flag. Serves as a fundamental data structure passed to the weather client and other core layers.

## 5. Interfaces Section
- **Open-Meteo API Gateway**: Communicates over HTTPS to `api.open-meteo.com/v1/forecast`, requesting JSON payloads containing hourly meteorological data based on provided latitude, longitude, and temporal parameters.
- **Inbound Data Delivery**: Exposes parsed `WeatherData` objects directly to downstream consumers, primarily the machine learning inference services (`InferenceEngine`, `LstmInferenceEngine`), the persistence layer (`DatabaseService`), and CLI orchestration routines (`CliRoutines`).

## 6. Dependencies Section
- **External Dependencies**:
  - `package:http/http.dart`: Used by `OpenMeteoClient` for standard cross-platform asynchronous HTTP GET requests.
- **Core Dart Libraries**:
  - `dart:async`: For Future primitives and `.timeout()` mechanisms.
  - `dart:convert`: For `jsonDecode()`.
- **Inter-Component Dependencies**:
  - The Weather module has zero coupling to presentation (UI) or local persistence (Isar). It operates solely on coordinate primitives (which can be derived from `LocationSettings`) and returns pure Dart objects.

## 7. Component Diagram

```mermaid
classDiagram
    direction TB

    package "Location Feature" {
        class LocationSettings {
            +double latitude
            +double longitude
            +bool isGps
            +LocationSettings(latitude, longitude, isGps)
        }
    }

    package "Weather Feature" {
        class OpenMeteoClient {
            -_baseUrl: String
            +double latitude
            +double longitude
            +OpenMeteoClient(latitude, longitude)
            +fetchForecast(referenceDate) Future~WeatherData~
        }

        class WeatherData {
            +List~DateTime~ time
            +List~double~ temperature2m
            +List~double~ relativeHumidity2m
            +List~double~ shortwaveRadiation
            +List~double~ precipitation
            +fromJson(json) WeatherData
        }
    }

    package "External Services" {
        class OpenMeteoAPI {
            <<REST API>>
            /v1/forecast
        }
    }

    package "Consumers" {
        class InferenceEngine
        class LstmInferenceEngine
        class DatabaseService
        class CliRoutines
    }

    LocationSettings ..> OpenMeteoClient : Provides coordinates
    OpenMeteoClient --> OpenMeteoAPI : HTTP GET
    OpenMeteoClient ..> WeatherData : Parses JSON into
    InferenceEngine ..> OpenMeteoClient : Fetches forecast
    LstmInferenceEngine ..> OpenMeteoClient : Fetches forecast
    CliRoutines ..> OpenMeteoClient : Fetches forecast
    DatabaseService ..> WeatherData : Caches data
```
