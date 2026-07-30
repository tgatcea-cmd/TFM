import 'package:isar_community/isar.dart';

part 'device.g.dart';

@collection
class Device {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String deviceIdentifier; 

  String name = "Unknown Station";

  double? latitude;
  double? longitude;
  late String handshakePassword;

  bool localInferenceCapabilities = false;
  bool loraEnabled = false;

  DateTime? latestSynchronizedTime;
  DateTime? latestInferenceTriggerDate;

  List<HistoricValue> historicValues = [];
  List<Prediction> previousPredictions = [];
  List<Prediction> newPredictions = [];

  bool isSynced = false;
  DateTime updatedAt = DateTime.now();

  @ignore
  bool get enoughForInference {
    final now = DateTime.now();
    if (now.hour >= 10 && now.hour < 19) return false;
    final cutoff = now.subtract(const Duration(hours: 48)).millisecondsSinceEpoch;
    return historicValues.any((v) => v.depthCm == 30.0 && v.tsMs != null && v.tsMs! >= cutoff);
  }
}

@embedded
class HistoricValue {
  int? tsMs;
  int? port;
  String? kind; 
  double? value;
  double? depthCm;
}

@embedded
class Prediction {
  int? tsMs;
  String? model; 
  String? kind; 
  int? port;
  double? value;
  double? depthCm;
  double? confidence;
}

class WeatherRecord {
  final int timestamp;
  final double temp;
  final double hum;
  final double radiation;
  final double prec;
  WeatherRecord({required this.timestamp, required this.temp, required this.hum, required this.radiation, required this.prec});
}

class SoilHumidityRecord {
  final int timestamp;
  final double value;
  SoilHumidityRecord({required this.timestamp, required this.value});
}

class PredictionRecord {
  final int timestamp;
  final double predictedHumidity;
  final String recommendation;
  PredictionRecord({required this.timestamp, required this.predictedHumidity, required this.recommendation});
}
