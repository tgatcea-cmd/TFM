import struct

# --- Mock implementation of MicroPython's bluetooth module ---

# Event codes matching MicroPython's bluetooth module
_IRQ_CENTRAL_CONNECT = 1
_IRQ_CENTRAL_DISCONNECT = 2
_IRQ_GATTS_WRITE = 3

class UUID:
    def __init__(self, value):
        self.value = value
    def __str__(self):
        return str(self.value)
    def __repr__(self):
        return f"UUID('{self.value}')"

class BLE:
    def __init__(self):
        self._active = False
        self._irq_handler = None
        self._char_values = {}
        self._handles_map = {}

    def active(self, val):
        self._active = val
        print(f"[Mock BLE] Adapter set active: {val}")

    def irq(self, handler):
        self._irq_handler = handler

    def gatts_register_services(self, services):
        print("[Mock BLE] Registering services:")
        handles = []
        handle_counter = 1
        
        # services is a tuple/list of (UUID, (characteristics, ...))
        for svc_uuid, chars in services:
            print(f"  Service UUID: {svc_uuid}")
            svc_handles = []
            for char in chars:
                char_uuid = char[0]
                flags = char[1]
                svc_handles.append(handle_counter)
                self._char_values[handle_counter] = b''
                self._handles_map[handle_counter] = char_uuid
                print(f"    Char Handle {handle_counter}: {char_uuid} (flags: {flags})")
                handle_counter += 1
            handles.append(tuple(svc_handles))
        return tuple(handles)

    def gatts_read(self, handle):
        return self._char_values.get(handle, b'')

    def gatts_write(self, handle, data):
        self._char_values[handle] = bytes(data)

    def gatts_notify(self, conn_handle, handle, data):
        char_uuid = self._handles_map.get(handle, "Unknown")
        print(f"[Mock BLE] NOTIFY to Central {conn_handle} on handle {handle} ({char_uuid}): {list(data)}")

    def gap_advertise(self, interval_us, adv_data=None):
        print(f"[Mock BLE] Start advertising (interval: {interval_us} us)...")

    # --- CLI Simulation Helper Methods for PC ---
    
    def simulate_connect(self, conn_handle=1):
        print(f"\n--- Simulating Central Connection (Handle {conn_handle}) ---")
        if self._irq_handler:
            self._irq_handler(_IRQ_CENTRAL_CONNECT, (conn_handle, 0, 0))

    def simulate_disconnect(self, conn_handle=1):
        print(f"\n--- Simulating Central Disconnection (Handle {conn_handle}) ---")
        if self._irq_handler:
            self._irq_handler(_IRQ_CENTRAL_DISCONNECT, (conn_handle, 0, 0))

    def simulate_write(self, handle, data, conn_handle=1):
        char_uuid = self._handles_map.get(handle, "Unknown")
        print(f"\n--- Simulating App Write to Char Handle {handle} ({char_uuid}): {list(data)} ---")
        self.gatts_write(handle, data)
        if self._irq_handler:
            self._irq_handler(_IRQ_GATTS_WRITE, (conn_handle, handle))
