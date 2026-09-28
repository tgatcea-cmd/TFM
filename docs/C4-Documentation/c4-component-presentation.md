# C4 Component Architecture: Presentation Layer

This document provides a C4 Component-level architecture specification for the Presentation Layer of the application, synthesizing the code-level elements from the root shell (`lib`), application screens (`lib/screens`), and reusable presentation widgets (`lib/screens/widgets`).

---

## 1. **Overview Section**

The Presentation Layer is the outer interactive shell of the application, built with Flutter. It orchestrates user workflows, hardware bindings, cross-platform UI rendering, and delegates complex business logic to a central orchestration facade. The component is responsible for navigating between specialized operational views, providing responsive scaffolding for different form factors (mobile vs. desktop), rendering real-time telemetry, and visualizing agronomic machine learning decisions.

---

## 2. **Purpose Section**

The primary purpose of the Presentation Component is to bridge the gap between the field agronomist/user and the underlying agronomic hardware and cloud services. Its objectives are:
- Provide an intuitive, responsive, and localized interface for interacting with IoT stations over Bluetooth Low Energy (BLE).
- Orchestrate data synchronization between local SQLite databases and cloud backends.
- Evaluate and visually present actionable machine learning recommendations (e.g., Irrigation Needed vs. Avoidable) while adhering to strict agronomic time-window constraints.
- Shield the user interface from the underlying volatility of hardware streams and database transactions through a unified orchestration facade (`CliRoutines`).

---

## 3. **Software Features Section**

The Presentation Component exposes the following critical software features:

- **Adaptive Responsive Scaffolding:** Seamlessly adapts the navigation interface between a `BottomNavigationBar` on mobile and a `NavigationRail` on desktop/tablet views. Gracefully degrades on Web platforms by disabling unsupported BLE views.
- **BLE Discovery & Authentication:** Scans for nearby agronomic IoT stations, negotiates challenge-response authentication, manages platform-specific location permissions, and caches credentials securely.
- **Live Telemetry & Diagnostics:** Presents a live console terminal for raw JSON packets, supports clipboard exports, monitors instantaneous BLE stream payloads, and provides a real-time clock (RTC) synchronization readout tracking station drift.
- **Unified Station Management:** Merges offline SQLite database entities with remote REST API stations into a unified dashboard, featuring interactive OpenStreetMap (`flutter_map`) visualizations.
- **Dual-Mode ML Orchestration & Display:** Triggers and visualizes inference executed locally on-device (via Edge ML on Pico or Host ML on phone CPU) as well as emulated cloud recommendations, rendering semantic severity through specialized widgets (`InferenceCard`).
- **Configuration & Agronomic Scheduling:** Provides a circular modulo-24 settings engine for managing valid execution windows (Yellow Zone) and handles the dynamic downloading and selection of Random Forest ML models.

---

## 4. **Code Elements Section**

The component is composed of the following primary code structures:

### 4.1 Application Shell & Facade (`lib`)
- **`DashboardShell` (`main.dart`):** The top-level `StatefulWidget` managing the navigation state and adaptive viewport layouts. It houses the persistent telemetry status footer.
- **`CliRoutines` (`cli_routines.dart`):** The master orchestration Facade. It initializes services (DB, BLE, Cloud API, ML Engine), routes complex workflows (like `triggerStationInference` or `sendHourlyForecast`), and exposes a clean asynchronous API to the UI.

### 4.2 Top-Level Screens (`lib/screens`)
- **`HomeScreen`:** Manages operational interaction with an actively connected IoT station. Handles live telemetry buffers, local clock offset calculations (`_clockOffsetMs`), and fault-injection debugging panels.
- **`NearbyScreen`:** Orchestrates BLE discovery. Implements aggressive defensive checks distinguishing mobile permission requirements (Location, GPS) from desktop capabilities before allowing scans.
- **`StorageScreen`:** Integrates `DatabaseService` and `SyncService` to merge local and cloud data into a `UnifiedStation` model. Supports offline inference evaluation and cloud prediction emulation in RAM.
- **`ConfigScreen` & `MlModelManagerSheet`:** Governs application environment settings, network endpoint overrides, circular agronomic time windows (`_agronomicDayStart`/`End`), and local ML model lifecycle.

### 4.3 Reusable Widgets (`lib/screens/widgets`)
- **`InferenceCard`:** A purely stateless deterministic widget that renders the output of ML recommendations. It maps diverse incoming data contracts (BLE telemetry, SQLite records, cloud emulation) to visual states (Grey: No Data, Amber: Restricted/Unrecommended, Blue: Irrigate, Green: Avoidable). Incorporates regex-based extraction for emulation metadata and handles time rollover.

