// ignore_for_file: avoid_web_libraries_in_flutter, uri_does_not_exist
import "dart:async";
import 'dart:typed_data';
import 'dart:js_util' as js_util;
import 'package:tflite_web/tflite_web.dart';

class TfliteService {
  TFLiteModel? _rfModel;
  bool _rfLoaded = false;

  bool get isRfLoaded => _rfLoaded;

  Future<void> loadRfModel(String modelPath) async {
    try {
      print('TfliteServiceWeb: Initializing TFLite JS WebAssembly...');
      await TFLiteWeb.initializeUsingCDN();
      
      print('TfliteServiceWeb: Loading model from asset URL: $modelPath');
      // Resolve asset URL relative to root on Flutter web
      String url = modelPath;
      if (!url.startsWith('assets/')) {
        url = 'assets/$url';
      }
      
      try {
        print('TfliteServiceWeb: Trying URL: $url');
        _rfModel = await TFLiteModel.fromUrl(url);
        _rfLoaded = true;
      } catch (e) {
        print('TfliteServiceWeb: Failed to load from $url, trying assets/assets/ format...');
        final nestedUrl = url.startsWith('assets/assets/') ? url : url.replaceFirst('assets/', 'assets/assets/');
        _rfModel = await TFLiteModel.fromUrl(nestedUrl);
        _rfLoaded = true;
      }
      
      print('TfliteServiceWeb: Model loaded successfully!');
    } catch (e) {
      print('TfliteServiceWeb: Error loading RF model: $e');
      _rfLoaded = false;
    }
  }

  /// Runs inference for the Random Forest model (TFLite)
  /// Output: Class 0 (Healthy) or 1 (Perjudicial)
  int runRfInference(double radSum, double predHum) {
    final model = _rfModel;
    if (model == null || !_rfLoaded) return -1;

    // Scaling: Mean: [4191.16, 0.74], Scale: [1443.37, 0.051]
    final double sRad = (radSum - 4191.16216) / 1443.37338;
    final double normalizedHum = predHum / 100.0;
    final double sHum = (normalizedHum - 0.74046) / 0.05144;

    try {
      // Input shape is [1, 2] for 2 features: sRad and sHum
      final inputTensor = Tensor(
        Float32List.fromList([sRad, sHum]),
        shape: [1, 2],
        type: TFLiteDataType.float32,
      );

      final result = model.predict<dynamic>(inputTensor);
      
      dynamic data;
      if (result is List) {
        // Multi-output list: first output is label
        final labelTensor = result[0];
        data = js_util.callMethod(labelTensor, 'dataSync', []);
      } else if (js_util.hasProperty(result, 'dataSync')) {
        // Single output Tensor
        data = js_util.callMethod(result, 'dataSync', []);
      } else {
        // NamedTensorMap
        final outputsInfo = model.outputs;
        if (outputsInfo.isNotEmpty) {
          final outName = outputsInfo[0].name;
          final labelTensor = js_util.getProperty(result, outName);
          if (labelTensor != null) {
            data = js_util.callMethod(labelTensor, 'dataSync', []);
          }
        }
      }

      double val = 0.0;
      if (data is List) {
        val = (data[0] as num).toDouble();
      } else if (data is TypedData) {
        if (data is Float32List) {
          val = data[0];
        } else if (data is Int32List) {
          val = data[0].toDouble();
        } else if (data is Int64List) {
          val = data[0].toDouble();
        } else if (data is Float64List) {
          val = data[0];
        } else {
          val = (data as dynamic)[0].toDouble();
        }
      } else if (data is num) {
        val = data.toDouble();
      }

      final label = val != 0.0 ? 1 : 0;
      print('TfliteServiceWeb: RF Inference output value: $val -> Label: $label');
      return label;
    } catch (e) {
      print('TfliteServiceWeb: Inference error: $e');
      return -1;
    }
  }

  void dispose() {
    // TFLiteModel doesn't have a close method on web, we can just clear it
    _rfModel = null;
    _rfLoaded = false;
  }
}
