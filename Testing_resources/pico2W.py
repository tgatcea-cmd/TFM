import bluetooth
import struct
import time
import math
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

class PicoBLE:
    def __init__(self, ble):
        self._ble = ble
        self._ble.active(True)
        self._ble.irq(self._irq)
        ((self._h_handshake, self._h_command, self._h_data),) = self._ble.gatts_register_services((SERVICE,))
        self._connections = set()
        self._authenticated = False
        self._debug_mode = False
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
            print("Sync Request -> Sending realistic 48h history")
            self.send_realistic_history()
        elif cmd == 0x02: # Env Data (Weather Bridge)
            print(f"Received Weather Bridge (24h sequence)")
        elif cmd == 0x09: # Toggle LSTM Probe
            self._debug_mode = not self._debug_mode
            print(f"LSTM Debug Probe: {'ON' if self._debug_mode else 'OFF'}")

    def send_0x11_soil_hum(self, offset, val):
        raw = int(val * 100)
        payload = struct.pack(">BBH", 0x11, offset, raw)
        self._notify(payload)

    def send_0x12_predicted_hum(self, val):
        """Sends Predicted Humidity (from FPGA/LSTM)"""
        raw = int(val * 100)
        payload = struct.pack(">BH", 0x12, raw)
        self._notify(payload)

    def _notify(self, data):
        for conn in self._connections:
            self._ble.gatts_notify(conn, self._h_data, data)

    def generate_hum_at_hour(self, hour_offset):
        """
        Simulates humidity: 
        - Peak at sunrise (irrigation)
        - Drop during day (sunlight/radiation)
        - Slow recovery/stability at night
        """
        # Current local hour (approximate relative to Now)
        current_hour = (time.localtime()[3] - hour_offset) % 24
        
        # Base level
        hum = 45.0 
        
        # Irrigation peak around 7 AM
        if 7 <= current_hour <= 9:
            hum += 25.0 * math.exp(-(current_hour - 7)**2)
        
        # Sunlight drop (Min at 3 PM)
        if 10 <= current_hour <= 19:
            drop = 15.0 * math.sin((current_hour - 10) * math.pi / 9)
            hum -= drop
            
        return max(15.0, min(95.0, hum))

    def send_realistic_history(self):
        """Sends 48 samples (one per hour) of historical data"""
        for i in range(48, -1, -1):
            val = self.generate_hum_at_hour(i)
            self.send_0x11_soil_hum(i, val)
            time.sleep_ms(20) # Avoid flooding
        
        # Also send current LSTM prediction (Trend if no irrigation)
        # Assuming current state is t=0, predict t+24
        current_hum = self.generate_hum_at_hour(0)
        print(f"History Sent. Current Hum: {current_hum}%. Sending LSTM prediction...")
        
        # Predict a decay (loss of 0.8% per hour if no water)
        prediction = current_hum - 15.0 # Predicted drop over 24h
        self.send_0x12_predicted_hum(max(10.0, prediction))

    def run_debug_probe(self):
        """Simulation of real-time LSTM output updates"""
        if not self._authenticated or not self._debug_mode: return
        
        # Cycle through some realistic LSTM outputs
        # 1. High Hum (Saturation Risk)
        # 2. Critical (Water Stress)
        scenarios = [92.0, 30.0, 75.0, 45.0]
        val = scenarios[int(time.time() / 10) % len(scenarios)]
        
        print(f"LSTM Probe -> Sending Predicted: {val}%")
        self.send_0x12_predicted_hum(val)

    def _advertise(self, interval_us=500000):
        name = "Pico2W_Station"
        adv = bytearray(b'\x02\x01\x06')
        adv += bytearray((len(name) + 1, 0x09)) + name.encode()
        self._ble.gap_advertise(interval_us, adv)
        print("Advertising...")

def main():
    ble = bluetooth.BLE()
    pico = PicoBLE(ble)
    
    last_probe = time.ticks_ms()
    while True:
        if pico._debug_mode and time.ticks_diff(time.ticks_ms(), last_probe) > 10000:
            pico.run_debug_probe()
            last_probe = time.ticks_ms()
        time.sleep_ms(100)

if __name__ == "__main__":
    main()
