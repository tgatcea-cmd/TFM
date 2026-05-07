// ignore_for_file: unintended_html_in_doc_comment

// import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';

class TfliteService {
  Interpreter? _interpreter;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  Future<void> loadModel(String modelPath) async {
    try {
      print('Loading TFLite model: $modelPath');
      _interpreter = await Interpreter.fromAsset(modelPath);
      _isLoaded = true;
      print('Model loaded successfully');
    } catch (e) {
      print('Error loading model: $e');
      _isLoaded = false;
    }
  }

  /// Runs inference for a GRU sequence
  /// Input: List<double> of length 10 (as per PoC analysis)
  /// Output: Single predicted value
  double runInference(List<double> sequence) {
    if (_interpreter == null || !_isLoaded) {
      print('Model not loaded');
      return -1.0;
    }

    // Prepare input: [1, 10, 1] as seen in Jupyter Notebook
    var input = [sequence.map((e) => [e]).toList()];
    var output = List.filled(1 * 1, 0.0).reshape([1, 1]);

    try {
      _interpreter!.run(input, output);
      return output[0][0];
    } catch (e) {
      print('Inference error: $e');
      return -1.0;
    }
  }

  void dispose() {
    _interpreter?.close();
  }
}
