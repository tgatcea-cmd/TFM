import bluetooth
import struct
import time
from micropython import const

# BLE Event Codes
_IRQ_CENTRAL_CONNECT = const(1)
_IRQ_CENTRAL_DISCONNECT = const(2)
_IRQ_GATTS_WRITE = const(3)

# UUIDs
SERVICE_UUID = bluetooth.UUID("0000ffe0-0000-1000-8000-00805f9b34fb")
HANDSHAKE_UUID = bluetooth.UUID("0000ffe1-0000-1000-8000-00805f9b34fb")
COMMAND_UUID = bluetooth.UUID("0000ffe2-0000-1000-8000-00805f9b34fb")
DATA_UUID = bluetooth.UUID("0000ffe3-0000-1000-8000-00805f9b34fb")

_WRITE = const(0x0008)
_NOTIFY = const(0x0010)

SERVICE = (
    SERVICE_UUID,
    (
        (HANDSHAKE_UUID, _WRITE),
        (COMMAND_UUID, _WRITE),
        (DATA_UUID, _NOTIFY),
    ),
)

# Realistic test scenarios (0.0 to 100.0 scale)
# 1 = Saturation Risk (Perjudicial), 0 = Healthy (Safe to irrigate)
TEST_SCENARIOS = [
    (92.0, "SATURATION RISK (1)"), # High humidity -> Should be 1
    (75.0, "SATURATION RISK (1)"), # High humidity -> Should be 1
    (45.0, "HEALTHY (0)"),         # Safe
    (30.0, "HEALTHY (0)"),         # Safe
]

class PicoBLE:
    def __init__(self, ble):
        self._ble = ble
        self._ble.active(True)
        self._ble.irq(self._irq)
        ((self._h_handshake, self._h_command, self._h_data),) = self._ble.gatts_register_services((SERVICE,))
        self._connections = set()
        self._authenticated = False
        self._debug_mode = False
        self._scenario_idx = 0
        self._advertise()

    def _irq(self, event, data):
        if event == _IRQ_CENTRAL_CONNECT:
            conn_handle, _, _ = data
            self._connections.add(conn_handle)
            print("Connected")
        elif event == _IRQ_CENTRAL_DISCONNECT:
            conn_handle, _, _ = data
            self._connections.remove(conn_handle)
            self._authenticated = False
            print("Disconnected")
            self._advertise()
        elif event == _IRQ_GATTS_WRITE:
            conn_handle, value_handle = data
            value = self._ble.gatts_read(value_handle)
            if value_handle == self._h_handshake:
                self._handle_handshake(value)
            elif value_handle == self._h_command:
                if self._authenticated:
                    self._handle_command(value)

    def _handle_handshake(self, value):
        if value == b'\xde\xad\xbe\xef':
            self._authenticated = True
            print("Handshake Success!")
        else:
            print("Handshake Failed")

    def _handle_command(self, value):
        if not value: return
        cmd = value[0]
        if cmd == 0x01: # Sync
            print("Sync Request -> Sending history")
            self.send_test_history()
        elif cmd == 0x02: # Env Data (Weather Bridge)
            print(f"Received Weather Bridge (24h sequence, len: {len(value)-1})")
        elif cmd == 0x09: # CUSTOM DEBUG COMMAND
            self._debug_mode = not self._debug_mode
            print(f"Debug Mode: {'ON' if self._debug_mode else 'OFF'}")

    def send_0x11_soil_hum(self, offset, val):
        raw = int(val * 100)
        payload = struct.pack(">BBH", 0x11, offset, raw)
        self._notify(payload)

    def send_0x12_predicted_hum(self, val):
        """Sends Predicted Humidity (from FPGA/LSTM) to trigger RF on App"""
        raw = int(val * 100)
        payload = struct.pack(">BH", 0x12, raw)
        self._notify(payload)
        print(f"Sent 0x12 (Predicted): {val}%")

    def _notify(self, data):
        for conn in self._connections:
            self._ble.gatts_notify(conn, self._h_data, data)

    def send_test_history(self):
        # Send 10 samples to satisfy InferenceBridge requirement
        base_hum = 45.0
        for i in range(10):
            self.send_0x11_soil_hum(i, base_hum - i*0.5)
            time.sleep_ms(50)

    def run_debug_cycle(self):
        if not self._authenticated or not self._debug_mode: return
        
        val, label = TEST_SCENARIOS[self._scenario_idx]
        print(f"Probing Scenario: {label} ({val}%)")
        self.send_0x12_predicted_hum(val)
        
        self._scenario_idx = (self._scenario_idx + 1) % len(TEST_SCENARIOS)

    def _advertise(self, interval_us=500000):
        name = "Pico2W_Station"
        adv = bytearray(b'\x02\x01\x06')
        adv += bytearray((len(name) + 1, 0x09)) + name.encode()
        self._ble.gap_advertise(interval_us, adv)
        print("Advertising...")

def main():
    ble = bluetooth.BLE()
    pico = PicoBLE(ble)
    
    last_debug = time.ticks_ms()
    while True:
        if pico._debug_mode and time.ticks_diff(time.ticks_ms(), last_debug) > 5000:
            pico.run_debug_cycle()
            last_debug = time.ticks_ms()
        time.sleep_ms(100)

if __name__ == "__main__":
    main()
