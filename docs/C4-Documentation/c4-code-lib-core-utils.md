# 1. Overview Section
- **Name**: Core Utilities (`lib/core/utils`)
- **Description**: Foundational utility module providing application-wide stateless helper functions and type extensions, excluding localization files.
- **Location**: `lib/core/utils`
- **Language**: Dart
- **Purpose**: Encapsulates common routines like date-time formatting and temporal manipulations into pure functions. It serves the domain, data, and presentation layers without introducing external package dependencies or UI framework coupling.

# 2. Code Elements Section

## Class: `AppDateFormatter`
- **Description**: Utility class for formatting dates across the application.
- **Location**: `lib/core/utils/date_formatter.dart`
- **Dependencies**: `dart:core`

### Methods
- **Signature**: `static String format(dynamic value, {bool showSeconds = true})`
  - **Description**: Formats a date value into a uniform app-wide string representation. Accepts a `DateTime`, an integer timestamp in milliseconds, or an ISO 8601 string. Returns `YYYY-MM-DD HH:mm:ss` by default, or `YYYY-MM-DD HH:mm` if `showSeconds` is false. Returns 'N/A' if the value is null, or the string representation of the value if it cannot be parsed.
  - **Location**: `lib/core/utils/date_formatter.dart`
  - **Dependencies**: `dart:core` (`DateTime`, `String`, `int`)

## Extension: `DateTimeFloor` on `DateTime`
- **Description**: Extension on standard Dart `DateTime` providing utility methods for manipulating date components.
- **Location**: `lib/core/utils/date_formatter.dart`
- **Dependencies**: `dart:core`

### Methods
- **Signature**: `DateTime floorToHour()`
  - **Description**: Snaps the `DateTime` instance down to the floor of the current hour (e.g., `14:45:30` becomes `14:00:00.000`). Returns a new `DateTime` instance.
  - **Location**: `lib/core/utils/date_formatter.dart`
  - **Dependencies**: `dart:core` (`DateTime`)

# 3. Dependencies Section
- **Internal Dependencies**: None. This module is completely stateless and self-contained; it does not depend on any domain, data, or presentation layer components.
- **External Dependencies**: 
  - `dart:core`: Relies exclusively on Dart SDK types (`DateTime`, `String`, `int`, `bool`). It purposefully avoids third-party formatting packages (e.g., `intl`) and UI framework libraries (e.g., `package:flutter`).

# 4. Relationships Section
- **Incoming Dependencies (Callers)**:
  - `HomeScreen` (`lib/screens/home_screen.dart`): Calls `AppDateFormatter.format()` to render telemetry timestamps and station synchronization statuses.
  - `ConfigScreen` (`lib/screens/config_screen.dart`): Calls `AppDateFormatter.format()` to format the device's current synchronization time.
  - `InferenceCard` (`lib/screens/widgets/inference_card.dart`): Calls `AppDateFormatter.format()` to display machine learning execution record times.
- **Outgoing Dependencies**: None beyond `dart:core`. Data flow is strictly one-way from callers into the utility functions, which return formatted data natively.
