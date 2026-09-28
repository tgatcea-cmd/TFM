import 'package:isar_community/isar.dart';

part 'device.g.dart';

/// Represents a remote or local agricultural device (e.g., weather station or soil sensor node).
/// 
/// Stored in the local Isar database. Contains device metadata, synchronization status, 
/// historical sensor readings, and machine learning predictions.
@collection
class Device {
  /// The auto-incremented primary key for the database.
  Id id = Isar.autoIncrement;

  /// A unique string identifying this specific hardware device.
  @Index(unique: true)
  late String deviceIdentifier; 

  /// A human-readable name for the device, defaulting to "Unknown Station".
  String name = "Unknown Station";

  /// The geographic latitude where the device is located.
  double? latitude;
  
  /// The geographic longitude where the device is located.
  double? longitude;
  
  /// The password or token used to authenticate handshakes with the device.
  late String handshakePassword;

  /// Indicates if this device is capable of performing machine learning inference locally.
  bool localInferenceCapabilities = false;
  
  /// Indicates if this device communicates via LoRaWAN.
  bool loraEnabled = false;

  /// The timestamp of the last successful synchronization with the remote backend or device.
  DateTime? latestSynchronizedTime;
  
  /// The timestamp when an inference prediction was last triggered for this device.
  DateTime? latestInferenceTriggerDate;

  /// A list of historical sensor readings collected from the device.
  List<HistoricValue> historicValues = [];
  
  /// A list of past predictions made for this device.
  List<Prediction> previousPredictions = [];
  
  /// A list of recently generated predictions for this device.
  List<Prediction> newPredictions = [];

  /// Flag indicating if the local device state is fully synchronized with the server.
  bool isSynced = false;
  
  /// The timestamp of the last local update to this device's record.
  DateTime updatedAt = DateTime.now();

  /// Determines if there is enough recent historical data to perform a new inference.
  /// 
  /// Returns `true` if outside typical daylight hours (10:00 to 19:00) and if there is
  /// at least one sensor reading at 30cm depth within the last 48 hours.
  @ignore
  bool get enoughForInference {
    final now = DateTime.now();
    if (now.hour >= 10 && now.hour < 19) return false;
    final cutoff = now.subtract(const Duration(hours: 48)).millisecondsSinceEpoch;
    return historicValues.any((v) => v.depthCm == 30.0 && v.tsMs != null && v.tsMs! >= cutoff);
  }
}

/// Represents a single historical sensor reading embedded within a [Device].
@embedded
class HistoricValue {
  /// The timestamp of the reading in milliseconds since epoch.
  int? tsMs;
  
  /// The hardware port on the device from which the reading was taken.
  int? port;
  
  /// The kind or type of sensor (e.g., 'SoilMoisture', 'Temperature').
  String? kind; 
  
  /// The recorded numeric value from the sensor.
  double? value;
  
  /// The depth in centimeters where the sensor is installed (useful for soil sensors).
  double? depthCm;
}

/// Represents a machine learning prediction embedded within a [Device].
@embedded
class Prediction {
  /// The timestamp for which this prediction applies in milliseconds since epoch.
  int? tsMs;
  
  /// The identifier of the model used to generate this prediction.
  String? model; 
  
  /// The kind of metric predicted (e.g., 'SoilMoisture').
  String? kind; 
  
  /// The hardware port the prediction correlates to, if applicable.
  int? port;
  
  /// The predicted numeric value.
  double? value;
  
  /// The depth in centimeters this prediction correlates to.
  double? depthCm;
  
  /// The confidence score of the prediction, typically between 0.0 and 1.0.
  double? confidence;
}

/// A transient model for holding weather data records.
class WeatherRecord {
  /// Timestamp of the weather record in milliseconds since epoch.
  final int timestamp;
  
  /// Temperature reading in Celsius.
  final double temp;
  
  /// Relative humidity percentage.
  final double hum;
  
  /// Solar radiation measurement.
  final double radiation;
  
  /// Precipitation amount in millimeters.
  final double prec;
  
  /// Creates a new [WeatherRecord].
  WeatherRecord({required this.timestamp, required this.temp, required this.hum, required this.radiation, required this.prec});
}

/// A transient model for holding soil humidity sensor records.
class SoilHumidityRecord {
  /// Timestamp of the record in milliseconds since epoch.
  final int timestamp;
  
  /// The measured soil humidity value.
  final double value;
  
  /// Creates a new [SoilHumidityRecord].
  SoilHumidityRecord({required this.timestamp, required this.value});
}

/// A transient model holding structured prediction outputs and agronomic recommendations.
class PredictionRecord {
  /// Timestamp of the prediction in milliseconds since epoch.
  final int timestamp;
  
  /// The predicted future soil humidity.
  final double predictedHumidity;
  
  /// An actionable recommendation based on the prediction (e.g., "Irrigate soon").
  final String recommendation;
  
  /// Creates a new [PredictionRecord].
  PredictionRecord({required this.timestamp, required this.predictedHumidity, required this.recommendation});
}
