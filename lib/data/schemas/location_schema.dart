import "dart:async";
import 'package:realm/realm.dart';

part 'location_schema.realm.dart';

@RealmModel()
class _LocationSettings {
  @PrimaryKey()
  late int id; // Singleton ID: 1
  late double latitude;
  late double longitude;
  late bool isGpsBased; // true if auto-updating via GPS
}
