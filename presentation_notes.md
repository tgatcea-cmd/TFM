# Architecture & Data Flow Overview

## 1. Architecture & Setup
* **3 Working Layers**: The architecture consists of the **Deep Edge** (IoT Station / Pico / FPGA), the **Edge** (this Flutter App running on mobile/PC), and the **Fog/Cloud** Server (TFM backend API handling telemetry sync and the Random Forest catalog).
* **The User opens the app**. 
* **Read/Write to IoT Station**: You can read Status (`0x10`), Telemetry & Predictions (`0x20`), and you can write UTC time (`0x11`) and trigger LSTM inferences (`0x20` op `infer`).
* **Handshake & Security**: The app pairs with the IoT Station using an HMAC-SHA256 Challenge-Response handshake using a known 128-bit Shared Secret.

## 2. Fog Server & Settings
* **Fog Server Interaction**: The app authenticates using a Bearer token (`apiKey`) and can pull (Read) or push (Write) telemetry and predictions.
* **Upload/Delete Local Data**: Users can upload local data to the Fog, and can completely purge the local Realm database from the settings.
* **Logical Settings**: The user can configure manual/auto GPS coords, the Agronomic Schedule (Irrigation/Prediction day start and end times), and the Fog/Cloud server IP and API key.
* **Dynamic Random Forest**: The user can fetch the catalog from the Fog server (`/models/rf`) and dynamically download and apply new Random Forest JSON models.

## 3. Inference Logic Execution
* **Trigger Check**: When inference is triggered, the app checks the agronomic schedule (preventing execution in the restricted "Yellow Zone") and checks if the station's storage has enough historical telemetry data.
* **"Local" Mode Execution**: If the station is in `Local` mode, the app fetches the 48h past and 24h future weather forecast from Open-Meteo, sends it to the IoT station via BLE (`0x12`), and sends the trigger command (`0x20`). The **LSTM inference runs directly on the Deep Edge hardware (IoT Station)**. The app then polls and downloads the resulting prediction vector.
* **"Forward" Mode Execution**: If the station is in `Forward` mode, the app reads the necessary data and Open-Meteo forecast, but **the LSTM inference runs on the Edge (the Mobile App itself)**, *not* on the IoT Hardware. The app uses its own local `SaviaLstmInferenceEngine` pipeline to calculate the 24-hour future soil moisture curve (at 30cm depth) and saves it locally.
* **Storage Screen / Cloud Emulation**: If triggered from the Storage Screen (using "Run Cloud Emulation"), the app effectively runs a RAM-based "Forward" inference. Crucially, it **pivots the reference time (T_ref)** to match the timestamp of the last saved telemetry record, completely emulating what the prediction and verdict *would have been* at that historical moment.
* **The Verdict**: After the LSTM generates the 24h prediction curve, the app takes the minimum predicted humidity and the 48h solar radiation sum, feeds them into the Random Forest model, and provides the final verdict (e.g., "Irrigation Needed" or "Irrigation Avoidable").
