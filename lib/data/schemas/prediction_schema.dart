import 'package:realm/realm.dart';

part 'prediction_schema.realm.dart';

@RealmModel()
class _PredictionRecord {
  @PrimaryKey()
  late int timestamp; // Milliseconds since epoch
  late double predictedHumidity;
  late String recommendation; // e.g. "Irrigate", "Wait"
}
