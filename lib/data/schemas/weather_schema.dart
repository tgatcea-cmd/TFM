import 'package:realm/realm.dart';

part 'weather_schema.realm.dart';

@RealmModel()
class _WeatherRecord {
  @PrimaryKey()
  late int timestamp; // Milliseconds since epoch
  late double temperature;
  late double humidity;
  late double radiation;
  late double precipitation;
}
