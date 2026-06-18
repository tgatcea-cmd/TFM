class LocationSettings {
  int id;
  double latitude;
  double longitude;
  bool isGpsBased;

  LocationSettings(this.id, this.latitude, this.longitude, this.isGpsBased);
}

class PredictionRecord {
  int timestamp;
  double predictedHumidity;
  String recommendation;

  PredictionRecord(this.timestamp, this.predictedHumidity, this.recommendation);
}

class SoilHumidityRecord {
  int timestamp;
  double value;

  SoilHumidityRecord(this.timestamp, this.value);
}

class WeatherRecord {
  int timestamp;
  double temperature;
  double humidity;
  double radiation;
  double precipitation;

  WeatherRecord(
    this.timestamp,
    this.temperature,
    this.humidity,
    this.radiation,
    this.precipitation,
  );
}
