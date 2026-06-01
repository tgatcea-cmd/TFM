import "dart:async";
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';

class TfliteService {
  Interpreter? _lstmInterpreter;
  Interpreter? _rfInterpreter;
  
  bool _lstmLoaded = false;
  bool _rfLoaded = false;

  bool get isLstmLoaded => _lstmLoaded;
  bool get isRfLoaded => _rfLoaded;

  Future<void> loadLstmModel(String modelPath) async {
    try {
      print('TfliteService: Loading LSTM model: $modelPath');
      _lstmInterpreter = await Interpreter.fromAsset(modelPath);
      _lstmLoaded = true;
    } catch (e) {
      print('TfliteService: Error loading LSTM model: $e');
      _lstmLoaded = false;
    }
  }

  Future<void> loadRfModel(String modelPath) async {
    try {
      print('TfliteService: Loading RF model: $modelPath');
      _rfInterpreter = await Interpreter.fromAsset(modelPath);
      _rfLoaded = true;
      
      // Debug info: print tensor shapes and types
      final inputTensors = _rfInterpreter?.getInputTensors();
      final outputTensors = _rfInterpreter?.getOutputTensors();
      print('TfliteService: RF Inputs: ${inputTensors?.length}');
      inputTensors?.forEach((t) => print('  - ${t.name}: ${t.shape} (${t.type})'));
      print('TfliteService: RF Outputs: ${outputTensors?.length}');
      outputTensors?.forEach((t) => print('  - ${t.name}: ${t.shape} (${t.type})'));
      
    } catch (e) {
      print('TfliteService: Error loading RF model: $e');
      _rfLoaded = false;
    }
  }

  /// Runs inference for a GRU sequence
  double runLstmInference(List<double> sequence) {
    final interpreter = _lstmInterpreter;
    if (interpreter == null || !_lstmLoaded) return -1.0;

    final input = [sequence.map((e) => [e]).toList()];
    final output = List.filled(1 * 1, 0.0).reshape([1, 1]);

    try {
      interpreter.run(input, output);
      return output[0][0];
    } catch (e) {
      print('TfliteService: LSTM Inference error: $e');
      return -1.0;
    }
  }

  /// Runs inference for the Random Forest model (TFLite)
  /// Output: Class 0 (Healthy) or 1 (Perjudicial)
  int runRfInference(double radSum, double predHum) {
    final interpreter = _rfInterpreter;
    if (interpreter == null || !_rfLoaded) return -1;

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
    _lstmInterpreter?.close();
    _rfInterpreter?.close();
  }
}
