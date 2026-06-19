import bluetooth
import struct
import time
import random
import hashlib










# -------------------------------------------------------------
# MicroPython HMAC Fallback Wrapper
# -------------------------------------------------------------
try:
    import hmac
except ImportError:
    class MockHMAC:
        def __init__(self, key, msg=None, digestmod=None):
            self.key = key
            self.msg = msg or b''
            self.digestmod = digestmod or hashlib.sha256
        
        def update(self, msg):
            self.msg += msg
            
        def digest(self):
            block_size = 64
            k = self.key
            if len(k) > block_size:
                k = hashlib.sha256(k).digest()
            if len(k) < block_size:
                k = k + b'\x00' * (block_size - len(k))
            
            ipad = bytes(x ^ 0x36 for x in k)
            opad = bytes(x ^ 0x5c for x in k)
            
            inner = hashlib.sha256(ipad + self.msg).digest()
            return hashlib.sha256(opad + inner).digest()
            
        def hexdigest(self):
            return self.digest().hex()

    class hmac_fallback:
        @staticmethod
        def new(key, msg=None, digestmod=None):
            return MockHMAC(key, msg, digestmod)
            
        @staticmethod
        def compare_digest(a, b):
            if len(a) != len(b):
                return False
            result = 0
            for x, y in zip(a, b):
                result |= x ^ y
            return result == 0

    hmac = hmac_fallback










# -------------------------------------------------------------
# Cross-Platform Shims for Standard Python / MicroPython
# -------------------------------------------------------------
try:
    from micropython import const
    import machine
    IS_PC = False
except ImportError:
    const = lambda x: x
    IS_PC = True

if not hasattr(time, 'sleep_ms'):
    time.sleep_ms = lambda ms: time.sleep(ms / 1000.0)
if not hasattr(time, 'ticks_ms'):
    time.ticks_ms = lambda: int(time.time() * 1000)
if not hasattr(time, 'ticks_diff'):
    time.ticks_diff = lambda t1, t2: t1 - t2

# Mock machine module if on PC
if IS_PC:
    class MockRTC:
        def __init__(self):
            self._time = time.time()
        def datetime(self, val=None):
            if val is not None:
                # Convert tuple (year, month, day, weekday, hour, minute, second, subsecond) to timestamp
                self._time = time.time()
                print("[PC Mock RTC] Set datetime to:", val)
            return (2026, 6, 12, 5, 12, 0, 0, 0)
    
    class MockMachine:
        @staticmethod
        def RTC():
            return MockRTC()
        @staticmethod
        def lightsleep(ms=None):
            if ms:
                time.sleep(ms / 1000.0)
            else:
                time.sleep(0.1)
    machine = MockMachine










