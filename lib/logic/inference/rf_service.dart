import 'dart:convert';
import 'package:flutter/services.dart';

class RfService {
  Map<String, dynamic>? _model;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  Future<void> loadModel(String assetPath) async {
    try {
      final String jsonString = await rootBundle.loadString(assetPath);
      _model = json.decode(jsonString);
      _isLoaded = true;
      print('RF Model loaded successfully from $assetPath');
    } catch (e) {
      print('Error loading RF model: $e');
      _isLoaded = false;
    }
  }

  /// Runs inference for the Random Forest model
  /// Input: [radiacion_sum_t0, HS30_min_t+1]
  /// Output: Class 0 (Healthy) or 1 (Stress)
  int runInference(double radSum, double predHum) {
    if (!_isLoaded || _model == null) return -1;

    // 1. Scaling
    final List<dynamic> mean = _model!['mean'];
    final List<dynamic> scale = _model!['scale'];
    
    final double sRad = (radSum - (mean[0] as num)) / (scale[0] as num);
    final double sHum = (predHum - (mean[1] as num)) / (scale[1] as num);
    
    final List<double> features = [sRad, sHum];

    // 2. Tree Ensemble Inference
    final List<dynamic> trees = _model!['trees'];
    double class0Prob = 0;
    double class1Prob = 0;

    for (var tree in trees) {
      final List<dynamic> nodes = tree;
      int currentNodeIdx = 0;
      
      while (true) {
        final Map<String, dynamic> node = nodes[currentNodeIdx];
        final int left = node['l'];
        final int right = node['r'];
        
        if (left == -1) {
          // Leaf node
          final List<dynamic> value = node['v'];
          // value is [count_class0, count_class1]
          // We normalize and add to total
          final num total = (value[0] as num) + (value[1] as num);
          class0Prob += (value[0] as num) / total;
          class1Prob += (value[1] as num) / total;
          break;
        } else {
          // Decision node
          final int featureIdx = node['f'];
          final double threshold = (node['t'] as num).toDouble();
          
          if (features[featureIdx] <= threshold) {
            currentNodeIdx = left;
          } else {
            currentNodeIdx = right;
          }
        }
      }
    }

    // 3. Apply Class Weights
    final List<dynamic> weights = _model!['class_weight'];
    // In our model: class_weight={0: 1, 1: 6.0}
    final double w0 = (weights[0] as num).toDouble();
    final double w1 = (weights[1] as num).toDouble();
    
    final double final0 = (class0Prob / trees.length) * w0;
    final double final1 = (class1Prob / trees.length) * w1;

    return final1 > final0 ? 1 : 0;
  }
}
