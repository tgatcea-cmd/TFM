import 'package:isar_community/isar.dart';
part 'app_rf_model.g.dart';

/// Database schema for storing downloaded Random Forest models in the local Isar database.
/// 
/// This model represents a machine learning model, specifically a Random Forest,
/// used for local on-device inference. It stores metadata about the model (e.g., crop name, version)
/// as well as the serialized model payload.
@collection
class RfModel {
  /// The auto-incremented primary key for the Isar database.
  Id id = Isar.autoIncrement;
  
  /// A unique identifier for this specific model, replacing any existing entry with the same ID.
  @Index(unique: true, replace: true)
  late String modelId;
  
  /// The name of the crop this model is designed for (e.g., 'Tomato', 'Almond').
  late String cropName;
  
  /// The version string of the model.
  late String version;
  
  /// A brief description detailing what this model predicts or its specific characteristics.
  late String description;
  
  /// The serialized JSON payload representing the Random Forest tree data.
  /// This string is parsed during initialization to construct the model for inference.
  late String treeDataJson;
  
  /// Indicates whether this model is currently the active model selected for making predictions.
  bool isActive = false;
  
  /// The timestamp of when this model record was last updated or synced.
  late DateTime updatedAt;
}