import 'package:realm/realm.dart';

part 'soil_humidity_schema.realm.dart';

@RealmModel()
class _SoilHumidityRecord {
  @PrimaryKey()
  late int timestamp; // Milliseconds since epoch
  late double value;
}
