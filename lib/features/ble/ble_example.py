import asyncio
import time
import cbor2
import hashlib
import struct
from datetime import datetime
try:
    import matplotlib.pyplot as plt
except ImportError:
    print("matplotlib not installed. Run 'pip install matplotlib' for plotting.")
    plt = None
from bleak import BleakScanner, BleakClient

# Base UUIDs from the protocol.h / documentation
SAVIA_SVC_UUID            = "5a71a000-0000-0000-0000-000000000001"
SAVIA_CHR_STATUS_UUID     = "5a71a000-0000-0000-0000-000000000010"
SAVIA_CHR_TIME_SYNC_UUID  = "5a71a000-0000-0000-0000-000000000011"
SAVIA_CHR_WEATHER_UUID    = "5a71a000-0000-0000-0000-000000000012"
SAVIA_CHR_CONFIG_UUID     = "5a71a000-0000-0000-0000-000000000013"
SAVIA_CHR_AUTH_UUID       = "5a71a000-0000-0000-0000-000000000014"
SAVIA_CHR_DATA_REQ_UUID   = "5a71a000-0000-0000-0000-000000000020"
SAVIA_CHR_DATA_RESP_UUID  = "5a71a000-0000-0000-0000-000000000021"

# --- Authentication Configuration ---
DEVICE_PASSWORD = b""             # Set to b"" or None for unprovisioned/empty password, or b"admin"
SET_NEW_PASSWORD = None           # Set to e.g. b"new_password" to change the password during this run

chunks_dict = {}
response_queue = asyncio.Queue()

def notification_handler(sender, data):
    """
    Handles chunked responses from the SAVIA_CHR_DATA_RESP_UUID characteristic.
    Reassembles them and puts the full response in an asyncio queue.
    """
    global chunks_dict
    payload = cbor2.loads(data)
    
    if payload.get("op") == "chunk":
        seq = payload.get("s")
        total = payload.get("t")
        eof = payload.get("eof")
        p = payload.get("p")
        
        if seq == 0 and len(chunks_dict) > 0 and (total != len(chunks_dict)):
            # If we see seq 0 and we had incomplete old data, clear it.
            chunks_dict.clear()
            
        chunks_dict[seq] = p
        
        print(f"Received chunk {seq + 1}/{total}")
        
        # Check if we have all chunks
        if len(chunks_dict) == total:
            sorted_keys = sorted(chunks_dict.keys())
            full_data = b"".join(chunks_dict[k] for k in sorted_keys)
            chunks_dict.clear() 
            
            if not full_data:
                response_queue.put_nowait([])
            else:
                try:
                    decoded_response = cbor2.loads(full_data)
                    response_queue.put_nowait(decoded_response)
                except Exception as e:
                    print("Failed to decode reassembled payload:", e)

def make_weather_cbor(past, future):
    """
    Manually creates a CBOR payload for the weather update using 32-bit floats (0xfa).
    This keeps the payload around 412 bytes, safely under the device's 512-byte buffer limit,
    because Python's cbor2 library defaults to 64-bit floats (which exceed 600 bytes).
    """
    out = b'\xa3' # Map of 3 items
    out += b'\x61\x76\x01' # "v": 1
    out += b'\x62\x6f\x70\x63\x75\x70\x64' # "op": "upd"
    out += b'\x64\x64\x61\x74\x61\xa2' # "data": Map of 2 items
    
    # "past_ta_hourly"
    out += b'\x6e' + b'past_ta_hourly'
    out += b'\x98\x30' # Array of 48 items
    for f in past:
        out += b'\xfa' + struct.pack('>f', float(f))
        
    # "future_ta_hourly"
    out += b'\x70' + b'future_ta_hourly'
    out += b'\x98\x18' # Array of 24 items
    for f in future:
        out += b'\xfa' + struct.pack('>f', float(f))
        
    return out

async def wait_for_data(client, request_payload, description):
    """
    Helper function to send a data request and wait for the reassembled response via queue.
    """
    await client.write_gatt_char(SAVIA_CHR_DATA_REQ_UUID, cbor2.dumps(request_payload))
    try:
        # Wait up to 10 seconds for the reassembled response to arrive
        return await asyncio.wait_for(response_queue.get(), timeout=10.0)
    except asyncio.TimeoutError:
        print(f"[-] Timeout waiting for {description}")
        return None

