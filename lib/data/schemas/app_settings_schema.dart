import 'package:realm/realm.dart';

part 'app_settings_schema.realm.dart';

@RealmModel()
class _AppSettings {
  @PrimaryKey()
  late int id; // Singleton ID: 1
  late String tfmServerUrl;
  late int tfmServerPort;
  late String tfmServerApiKey;
  late String selectedTfliteModel;
  late bool invertModelOutput;
  late bool permitOpenMeteoFill;
  late bool alwaysForceInference;
}
