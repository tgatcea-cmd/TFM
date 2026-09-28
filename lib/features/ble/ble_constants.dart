/// Defines the Bluetooth Low Energy (BLE) UUID constants used for communicating with the Savia device.
///
/// This class holds the primary service UUID and all the characteristic UUIDs
/// required to interact with the device's custom BLE profile.
class BleConstants {
  /// The primary service UUID for the Savia device.
  static const String serviceUuid = "5a71a000-0000-0000-0000-000000000001";
  /// Characteristic UUID for reading the device's status.
  static const String statusUuid = "5a71a000-0000-0000-0000-000000000010";
  /// Characteristic UUID for synchronizing the device's real-time clock (RTC).
  static const String timeSyncUuid = "5a71a000-0000-0000-0000-000000000011";
  /// Characteristic UUID for sending weather forecast data to the device.
  static const String weatherUuid = "5a71a000-0000-0000-0000-000000000012";
  /// Characteristic UUID for sending commands and requesting data from the device.
  static const String dataRequestUuid = "5a71a000-0000-0000-0000-000000000020";
  /// Characteristic UUID for receiving chunked responses and data payloads from the device.
  static const String dataResponseUuid = "5a71a000-0000-0000-0000-000000000021";
}