---

## 5. **Interfaces Section**

The Presentation Component acts as the integration point between the User and the Core Services:

- **Inbound User Interfaces:** Flutter touch and pointer events via Material widgets, text entry for API endpoints and secrets, map interactions for geographic coordinates.
- **Outbound Hardware Interfaces:** Listens to platform BLE adapter states, streams BLE scan results, and connects via the `BleService` abstraction wrapper. Accesses platform GPS by querying the native OS through `geolocator`.
- **Core Facade Interface (`CliRoutines`):**
  - Screens delegate database reads/writes (`db`), API calls (`cloudApi`), ML evaluations (`inferenceBridge`), and BLE operations (`bleService`) entirely through `CliRoutines`.
  - Status updates flow back up to the UI shell via asynchronous `StreamSubscriptions` and reactive `ValueNotifier` hooks.

---

## 6. **Dependencies Section**

### 6.1 Internal Subsystem Dependencies
The presentation layer relies on the following core domains, accessed strictly through the facade:
- **`core/database`**: `DatabaseService`, `SyncService`, `AppSettings`, `Device`
- **`core/network`**: `ApiClient` for REST synchronizations and health pings.
- **`features/ble`**: `BleService`, `BleDataProcessor`, `PicoHandshakeModule`.
- **`features/ml_inference`**: `InferenceBridge`, `SaviaLstmInferenceEngine`.
- **`features/weather`**: `OpenMeteoClient`.
- **`core/theme` & `core/utils`**: `AppStyles` (design tokens), `AppDateFormatter`, `AppLocalizations` (i18n).

### 6.2 External Package Dependencies
- **`flutter_blue_plus`**: Standard BLE protocol operations and peripheral negotiation.
- **`geolocator`**: Cross-platform location and GPS permission assertion.
- **`flutter_map` & `latlong2`**: Slippy map rendering using OpenStreetMap tiles (avoiding proprietary map SDKs).
- **`flutter_secure_storage`**: Platform-native keychain access for cryptographic PSK caching.
- **`http` & `path_provider`**: REST requests and filesystem log exports.

---

## 7. **Component Diagram**

The following C4 Component Diagram illustrates the internal structure of the Presentation Layer and its relationship to the foundational system components.

```mermaid
C4Component
    title Component Diagram for Presentation Layer

    Container_Boundary(presentation, "Presentation Layer") {
        Component(shell, "App Shell (main.dart)", "Flutter", "Bootstraps app, provides responsive navigation and global status UI.")
        Component(facade, "CliRoutines (Facade)", "Dart", "Central orchestrator. Abstracts domain services, BLE, Cloud, and ML from UI.")
        
        Component_Boundary(screens, "Application Screens") {
            Component(home_screen, "Home Screen", "Widget", "Live telemetry, RTC drift sync, console logger, and edge execution.")
            Component(nearby_screen, "Nearby Screen", "Widget", "Hardware permissions, BLE discovery, and secure pairing.")
            Component(storage_screen, "Storage Screen", "Widget", "Unified local/cloud datastore, bidirectional sync, RAM emulation.")
            Component(config_screen, "Config Screen", "Widget", "Modulo-24 agronomic scheduling, GPS tools, API settings, ML management.")
        }
        
        Component_Boundary(widgets, "Shared Widgets") {
            Component(inference_card, "InferenceCard", "StatelessWidget", "Visualizes ML verdicts, semantic states, and agronomic restrictions.")
        }
    }

    Container_Ext(core_db, "Core Database", "Isar / SQLite", "Persists local devices, telemetry, ML models, and configurations.")
    Container_Ext(core_net, "Core Network", "HTTP", "Cloud API synchronization and health endpoints.")
    Container_Ext(feat_ble, "BLE Stack", "flutter_blue_plus", "GATT characteristics, streams, device authentication.")
    Container_Ext(feat_ml, "ML Engines", "Dart / RF / LSTM", "Executes forecasting and decision trees.")

    Rel(shell, screens, "Routes & Mounts")
    Rel(shell, facade, "Initializes & Holds")
    
    Rel(screens, inference_card, "Embeds for Prediction Visualization")
    Rel(screens, facade, "Delegates domain logic & commands")
    
    Rel(facade, core_db, "Reads/Writes State")
    Rel(facade, core_net, "Syncs Data / Checks Health")
    Rel(facade, feat_ble, "Issues Radio Commands")
    Rel(facade, feat_ml, "Triggers Inferences & Emulations")
```