# -------------------------------------------------------------
# CBOR Encoder & Decoder
# -------------------------------------------------------------
def encode_cbor(obj):
    if obj is None:
        return b'\xf6'
    elif isinstance(obj, bool):
        return b'\xf5' if obj else b'\xf4'
    elif isinstance(obj, int):
        if obj >= 0:
            if obj < 24:
                return bytes([obj])
            elif obj < 256:
                return b'\x18' + struct.pack('>B', obj)
            elif obj < 65536:
                return b'\x19' + struct.pack('>H', obj)
            elif obj < 4294967296:
                return b'\x1a' + struct.pack('>I', obj)
            else:
                return b'\x1b' + struct.pack('>Q', obj)
        else:
            val = -1 - obj
            if val < 24:
                return bytes([0x20 + val])
            elif val < 256:
                return b'\x38' + struct.pack('>B', val)
            elif val < 65536:
                return b'\x39' + struct.pack('>H', val)
            elif val < 4294967296:
                return b'\x3a' + struct.pack('>I', val)
            else:
                return b'\x3b' + struct.pack('>Q', val)
    elif isinstance(obj, float):
        return b'\xfb' + struct.pack('>d', obj)
    elif isinstance(obj, (bytes, bytearray)):
        l = len(obj)
        if l < 24:
            header = bytes([0x40 + l])
        elif l < 256:
            header = b'\x58' + struct.pack('>B', l)
        elif l < 65536:
            header = b'\x59' + struct.pack('>H', l)
        else:
            header = b'\x5a' + struct.pack('>I', l)
        return header + obj
    elif isinstance(obj, str):
        data = obj.encode('utf-8')
        l = len(data)
        if l < 24:
            header = bytes([0x60 + l])
        elif l < 256:
            header = b'\x78' + struct.pack('>B', l)
        elif l < 65536:
            header = b'\x79' + struct.pack('>H', l)
        else:
            header = b'\x7a' + struct.pack('>I', l)
        return header + data
    elif isinstance(obj, list):
        l = len(obj)
        if l < 24:
            header = bytes([0x80 + l])
        elif l < 256:
            header = b'\x98' + struct.pack('>B', l)
        elif l < 65536:
            header = b'\x99' + struct.pack('>H', l)
        else:
            header = b'\x9a' + struct.pack('>I', l)
        return header + b''.join(encode_cbor(x) for x in obj)
    elif isinstance(obj, dict):
        l = len(obj)
        if l < 24:
            header = bytes([0xa0 + l])
        elif l < 256:
            header = b'\xb8' + struct.pack('>B', l)
        elif l < 65536:
            header = b'\xb9' + struct.pack('>H', l)
        else:
            header = b'\xba' + struct.pack('>I', l)
        return header + b''.join(encode_cbor(k) + encode_cbor(v) for k, v in obj.items())
    else:
        raise TypeError("Unsupported type: %s" % type(obj))

def decode_cbor(data, offset=0):
    if offset >= len(data):
        return None, offset
    
    b = data[offset]
    major = b >> 5
    val = b & 0x1f
    
    if major < 6:
        if val < 24:
            info = val
            offset += 1
        elif val == 24:
            info = data[offset+1]
            offset += 2
        elif val == 25:
            info = struct.unpack('>H', data[offset+1:offset+3])[0]
            offset += 3
        elif val == 26:
            info = struct.unpack('>I', data[offset+1:offset+5])[0]
            offset += 5
        elif val == 27:
            info = struct.unpack('>Q', data[offset+1:offset+9])[0]
            offset += 9
        else:
            info = None
    
    if major == 0:
        return info, offset
    elif major == 1:
        return -1 - info, offset
    elif major == 2:
        res = data[offset:offset+info]
        return res, offset + info
    elif major == 3:
        res = data[offset:offset+info].decode('utf-8')
        return res, offset + info
    elif major == 4:
        res = []
        for _ in range(info):
            item, offset = decode_cbor(data, offset)
            res.append(item)
        return res, offset
    elif major == 5:
        res = {}
        for _ in range(info):
            k, offset = decode_cbor(data, offset)
            v, offset = decode_cbor(data, offset)
            res[k] = v
        return res, offset
    elif major == 7:
        if b == 0xf4:
            return False, offset + 1
        elif b == 0xf5:
            return True, offset + 1
        elif b == 0xf6:
            return None, offset + 1
        elif b == 0xfb:
            res = struct.unpack('>d', data[offset+1:offset+9])[0]
            return res, offset + 9
        elif b == 0xfa:
            res = struct.unpack('>f', data[offset+1:offset+5])[0]
            return res, offset + 5
        elif b == 0xf9:
            val_bytes = data[offset+1:offset+3]
            h = struct.unpack('>H', val_bytes)[0]
            s = (h >> 15) & 1
            e = (h >> 10) & 0x1f
            m = h & 0x3ff
            if e == 0:
                res = (-1.0)**s * (2.0**-14) * (m / 1024.0)
            elif e == 31:
                res = float('nan') if m != 0 else (float('-inf') if s else float('inf'))
            else:
                res = (-1.0)**s * (2.0**(e - 15)) * (1.0 + m / 1024.0)
            return res, offset + 3
        
    raise ValueError("Unsupported major type: %d" % major)

