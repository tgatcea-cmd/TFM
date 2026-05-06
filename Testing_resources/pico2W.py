import bluetooth
import struct
import time
from micropython import const

# BLE Event Codes
_IRQ_CENTRAL_CONNECT = const(1)
_IRQ_CENTRAL_DISCONNECT = const(2)
_IRQ_GATTS_WRITE = const(3)

# UUIDs from ble_constants.dart
SERVICE_UUID = bluetooth.UUID("0000ffe0-0000-1000-8000-00805f9b34fb")
HANDSHAKE_UUID = bluetooth.UUID("0000ffe1-0000-1000-8000-00805f9b34fb")
COMMAND_UUID = bluetooth.UUID("0000ffe2-0000-1000-8000-00805f9b34fb")
DATA_UUID = bluetooth.UUID("0000ffe3-0000-1000-8000-00805f9b34fb")

# Characteristic Flags
_WRITE = const(0x0008)
_NOTIFY = const(0x0010)

# BLE Service Setup
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
            print(f"Write event on handle {value_handle}, value: {value.hex()}")
            
            if value_handle == self._h_handshake:
                self._handle_handshake(value)
            elif value_handle == self._h_command:
                if self._authenticated:
                    self._handle_command(value)
                else:
                    print("Unauthenticated command attempt")

    def _handle_handshake(self, value):
        # App writes [0xDE, 0xAD, 0xBE, 0xEF]
        if value == b'\xde\xad\xbe\xef':
            self._authenticated = True
            print("Handshake Success!")
        else:
            print("Handshake Failed: ", value)

    def _handle_command(self, value):
        if not value: return
        cmd_type = value[0]
        
        if cmd_type == 0x01: # Sync Request
            print("Sync Requested")
            self.send_test_data()
        elif cmd_type == 0x02: # Env Data
            self._handle_env_data(value[1:])

    def _handle_env_data(self, payload):
        # Expected 8 bytes: [T_hi, T_lo, H_hi, H_lo, R_hi, R_lo, P_hi, P_lo]
        if len(payload) < 8:
            print("Invalid Env Data length")
            return
            
        temp, hum, rad, prec = struct.unpack(">HHHH", payload)
        print(f"Received Env Data:")
        print(f"  Temp: {temp/100.0} C")
        print(f"  Hum: {hum/100.0} %")
        print(f"  Rad: {rad/100.0} W/m2")
        print(f"  Prec: {prec/100.0} mm")

    def send_soil_humidity(self, hour_offset, humidity):
        """
        Sends soil humidity in format: [0x11, offset, hum_hi, hum_lo]
        humidity: float (e.g. 45.5) -> scaled by 100 as per Dart logic
        """
        if not self._authenticated: return
        
        raw_hum = int(humidity * 100)
        # Pack as [0x11 (byte), offset (byte), raw_hum (uint16 big-endian)]
        payload = struct.pack(">BBH", 0x11, hour_offset, raw_hum)
        
        for conn in self._connections:
            self._ble.gatts_notify(conn, self._h_data, payload)
        print(f"Sent: {humidity}% at offset {hour_offset}")

    def send_test_data(self):
        # Sample data
        self.send_soil_humidity(0, 42.15)
        time.sleep_ms(100)
        self.send_soil_humidity(1, 41.80)

    def _advertise(self, interval_us=500000):
        name = "Pico2W_Station"
        adv = bytearray(b'\x02\x01\x06') # Flags
        adv += bytearray((len(name) + 1, 0x09)) + name.encode() # Local Name
        self._ble.gap_advertise(interval_us, adv)
        print("Advertising...")

def main():
    ble = bluetooth.BLE()
    pico = PicoBLE(ble)
    
    # Loop to simulate periodic data sending if desired
    while True:
        time.sleep(10)
        if pico._authenticated:
             pico.send_soil_humidity(0, 38.5)

if __name__ == "__main__":
    main()
