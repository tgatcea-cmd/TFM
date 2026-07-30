# Savia BLE API Documentation

The Savia device acts as a BLE GATT peripheral. It uses **CBOR (Concise Binary Object Representation)** for all data payloads to remain compact.

## Base UUIDs
*   **Base UUID pattern:** `5A71A000-0000-0000-0000-0000000000XX`
*   **Service UUID:** `5A71A000-0000-0000-0000-000000000001`

All characteristic UUIDs fall under this base pattern by replacing the last byte.

## Characteristics

### 1. Status (`...0010`)
*   **Permissions:** READ, NOTIFY
*   **Description:** Returns the current state of the device.
*   **Payload (CBOR to JSON equivalent):**
    ```json
    {
      "v": 1,
      "fw": "0.1.0-c",
      "mode": "local", // or "forward"
      "irrigation_hour": 6,
      "now_ms": 1690000000000, // or null if unset
      "utc_offset_min": 0,
      "act": [{"port": 1, "gpio": 15, "on": false}], // Actuators state
      "uptime_s": 3600,
      "last_sync_ms": 1689990000000,
      "weather_updated_ms": 1689990000000,
      "lora": {
        "inited": true,
        "joined": true,
        "rssi": -85,
        "snr": 5.5,
        "last_ms": 1689990000000,
        "module": "Wio-E5",
        "seq": 12
      }
    }
    ```

### 2. Time Sync (`...0011`)
*   **Permissions:** WRITE
*   **Description:** Sets the real-time clock on the device.
*   **Payload:**
    ```json
    {
      "v": 1,
      "op": "set",
      "ms": 1690000000000 // Timestamp in milliseconds
    }
    ```

### 3. Weather (`...0012`)
*   **Permissions:** WRITE
*   **Description:** Uploads weather forecast arrays to the device.
*   **Payload:**
    ```json
    {
      "v": 1,
      "op": "upd",
      "data": {
        "past_ta_hourly": [22.1, 21.5, 20.0],
        "future_ta_hourly": [23.5, 24.1, 25.0]
      }
    }
    ```

### 4. Config (`...0013`)
*   **Permissions:** READ, WRITE, NOTIFY
*   **Description:** Manage the configuration of the device and its connected sensors.
*   **Read Payload (Snapshot):**
    ```json
    {
      "v": 1,
      "device": {"model": "...", "mcu": "RP2040", "fw": "0.1.0-c"},
      "name": "Savia-1",
      "sleep_s": 3600,
      "deep_sleep": true,
      "capture_s": 600,
      "daily_hour": 12,
      "mock": false,
      "log_level": 1,
      "wake_gpio": 14,
      "lora_period_s": 3600,
      "inference_mode": "local",
      "infer_dev": true,
      "utc_offset_min": 120,
      "irrigation_hour": 6,
      "lat": 40.4167, // or null
      "lon": -3.7032, // or null
      "sensors": [
        {
          "port": 1,
          "gpio": 2,
          "type": "analog_linear",
          "addr": "0",
          "interval_s": 600,
          "kind": "soil_moisture",
          "depth_cm": 10,
          "scale": 1.0,
          "offset": 0.0
        }
      ]
    }
    ```
*   **Write Payload (Patch):**
    ```json
    {
      "v": 1,
      "op": "set",
      "sleep_s": 1800 // include any fields you want to update
    }
    ```
*   **Notify Payload (Ack):** `{"v": 1, "op": "config_ok"}` or `{"v": 1, "op": "config_err"}`

### 5. Auth (`...0014`)
*   **Permissions:** READ, WRITE
*   **Description:** Controls authentication and device provisioning using a zero-knowledge **Challenge-Response** protocol. Plaintext passwords are **never** stored or transmitted over Bluetooth; the station only stores `auth_key = SHA256(password)` (32 bytes).
*   **Device Provisioning States:**
    *   **Unprovisioned (`prov: false`):** On fresh flash or factory reset, `auth_key` is set to all zeros (`0x00...`). No password is set yet. First-time setup is performed using `op: "setpw"`.
    *   **Provisioned (`prov: true`):** A password has been set (in example/test scripts, default is `"admin"`). Connections require proving knowledge of the password using `op: "auth"`.
*   **Protocol Flow & Operations:**
    1.  **Read Challenge (Nonce):**
        *   Client reads `...0014` to obtain a fresh random 16-byte `nonce`.
        *   Read Payload: `{"v": 1, "prov": true, "authed": false, "nonce": <bytes>}`
    2.  **Authenticate (`op: "auth"`):**
        *   Client computes local key: `key = SHA256(password)`
        *   Client computes MAC proof: `mac = SHA256(key + nonce)`
        *   Write Payload: `{"v": 1, "op": "auth", "mac": <bytes>}`
        *   Device computes `expected_mac = SHA256(stored_auth_key + nonce)`. If matched, `authed` becomes `true` for the active BLE connection handle.
    3.  **Initial Setup (`op: "setpw"` - Unprovisioned only):**
        *   Write Payload: `{"v": 1, "op": "setpw", "key": <bytes>}` where `key = SHA256(new_password)`.
        *   Saves `auth_key` to flash and sets `authed = true`.
    4.  **Change Password (`op: "chgpw"`):**
        *   Write Payload: `{"v": 1, "op": "chgpw", "old_mac": <bytes>, "key": <bytes>}` where `old_mac = SHA256(current_auth_key + nonce)` and `key = SHA256(new_password)`.
        *   Validates `old_mac`, updates stored `auth_key`, and sets `authed = true`.

### 6. Pinmap (`...0015`)
*   **Permissions:** READ
*   **Description:** Gets the hardware GPIO inventory and their current roles.
*   **Payload:**
    ```json
    {
      "v": 1,
      "pins": [
        {
          "gpio": 0,
          "state": "in_use",
          "reason": "sensor",
          "caps": 5,
          "port": 1
        }
      ]
    }
    ```

### 7. Data Request (`...0020`)
*   **Permissions:** WRITE
*   **Description:** Requests logs, data or triggers operations.
*   **Payload:**
    ```json
    {
      "v": 1,
      "op": "get", // "get", "count", "clear", "mock", "ingest", "lora", "at", "sdi12", "act", "infer"
      "kind": "agg", // "raw", "agg", "pred", "logs"
      "from": 1680000000000,
      "to": 1690000000000,
      "limit": 100
    }
    ```

### 8. Data Response (`...0021`)
*   **Permissions:** NOTIFY
*   **Description:** Responses to data requests arrive here in chunks.
*   **Payload:**
    ```json
    {
      "v": 1,
      "op": "chunk",
      "s": 0, // sequence number
      "t": 5, // total chunks
      "eof": false,
      "p": <bytes> // The actual chunk payload (CBOR encoded inner structure)
    }
    ```
    Once all chunks are received and reassembled in order (0 to t-1), the concatenated `p` bytes form a complete CBOR message (e.g. an array of readings or a count response).
