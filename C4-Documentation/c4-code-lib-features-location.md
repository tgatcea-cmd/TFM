# C4 Code-Level Documentation: `lib/features/location`

## 1. Overview Section
- **Name**: Location Feature
- **Description**: Contains data structures for managing and passing geographic coordinates within the app.
- **Location**: [`lib/features/location`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/features/location)
- **Language**: Dart
- **Purpose**: Provides a standardized representation of GPS or manually entered location coordinates (latitude and longitude) along with a flag indicating the source of the data.

## 2. Code Elements Section
### Classes
- **[`LocationSettings`](file:///C:/Users/CrackoPattt88/Proyectos/tfm_app/lib/features/location/location_settings.dart#L1-L7)**:
  - **Description**: A simple data class holding location coordinates.
  - **Fields**:
    - `latitude` (`double`): The geographical latitude.
    - `longitude` (`double`): The geographical longitude.
    - `isGps` (`bool`): Flag indicating if the location was automatically obtained via GPS (`true`) or manually entered/selected (`false`).
  - **Constructor**: `LocationSettings(this.latitude, this.longitude, this.isGps)`

## 3. Dependencies Section
- **Internal dependencies**: None. It is a fundamental data structure.
- **External dependencies**: None.

## 4. Relationships Section
This class is consumed across the presentation and core layers where location coordinates are needed, such as in configuration screens, and potentially in routines that fetch location-specific weather data or synchronize the station's location with the cloud.
