# C4 Component-Level Documentation: BLE Communications Component

## 1. Overview Section
The **BLE Communications Component** (located in `lib/features/ble`) serves as the hardware abstraction layer and communication gateway of the application. It manages the point-to-point wireless communication between the client application (Flutter smartphone/desktop) and the agronomical field station powered by a Raspberry Pi Pico W microcontroller.

## 2. Purpose Section
The primary purpose of this component is to abstract away the complexities of Bluetooth Low Energy (BLE) communication, cryptographic handshakes, and binary data serialization. It exposes high-level asynchronous operations and reactive data streams to the rest of the application, enabling seamless interactions with the hardware telemetry station without exposing underlying GATT or CBOR protocol mechanics.

## 3. Software Features Section
The component provides the following core capabilities:
- **Device Discovery & Lifecycle Management**: Scanning for Savia BLE peripherals, establishing GATT connections with automatic MTU negotiation, handling disconnections, and monitoring link stability.
- **Cryptographic Authentication**: Executing a challenge-response handshake utilizing SHA-256 HMAC-like proofs to unlock protected hardware registers and prevent unauthorized station configuration.
- **High-Efficiency CBOR Serialization**: Encoding and decoding Concise Binary Object Representation (CBOR) payloads. Features manual binary packaging of IEEE 754 32-bit floating point arrays for weather forecasts to comply with the station's 512-byte MTU ceiling.
- **Packet Chunk Reassembly**: Reconstituting arbitrary-length, multi-part telemetry responses transmitted over GATT notifications via a sequence-indexed chunking protocol.
- **Station State & Command Execution**: Controlling RTC time synchronization, reading pin configurations and system statuses, dispatching historical data requests (`raw`, `agg`, `pred`), triggering on-device LSTM machine learning inferences, and orchestrating station resets and storage flushes.

## 4. Code Elements Section
The component is composed of several specialized classes and sub-modules:
- `BleConstants`: Centralizes standard 128-bit UUID definitions for the Savia telemetry service and its associated GATT characteristics.
- `BleService`: The central BLE connectivity and command facade. It orchestrates the connection lifecycle, characteristic caching, manual serialization of forecasts, and dispatching of commands to the hardware station.
- `PicoHandshakeModule`: A dedicated security sub-module implementing the cryptographic challenge-response handshake to authenticate the client to the hardware station.
- `BleChunkAssembler`: A stateful packet assembly engine responsible for reconstructing CBOR documents that exceed standard GATT notification limits by tracking and concatenating binary fragments.
- `BleDataProcessor`: A higher-level adapter that bridges incoming, assembled BLE data streams with the local SQLite database for persistence.

## 5. Interfaces Section
### Inbound Interfaces
- **Application Facade (`CliRoutines`)**: Initiates connection requests, orchestrates station synchronization, dispatches forecasts, and triggers inference routines via `BleService`.
- **ML Inference Domain (`InferenceBridge`)**: Queries the connection state through `BleService` to determine whether to trigger live on-station inferences or fallback to simulated inference modes.
- **Presentation Layer**: Consumes reactive connection and data streams from `BleService` and `BleDataProcessor`.

### Outbound Interfaces
- **Hardware Gateway (GATT Server)**: Reads, writes, and listens to notifications from the Raspberry Pi Pico W using the `flutter_blue_plus` package.
- **Persistence Layer (`DatabaseService`)**: `BleDataProcessor` persists decoded historical telemetry, aggregated data, and ML prediction records locally to the application database.

## 6. Dependencies Section
### External Libraries
- **`flutter_blue_plus`**: Provides cross-platform native BLE bindings for scanning, connection, MTU negotiation, and characteristic interactions.
- **`cbor`**: Facilitates binary decoding and encoding of RFC 8949 CBOR objects.
- **`crypto`**: Used for SHA-256 hash calculations required during the challenge-response authentication protocol.

### Internal Modules
- **`lib/core/database/app_database.dart`**: Persistent storage mechanism for ingested station data.
- **`lib/cli_routines.dart`**: The application orchestration layer utilizing the BLE component.

## 7. Component Diagram

```mermaid
flowchart TD
    %% Internal Boundaries
    subgraph AppBoundary ["Flutter Application"]
        subgraph Facades ["Application Logic & Facades"]
            CLI["CLI Routines\n(Application Facade)"]
            ML["Inference Engine\n(InferenceBridge)"]
        end

        subgraph BleComponent ["BLE Communications Component (lib/features/ble)"]
            BleSvc["BleService\n(Central BLE Facade)"]
            Auth["PicoHandshakeModule\n(Security Handshake)"]
            Assembler["BleChunkAssembler\n(Packet Reassembly)"]
            Processor["BleDataProcessor\n(Data Adapter)"]
            Const["BleConstants\n(UUIDs)"]
        end
        
        DB[("DatabaseService\n(SQLite)")]
    end

    %% External Systems
    Pico["Raspberry Pi Pico W\n(GATT Server)"]

    %% Relationships - Inbound
    CLI -->|Connects, Syncs, Dispatches| BleSvc
    ML -->|Queries status, Triggers| BleSvc

    %% Relationships - Internal Component
    BleSvc -->|Reads Constants| Const
    BleSvc *--|Delegates Handshake| Auth
    BleSvc *--|Delegates Assembly| Assembler
    Processor -->|Observes Stream| BleSvc

    %% Relationships - Outbound
    Processor -->|Persists Telemetry| DB
    BleSvc <-->|Reads/Writes/Notifies\n(CBOR over BLE)| Pico
    Auth -->|Challenges/Verifies\n(CBOR over BLE)| Pico
```
