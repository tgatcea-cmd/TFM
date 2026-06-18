import 'package:realm/realm.dart';

part 'device_schema.realm.dart';

@RealmModel()
class _SavedDevice {
  @PrimaryKey()
  late String id; // MAC address / remote ID
  late String name;
}
