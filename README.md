# Predictive Irrigation System (TFM)

## Overview
A cross-platform Flutter application and IoT station designed to intelligently manage irrigation decisions. It utilizes Open-Meteo weather forecasts and an Edge AI inference engine combining LSTM (Long Short-Term Memory) and Random Forest models to provide offline edge irrigation verdicts.

## Warnings & Known Issues
- **Undeveloped Chart Feature:** The charting module (`lib/features/charts/`) is currently undeveloped and is not actively integrated or utilized in the main application flow.
- **Incomplete Globalization:** The localization and globalization language tool (`lib/core/utils/l10n/`) is incomplete and lacks full translation mapping.

## Architecture
This repository follows the C4 Architecture model. Complete technical and architectural documentation can be found in `docs/C4-Documentation/`.

- `c4-context.md`: High-level system context and user personas.
- `c4-container.md`: Deployment containers and software architecture.
- `c4-component-*.md`: Logical component definitions.
- `c4-code-*.md`: Code-level references mapping to the `lib/` directory.

## Repository Structure

```text
TFM_APP/
|-- docs/
|   |-- audits/               (Performance and code audits)
|   |-- C4-Documentation/     (C4 architectural specs)
|-- lib/
|   |-- core/                 (Foundational logic)
|   |   |-- database/         (Realm DB sync and persistence)
|   |   |-- models/           (Data models)
|   |   |-- network/          (Cloud APIs and Open-Meteo)
|   |   |-- theme/            (Styling definitions)
|   |   |-- utils/            (Date formatting, l10n)
|   |-- features/             (Domain features)
|   |   |-- ble/              (Bluetooth comms, HMAC auth, JSON serialization)
|   |   |-- charts/           [WARNING: Undeveloped & Unused]
|   |   |-- location/         (GPS and location settings)
|   |   |-- ml_inference/     (LSTM and Random Forest engines)
|   |   |-- weather/          (Forecast data handlers)
|   |-- screens/              (UI and Views)
|   |-- cli_routines.dart     (Command line interface routines)
|   |-- main.dart             (Entry point)
|-- Testing_resources/        (Mock scripts and Dart test workflows)
|   |-- pico2W.py
|   |-- pico_mock.py
|   |-- test_rf_csv_generator.dart
|   |-- test_rf_script.dart
|   |-- test_workflow3_fallback.dart
|   |-- test_workflow4_benchmark.dart
|   |-- test_workflow5_comparison.dart
```

## Getting Started

### Prerequisites
- Flutter SDK (Dart 3.x / Flutter 3.x)
- Visual Studio (Windows build), Xcode (macOS/iOS), or Android Studio (Android)
- Linux target only: Requires `libtensorflowlite_c-linux.so` binary properly linked.

### Setup and Build
1. Clone the repository and fetch package dependencies:
   ```bash
   git clone <repository-url>
   cd TFM_APP
   flutter pub get
   ```

2. Run code generation for Realm schemas and auto-generated classes:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

3. Compile and run the application:
   ```bash
   flutter run
   ```
   To specify a development target (e.g., Windows):
   ```bash
   flutter run -d windows
   ```

## Hardware Mocking & ML Workflow Testing
To test the application without the physical IoT node, run the provided Python scripts in `Testing_resources/` (e.g., `pico_mock.py`). These emulate the BLE transport layer, handle HMAC-SHA256 challenge-responses, and provide simulated JSON telemetry.

Additionally, the `Testing_resources/` folder contains several Dart standalone scripts (e.g., `test_workflow3_fallback.dart`, `test_rf_script.dart`) recovered for testing the ML models, offline fallbacks, and running inference benchmarks isolated from the UI framework.
