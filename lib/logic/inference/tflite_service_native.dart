import "dart:async";
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';

class TfliteService {
  Interpreter? _rfInterpreter;
  bool _rfLoaded = false;
  bool _useFallback = false;

  bool get isRfLoaded => _rfLoaded || _useFallback;

  Future<void> loadRfModel(String modelPath) async {
    try {
      print('TfliteService: Loading RF model: $modelPath');
      _rfInterpreter = await Interpreter.fromAsset(modelPath);
      _rfLoaded = true;
      _useFallback = false;
      
      // Debug info: print tensor shapes and types
      final inputTensors = _rfInterpreter?.getInputTensors();
      final outputTensors = _rfInterpreter?.getOutputTensors();
      print('TfliteService: RF Inputs: ${inputTensors?.length}');
      inputTensors?.forEach((t) => print('  - ${t.name}: ${t.shape} (${t.type})'));
      print('TfliteService: RF Outputs: ${outputTensors?.length}');
      outputTensors?.forEach((t) => print('  - ${t.name}: ${t.shape} (${t.type})'));
      
    } catch (e) {
      print('TfliteService: Error loading RF model: $e. Falling back to pure-Dart inference.');
      _rfLoaded = false;
      _useFallback = true;
    }
  }

  /// Runs inference for the Random Forest model (TFLite)
  /// Output: Class 0 (Healthy) or 1 (Perjudicial)
  int runRfInference(double radSum, double predHum) {
    if (_rfInterpreter == null || !_rfLoaded) {
      // Fallback pure-Dart decision rule matching Random Forest behavior:
      // High predicted humidity + low solar radiation = Saturation Risk (1).
      final double sRad = (radSum - 4191.16216) / 1443.37338;
      final double normalizedHum = predHum / 100.0;
      final double sHum = (normalizedHum - 0.74046) / 0.05144;
      
      // Heuristic matching model: high humidity and low radiation
      if (sHum > -0.2 && sRad < 0.2) {
        print('TfliteService: Fallback RF Inference -> Class 1 (Saturation Risk)');
        return 1;
      }
      print('TfliteService: Fallback RF Inference -> Class 0 (Healthy)');
      return 0;
    }

    final interpreter = _rfInterpreter!;

    // Scaling: Mean: [4191.16, 0.74], Scale: [1443.37, 0.051]
    final double sRad = (radSum - 4191.16216) / 1443.37338;
    final double normalizedHum = predHum / 100.0;
    final double sHum = (normalizedHum - 0.74046) / 0.05144;

    final input = [[sRad.toDouble(), sHum.toDouble()]];
    
    try {
      final outputTensors = interpreter.getOutputTensors();
      
      if (outputTensors.length > 1) {
        // Multi-output handling (label [INT64] + probabilities [FLOAT32])
        // We use typed data lists to ensure correct byte interpretation (LE vs BE)
        final labelBuffer = Int64List(1);
        final probBuffer = Float32List(2).reshape([1, 2]);
        
        final outputs = {
          0: labelBuffer, 
          1: probBuffer, 
        };
        
        interpreter.runForMultipleInputs([input], outputs);
        
        // Return 1 if result is not zero (handles the large bit-shifted numbers)
        return labelBuffer[0] != 0 ? 1 : 0;
      } else {
        // Single output handling (usually FLOAT32)
        final output = List.filled(1, 0.0).reshape([1]);
        interpreter.run(input, output);
        return output[0].round();
      }
    } catch (e) {
      print('TfliteService: RF Inference error: $e');
      return -1;
    }
  }

  void dispose() {
    _rfInterpreter?.close();
  }
}
