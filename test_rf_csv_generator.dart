import 'dart:io';
import 'dart:convert';
import 'package:tfm_app/features/ml_inference/dynamic_random_forest.dart';

// Same scaler used in test_rf_script.dart
class SaviaLstmScaler {
  static const double hs30Mean = 0.7712527688624472;
  static const double hs30Std = 0.042382551037717174;
  static double scaleHs30(double val) => (val - hs30Mean) / hs30Std;
  
  static const double radSumMean = 4191.1622;
  static const double radSumStd = 1443.3734;
  static double scaleRadiation(double val) => (val - radSumMean) / radSumStd;
}

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart test_rf_csv_generator.dart <path_to_dynamic_model.json>');
    print('Example: dart test_rf_csv_generator.dart model_RF_final.json');
    exit(1);
  }

  final String jsonPath = args[0];
  final File file = File(jsonPath);
  
  if (!await file.exists()) {
    print('Error: JSON model file not found at $jsonPath');
    exit(1);
  }

  print('Loading dynamic JSON model from $jsonPath...');
  final String jsonString = await file.readAsString();
  final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
  
  final rfModel = DynamicRandomForest.fromJson(jsonMap);
  print('Successfully loaded model with ${rfModel.numTrees} trees.');

  final File outFile = File('rf_boundary_data.csv');
  final sink = outFile.openWrite();
  
  // Write CSV Header
  sink.writeln('Radiation_Raw,Humidity_Raw,Radiation_Scaled,Humidity_Scaled,Prob_Class0_Stress,Prob_Class1_Healthy,Predicted_Class');

  print('Generating prediction grid...');
  
  // Generate a grid
  // Radiation ranges roughly from 0 to 8000 W/m2 in 48h
  // Humidity ranges roughly from 0.0 to 1.0 (VWC)
  
  int count = 0;
  for (double rad = 0; rad <= 8000; rad += 100) {
    for (double hum = 0.0; hum <= 1.0; hum += 0.02) {
      
      final double normalizedRad = SaviaLstmScaler.scaleRadiation(rad);
      final double scaledPredHum = SaviaLstmScaler.scaleHs30(hum);
      
      // Predict
      // Feature order must match what the tree expects: [normalizedRad, scaledPredHum]
      final List<double> probs = rfModel.predict([normalizedRad, scaledPredHum]);
      
      // Determine class (0 = Irrigation Needed / Stress, 1 = Irrigation Avoidable / Healthy)
      final int resultClass = (probs.length > 1 && probs[1] > probs[0]) ? 1 : 0;
      
      sink.writeln('${rad.toStringAsFixed(2)},${hum.toStringAsFixed(3)},'
          '${normalizedRad.toStringAsFixed(4)},${scaledPredHum.toStringAsFixed(4)},'
          '${probs[0].toStringAsFixed(4)},${probs.length > 1 ? probs[1].toStringAsFixed(4) : "0.0000"},'
          '$resultClass');
          
      count++;
    }
  }

  await sink.close();
  print('Done! Generated $count data points and saved to ${outFile.absolute.path}');
}
