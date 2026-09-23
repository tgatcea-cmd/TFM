import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:tfm_app/features/ml_inference/dynamic_random_forest.dart';
import 'package:tfm_app/features/ml_inference/random_forest.dart' as rf;

void main() async {
  print('=== Workflow 5: Dynamic vs Compiled Model Parity Validation ===');
  // 1. Load Dynamic Model (Workflow 1 Static Structure)
  final file = File('test_rf_01.json');
  final jsonString = await file.readAsString();
  final jsonMap = jsonDecode(jsonString);
  final dynamicRf = DynamicRandomForest.fromJson(jsonMap);
  print('Loaded Dynamic JSON model with ${dynamicRf.numTrees} trees.');

  final outFile = File('workflow5_comparison_results.csv');
  final sink = outFile.openWrite();
  sink.writeln('Radiation_Scaled,Humidity_Scaled,Static_Dynamic_Class,Retrieved_Compiled_Class,Match');

  int total = 0;
  int matches = 0;
  int truePositives = 0; // Class 1 matches
  int falseNegatives = 0;
  int falsePositives = 0;

  final rand = Random(42);

  print('Simulating 10,000 real-world retrieved weather points...');
  // Generate 10000 random test cases spanning the normalized feature space
  // Normalized Rad typically between -3.0 and 3.0
  // Scaled Hum typically between -4.0 and 4.0
  for (int i = 0; i < 10000; i++) {
    double rad = (rand.nextDouble() * 6) - 3.0;
    double hum = (rand.nextDouble() * 8) - 4.0;

    // Workflow 1 Approach: Dynamic JSON Model
    List<double> probsDynamic = dynamicRf.predict([rad, hum]);
    int classDynamic = (probsDynamic.length > 1 && probsDynamic[1] > probsDynamic[0]) ? 1 : 0;

    // Workflow 2 Approach: Retrieved Compiled Model
    List<double> probsCompiled = rf.score([rad, hum]);
    int classCompiled = (probsCompiled.length > 1 && probsCompiled[1] > probsCompiled[0]) ? 1 : 0;

    bool match = classDynamic == classCompiled;
    
    total++;
    if (match) matches++;
    
    // Treat Compiled as ground truth
    if (classCompiled == 1 && classDynamic == 1) truePositives++;
    if (classCompiled == 1 && classDynamic == 0) falseNegatives++;
    if (classCompiled == 0 && classDynamic == 1) falsePositives++;

    sink.writeln('${rad.toStringAsFixed(4)},${hum.toStringAsFixed(4)},$classDynamic,$classCompiled,$match');
  }

  await sink.close();

  double accuracy = matches / total;
  double recall = truePositives / (truePositives + falseNegatives);
  double precision = truePositives / (truePositives + falsePositives);

  print('----------------------------------------------------');
  print('Total Evaluation Samples: $total');
  print('Exact Matches: $matches');
  print('Accuracy Parity: ${(accuracy * 100).toStringAsFixed(2)}%');
  print('Recall Parity (Class 1): ${(recall * 100).toStringAsFixed(2)}%');
  print('Precision Parity (Class 1): ${(precision * 100).toStringAsFixed(2)}%');
  print('----------------------------------------------------');
  print('Detailed output saved to: workflow5_comparison_results.csv');
}
