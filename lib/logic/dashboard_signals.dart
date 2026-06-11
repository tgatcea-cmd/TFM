import 'package:signals/signals.dart';
import '../core/db/database_service.dart';
import '../data/schemas/soil_humidity_schema.dart';
import '../data/schemas/weather_schema.dart';
import '../data/schemas/prediction_schema.dart';

class DashboardSignals {
  final DatabaseService _db;

  // Signals for the chart
  final humidityHistory = signal<List<SoilHumidityRecord>>([]);
  final weatherHistory = signal<List<WeatherRecord>>([]);
  final predictionHistory = signal<List<PredictionRecord>>([]);
  
  // Subscriptions to Realm changes would be ideal, but for now we update manually
  // or poll. Since we have onDataProcessed in BleDataProcessor, we can link there.

  DashboardSignals(this._db) {
    refresh();
  }

  void refresh() {
    humidityHistory.value = _db.getSoilHumidityHistory();
    weatherHistory.value = _db.getWeatherHistory();
    predictionHistory.value = _db.getPredictionHistory();
  }
}