def decode_cbor_full(data):
    res, _ = decode_cbor(data)
    return res











# -------------------------------------------------------------
# BLE Constants & Services Setup
# -------------------------------------------------------------
_IRQ_CENTRAL_CONNECT = const(1)
_IRQ_CENTRAL_DISCONNECT = const(2)
_IRQ_GATTS_WRITE = const(3)

SERVICE_UUID = bluetooth.UUID("5a71a000-0000-0000-0000-000000000001")
STATUS_UUID = bluetooth.UUID("5a71a000-0000-0000-0000-000000000010")
TIME_SYNC_UUID = bluetooth.UUID("5a71a000-0000-0000-0000-000000000011")
WEATHER_UUID = bluetooth.UUID("5a71a000-0000-0000-0000-000000000012")
DATA_REQUEST_UUID = bluetooth.UUID("5a71a000-0000-0000-0000-000000000020")
DATA_RESPONSE_UUID = bluetooth.UUID("5a71a000-0000-0000-0000-000000000021")

_READ = const(0x0002)
_WRITE = const(0x0008)
_NOTIFY = const(0x0010)

SERVICE = (
    SERVICE_UUID,
    (
        (STATUS_UUID, _READ | _NOTIFY),
        (TIME_SYNC_UUID, _WRITE),
        (WEATHER_UUID, _WRITE),
        (DATA_REQUEST_UUID, _WRITE),
        (DATA_RESPONSE_UUID, _NOTIFY),
    ),
)

SHARED_SECRET = b"TFM_CESAR_PICO_SECRET_KEY_2026"

# Test scenarios for real-time FPGA LSTM inference output
TEST_SCENARIOS = [
    (0.92, "SATURATION RISK (1)"),
    (0.75, "SATURATION RISK (1)"),
    (0.45, "HEALTHY (0)"),
    (0.30, "HEALTHY (0)"),
]