async def main():
    print("Scanning for Savia device...")
    device = await BleakScanner.find_device_by_filter(
        lambda d, ad: SAVIA_SVC_UUID.lower() in [u.lower() for u in ad.service_uuids]
    )
    
    if not device:
        print("Savia device not found. Ensure it is powered on and advertising.")
        return
        
    print(f"Found device: {device.name} [{device.address}]")
    
    # Increase timeout and disable cached services to help mitigate Windows connection errors
    async with BleakClient(device, timeout=20.0, winrt=dict(use_cached_services=False)) as client:
        print("Connected!")
        
        # Enable notifications for data responses
        await client.start_notify(SAVIA_CHR_DATA_RESP_UUID, notification_handler)
        
        # 1. Authentication Handshake
        print("\n--- Authentication Handshake ---")
        auth_state = cbor2.loads(await client.read_gatt_char(SAVIA_CHR_AUTH_UUID))
        nonce = auth_state.get("nonce", b"")
        nonce_bytes = nonce if isinstance(nonce, bytes) else bytes(nonce)
        
        # Normalize password types (strings/None -> bytes)
        def to_bytes(pw):
            if pw is None:
                return b""
            if isinstance(pw, str):
                return pw.encode("utf-8")
            return bytes(pw)

        dev_pw_bytes = to_bytes(DEVICE_PASSWORD)
        new_pw_bytes = to_bytes(SET_NEW_PASSWORD) if SET_NEW_PASSWORD is not None else None

        if not auth_state.get("prov"):
            print("Device is UNPROVISIONED. Setting up initial password...")
            target_pw = new_pw_bytes if new_pw_bytes is not None else dev_pw_bytes
            new_key = hashlib.sha256(target_pw).digest()
            await client.write_gatt_char(SAVIA_CHR_AUTH_UUID, cbor2.dumps({
                "v": 1, "op": "setpw", "key": new_key
            }))
            print("Initial password has been set!")
        else:
            if not auth_state.get("authed"):
                print("Authenticating...")
                key = hashlib.sha256(dev_pw_bytes).digest()
                computed_mac = hashlib.sha256(key + nonce_bytes).digest()
                
                await client.write_gatt_char(SAVIA_CHR_AUTH_UUID, cbor2.dumps({
                    "v": 1, "op": "auth", "mac": computed_mac
                }))
                
                # Check if auth succeeded
                auth_check = cbor2.loads(await client.read_gatt_char(SAVIA_CHR_AUTH_UUID))
                if not auth_check.get("authed"):
                    print("[-] Authentication FAILED! Incorrect password.")
                    await client.stop_notify(SAVIA_CHR_DATA_RESP_UUID)
                    return
                print("Authentication successful!")
                
                # Change password if requested
                if new_pw_bytes is not None:
                    print("Changing password...")
                    new_key = hashlib.sha256(new_pw_bytes).digest()
                    # A new nonce might have been generated after auth, so re-read it
                    new_nonce = auth_check.get("nonce", b"")
                    new_nonce_bytes = new_nonce if isinstance(new_nonce, bytes) else bytes(new_nonce)
                    old_mac = hashlib.sha256(key + new_nonce_bytes).digest()
                    
                    await client.write_gatt_char(SAVIA_CHR_AUTH_UUID, cbor2.dumps({
                        "v": 1, "op": "chgpw", "old_mac": old_mac, "key": new_key
                    }))
                    print("Password changed successfully!")
            else:
                print("Already authenticated.")
            
        # 2. Get information: is inference capable? If yes set inference mode to local
        print("\n--- Checking Inference Capabilities ---")
        config = cbor2.loads(await client.read_gatt_char(SAVIA_CHR_CONFIG_UUID))
        if config.get("infer_dev"):
            print("Device IS inference capable. Setting inference mode to 'local'...")
            await client.write_gatt_char(SAVIA_CHR_CONFIG_UUID, cbor2.dumps({
                "v": 1,
                "op": "set",
                "inference_mode": "local"
            }))
        else:
            print("Device is NOT inference capable.")
            
        # 3. Sync time
        print("\n--- Syncing Time ---")
        now_ms = int(time.time() * 1000)
        await client.write_gatt_char(SAVIA_CHR_TIME_SYNC_UUID, cbor2.dumps({
            "v": 1, "op": "set", "ms": now_ms
        }))
        print(f"Time synced to {now_ms} ms")
        
        # 4. Generate 48h Mock History
        print("\n--- Generating 48h Mock History ---")
        mock_hist_resp = await wait_for_data(client, {
            "v": 1,
            "op": "mock",
            "kind": "48h"
        }, "mock history generation")
        print(f"Mock generation response: {mock_hist_resp}")
        
        # 5. Get 48 past hour soil_humidity at depth 30
        print("\n--- Getting past 48 hours of historic data ---")
        historic_resp = await wait_for_data(client, {
            "v": 1,
            "op": "get",
            "kind": "raw",
            "limit": 150  # Requesting more rows because each hour has multiple depths/sensors
        }, "historic data")
        
        # Filtering for depth 30
        if historic_resp and isinstance(historic_resp, list):
            filtered = [
                reading for reading in historic_resp 
                if reading.get("depth_cm") == 30 and "moist" in str(reading.get("kind", "")).lower()
            ]
            print(f"Found {len(filtered)} historic soil humidity readings at depth 30:")
            print(filtered)
        else:
            print(f"Historic data response: {historic_resp}")
            
        # 6. Send forecast temperature 24 hourly data (mock)
        print("\n--- Sending mock weather forecast (24h) ---")
        # Note: We use a custom manual CBOR builder to force 32-bit floats (0xfa)
        # to ensure the payload stays under 512 bytes.
        mock_past_ta = [20.0 + (i * 0.5) for i in range(48)]   # 48 past hours
        mock_future_ta = [22.0 + (i * 0.5) for i in range(24)] # 24 future hours
        
        weather_payload = make_weather_cbor(mock_past_ta, mock_future_ta)
        await client.write_gatt_char(SAVIA_CHR_WEATHER_UUID, weather_payload)
        print(f"Mock forecast temperature sent ({len(weather_payload)} bytes).")
        
        # 7. Get latest inference result
        print("\n--- Getting latest inference result ---")
        latest_pred = await wait_for_data(client, {
            "v": 1,
            "op": "get",
            "kind": "pred",
            "limit": 24
        }, "latest prediction")
        print(f"Latest prediction: {latest_pred}")
        
        # 8. Send inference request
        print("\n--- Sending Inference Request ---")
        infer_ack = await wait_for_data(client, {
            "v": 1,
            "op": "infer"
        }, "inference ack")
        print(f"Inference ACK: {infer_ack}")
        
        # 9 & 10. Wait for inference (polling up to 6 tries) and get results
        print("\n--- Polling for new inference result ---")
        new_pred = latest_pred
        for attempt in range(1, 7):
            print(f"Polling attempt {attempt}/6... waiting 5 seconds.")
            await asyncio.sleep(5.0)
            
            polled_pred = await wait_for_data(client, {
                "v": 1,
                "op": "get",
                "kind": "pred",
                "limit": 24
            }, "inference poll")
            
            # Check if prediction changed
            if polled_pred != latest_pred:
                new_pred = polled_pred
                print(">>> New inference result detected! <<<")
                break
        
        # 11. Get inference results (already pulled by the polling loop)
        print("\n--- Final Inference Results ---")
        if new_pred and isinstance(new_pred, list):
            for p in new_pred:
                dt = datetime.fromtimestamp(p.get("ts_ms", 0) / 1000.0)
                val = p.get("value", 0.0)
                print(f"[{dt}] Prediction (Depth {p.get('depth_cm', 30)}cm): {val:.4f} VWC")
        else:
            print(new_pred)
        
        # 12. Plotting
        if plt and filtered:
            print("\n--- Plotting Results ---")
            # Extract historical data
            hist_times = []
            hist_vals = []
            for row in filtered:
                # Aggregated rows might use 'hour_ms' or 'ts_ms', and 'mean' or 'value'
                t_ms = row.get("hour_ms", row.get("ts_ms"))
                val = row.get("mean", row.get("value"))
                if t_ms is not None and val is not None:
                    hist_times.append(datetime.fromtimestamp(t_ms / 1000.0))
                    hist_vals.append(val)
            
            # Extract prediction data
            pred_times = []
            pred_vals = []
            if new_pred and isinstance(new_pred, list):
                for row in new_pred:
                    t_ms = row.get("ts_ms")
                    val = row.get("value")
                    if t_ms is not None and val is not None:
                        pred_times.append(datetime.fromtimestamp(t_ms / 1000.0))
                        pred_vals.append(val)
            elif new_pred and isinstance(new_pred, dict):
                t_ms = new_pred.get("ts_ms")
                val = new_pred.get("value")
                if t_ms is not None and val is not None:
                    pred_times.append(datetime.fromtimestamp(t_ms / 1000.0))
                    pred_vals.append(val)
                    
            # Sort arrays chronologically
            if hist_times:
                hist_times, hist_vals = zip(*sorted(zip(hist_times, hist_vals)))
            if pred_times:
                pred_times, pred_vals = zip(*sorted(zip(pred_times, pred_vals)))
            
            fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(10, 8))
            
            if hist_times:
                ax1.plot(hist_times, hist_vals, label="Historic Soil Moisture (30cm)", color="blue", marker="o")
            ax1.set_title("Savia: Historic Soil Moisture")
            ax1.set_ylabel("Soil Moisture")
            ax1.grid(True)
            ax1.legend()
            
            if pred_times:
                # Plot prediction in a different plot (subplot 2) with a different color (green)
                ax2.plot(pred_times, pred_vals, label="Inference Prediction", color="green", linestyle="--", marker="s")
            ax2.set_title("Savia: Inference Prediction")
            ax2.set_xlabel("Time")
            ax2.set_ylabel("Predicted Soil Moisture")
            ax2.grid(True)
            ax2.legend()
            
            plt.tight_layout()
            plt.show()

        # 13. Disconnect
        print("\nDisconnecting...")
        await client.stop_notify(SAVIA_CHR_DATA_RESP_UUID)

if __name__ == "__main__":
    asyncio.run(main())
