import 'package:isar_community/isar.dart';
part 'app_rf_model.g.dart';

/// Database schema for storing downloaded Random Forest models
@collection
class RfModel {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true, replace: true)
  late String modelId;
  
  late String cropName;
  late String version;
  late String description;
  
  late String treeDataJson; // The serialized JSON payload
  
  bool isActive = false;
  late DateTime updatedAt;
}