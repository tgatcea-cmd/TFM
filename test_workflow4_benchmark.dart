import 'dart:io';
import 'dart:convert';
import 'package:tfm_app/features/ml_inference/dynamic_random_forest.dart';
import 'package:tfm_app/features/ml_inference/random_forest.dart' as rf;

void main() async {
  print('=== Workflow 4: Dynamic vs Static Execution Benchmarking ===');
  
  final file = File('test_rf_01.json');
  final jsonString = await file.readAsString();
  final jsonMap = jsonDecode(jsonString);
  final dynamicRf = DynamicRandomForest.fromJson(jsonMap);

  int iterations = 10000;
  List<List<double>> inputs = List.generate(iterations, (i) => [0.5, 0.5]);

  print('Benchmarking $iterations iterations...');

  // Warmup
  for (int i=0; i<1000; i++) {
    dynamicRf.predict([0.5, 0.5]);
    rf.score([0.5, 0.5]);
  }

  // Benchmark Static (Compiled)
  final staticWatch = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    rf.score(inputs[i]);
  }
  staticWatch.stop();

  // Benchmark Dynamic (JSON)
  final dynamicWatch = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    dynamicRf.predict(inputs[i]);
  }
  dynamicWatch.stop();

  final outFile = File('workflow4_benchmark_results.txt');
  final sink = outFile.openWrite();

  sink.writeln('=== Execution Speed Benchmark ($iterations runs) ===');
  sink.writeln('Compiled Model (random_forest.dart): ${staticWatch.elapsedMilliseconds} ms');
  sink.writeln('Dynamic Model (dynamic_random_forest.dart): ${dynamicWatch.elapsedMilliseconds} ms');
  
  double ratio = dynamicWatch.elapsedMilliseconds / staticWatch.elapsedMilliseconds;
  sink.writeln('Overhead Ratio: Dynamic is ${ratio.toStringAsFixed(2)}x slower than Compiled');

  await sink.close();

  print('Compiled Model: ${staticWatch.elapsedMilliseconds} ms');
  print('Dynamic Model: ${dynamicWatch.elapsedMilliseconds} ms');
  print('Results saved to workflow4_benchmark_results.txt');
}