class PicoBLEMock:
    def __init__(self, ble):
        self._ble = ble
        self._ble.active(True)
        self._ble.irq(self._irq)
        ((self._h_status, self._h_time_sync, self._h_weather, self._h_data_request, self._h_data_response),) = self._ble.gatts_register_services((SERVICE,))
        
        # Set buffer size to 256 bytes for all characteristics to handle CBOR structures
        for handle in (self._h_status, self._h_time_sync, self._h_weather, self._h_data_request, self._h_data_response):
            self._ble.gatts_set_buffer(handle, 256)
        
        self._connections = set()
        self._authenticated = False
        self._debug_mode = False
        self._scenario_idx = 0
        self._rtc = machine.RTC()
        self._weather_forecast = []
        
        if IS_PC:
            print("[PC Mock BLE] Initialized emulator.")

        # Generate initial challenge nonce
        self._challenge = bytes([random.randint(0, 255) for _ in range(16)])
        self._update_status()
        self._advertise()

    def _update_status(self):
        status_map = {
            "v": 1,
            "authenticated": self._authenticated,
            "challenge": self._challenge,
            "firmware": "1.3.0-TobiasMock",
            "uptime": time.ticks_ms() // 1000
        }
        self._ble.gatts_write(self._h_status, encode_cbor(status_map))

    def _advertise(self, interval_us=500000):
        name = "PicoWH_MockStation"
        
        # --- 1. MAIN ADVERTISEMENT PACKET (Max 31 Bytes) ---
        # Flags: General discoverable, BR/EDR not supported (3 bytes)
        adv_data = bytearray(b'\x02\x01\x06')
        
        # 128-bit Service UUID (18 bytes)
        # BLE requires UUIDs to be transmitted in Little-Endian format.
        # UUID: 5a71a000-0000-0000-0000-000000000001
        uuid_little_endian = bytes([
            0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
            0x00, 0x00, 0x00, 0x00, 0x00, 0xA0, 0x71, 0x5A
        ])
        
        # Type 0x06 = Incomplete List of 128-bit Service UUIDs
        adv_data += bytearray([17, 0x06]) + uuid_little_endian
        
        # --- 2. SCAN RESPONSE PACKET (Max 31 Bytes) ---
        # Complete Local Name (Type 0x09)
        resp_data = bytearray([len(name) + 1, 0x09]) + name.encode()
        
        # Publish both: The phone reads adv_data, then requests resp_data
        self._ble.gap_advertise(interval_us, adv_data=adv_data, resp_data=resp_data)
        print("Advertising as '%s' with Service UUID..." % name)

    def _irq(self, event, data):
        if event == _IRQ_CENTRAL_CONNECT:
            conn_handle, _, _ = data
            self._connections.add(conn_handle)
            print("Client connected. Resetting challenge.")
            self._authenticated = False
            self._challenge = bytes([random.randint(0, 255) for _ in range(16)])
            self._update_status()
        elif event == _IRQ_CENTRAL_DISCONNECT:
            conn_handle, _, _ = data
            if conn_handle in self._connections:
                self._connections.remove(conn_handle)
            self._authenticated = False
            print("Client disconnected. Re-advertising.")
            self._advertise()
        elif event == _IRQ_GATTS_WRITE:
            conn_handle, value_handle = data
            value = self._ble.gatts_read(value_handle)
            
            if value_handle == self._h_time_sync:
                self._handle_time_sync(value)
            elif value_handle == self._h_weather:
                self._handle_weather(value)
            elif value_handle == self._h_data_request:
                self._handle_data_request(value)

    def _handle_time_sync(self, value):
        try:
            data = decode_cbor_full(value)
            if data and data.get("op") == "set":
                ms = data.get("ms")
                # Update mock RTC
                secs = ms // 1000
                t_struct = time.localtime(secs)
                self._rtc.datetime((t_struct[0], t_struct[1], t_struct[2], t_struct[6], t_struct[3], t_struct[4], t_struct[5], 0))
                print("RTC successfully synchronized to: %d-%02d-%02d %02d:%02d:%02d UTC" % 
                      (t_struct[0], t_struct[1], t_struct[2], t_struct[3], t_struct[4], t_struct[5]))
        except Exception as e:
            print("Error handling time sync: %s" % e)

    def _handle_weather(self, value):
        try:
            data = decode_cbor_full(value)
            if data and "temps" in data:
                self._weather_forecast = data.get("temps", [])
                avg = sum(self._weather_forecast) / len(self._weather_forecast) if self._weather_forecast else 0.0
                print("Stored 24h temperature forecast. Size: %d, Avg Temp: %.2f C" % (len(self._weather_forecast), avg))
        except Exception as e:
            print("Error handling weather: %s" % e)

    def _handle_data_request(self, value):
        try:
            data = decode_cbor_full(value)
            if not data:
                return

            op = data.get("op")
            
            # 1. Challenge-Response Handshake
            if op == "auth":
                resp = data.get("resp")
                if resp is not None:
                    resp = bytes(resp)
                else:
                    resp = b""
                
                expected = hmac.new(SHARED_SECRET, self._challenge, hashlib.sha256).digest()
                print("Auth response verification: Got %s, Expected %s" % (resp.hex(), expected.hex()))
                
                if len(resp) == len(expected) and hmac.compare_digest(resp, expected):
                    self._authenticated = True
                    print("HMAC verification successful! Session authenticated.")
                else:
                    self._authenticated = False
                    print("HMAC verification failed!")
                
                self._update_status()
                return

            # Authentication Guard
            if not self._authenticated:
                print("Access blocked: Operation '%s' requires authentication." % op)
                return

            # 2. Retrieve history commands
            if op == "get":
                kind = data.get("kind")
                print("Request kind: %s" % kind)
                if kind == "raw":
                    self.send_raw_humidity_history()
                elif kind == "pred":
                    self.send_prediction_history()
            
            # 3. Trigger Real-time FPGA LSTM inference
            elif op == "infer":
                print("Inference trigger requested.")
                self.run_real_time_inference()

            # 4. Toggle Debug Mode
            elif op == "debug_toggle":
                self._debug_mode = not self._debug_mode
                print("Debug mode: %s" % ("ON" if self._debug_mode else "OFF"))

        except Exception as e:
            print("Error processing data request: %s" % e)

    def _notify(self, handle, payload):
        for conn in self._connections:
            self._ble.gatts_notify(conn, handle, payload)

    def send_chunks(self, payload_bytes, chunk_size=128):
        total_chunks = (len(payload_bytes) + chunk_size - 1) // chunk_size
        print("Sending payload in %d chunks..." % total_chunks)
        
        for s in range(total_chunks):
            chunk_data = payload_bytes[s*chunk_size : (s+1)*chunk_size]
            chunk_map = {
                "v": 1,
                "op": "chunk",
                "s": s,
                "t": total_chunks,
                "eof": (s == total_chunks - 1),
                "p": chunk_data
            }
            self._notify(self._h_data_response, encode_cbor(chunk_map))
            time.sleep_ms(30) # Prevent queue buffer overflows

    def send_raw_humidity_history(self):
        # 48 hours of soil moisture raw data (1 reading per hour)
        base_time = time.time() * 1000
        readings = []
        # Generate stable decaying moisture profile (from 0.85 to 0.40)
        for i in range(48):
            readings.append({
                "ts_ms": int(base_time - (47 - i) * 3600000),
                "port": 1,
                "kind": "soil_moisture",
                "value": round(0.85 - (i * 0.009) + random.uniform(-0.01, 0.01), 4),
                "depth_cm": 30
            })
        
        payload = encode_cbor(readings)
        self.send_chunks(payload)

    def send_prediction_history(self):
        # 24 hours of prediction forecast data (1 forecast per hour)
        base_time = time.time() * 1000
        predictions = []
        for i in range(24):
            predictions.append({
                "ts_ms": int(base_time + (i + 1) * 3600000),
                "model": "lstm-hs30",
                "kind": "hs30_forecast",
                "port": None,
                "value": round(0.40 - (i * 0.005) + random.uniform(-0.005, 0.005), 4),
                "confidence": None
            })
        payload = encode_cbor(predictions)
        self.send_chunks(payload)

    def run_real_time_inference(self):
        val, label = TEST_SCENARIOS[self._scenario_idx]
        print("Simulating FPGA LSTM inference: %s (%.2f VWC)" % (label, val))
        
        # Simulate LSTM processing latency
        time.sleep_ms(400)
        
        response = {
            "v": 1,
            "op": "infer_done",
            "ok": True,
            "hs30_min": val
        }
        
        self.send_chunks(encode_cbor(response))
        self._scenario_idx = (self._scenario_idx + 1) % len(TEST_SCENARIOS)

    def run_debug_cycle(self):
        if not self._authenticated or not self._debug_mode:
            return
        self.run_real_time_inference()
















def main():
    ble = bluetooth.BLE()
    pico = PicoBLEMock(ble)
    
    last_debug = time.ticks_ms()
    print("BLE Mock Station active. Entering low power loop.")
    
    while True:
        # If in debug mode, trigger inference cycle every 5 seconds
        if pico._debug_mode and time.ticks_diff(time.ticks_ms(), last_debug) > 5000:
            pico.run_debug_cycle()
            last_debug = time.ticks_ms()
            
        # Light sleep to maintain energy efficiency while advertising / listening
        if not pico._connections:
            # When disconnected, light sleep briefly to conserve power while advertising
            machine.lightsleep(200)
        else:
            time.sleep_ms(100)

if __name__ == "__main__":
    main()
