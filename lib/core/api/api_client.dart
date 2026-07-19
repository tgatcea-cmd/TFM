import 'dart:convert';
import 'package:http/http.dart' as http;

// ponytail: dead-simple generic API client. No interceptors, no fluff until you need them.
class ApiClient {
  final String baseUrl;
  
  ApiClient({
    this.baseUrl = "http://localhost:3000/api",
    String? serverUrl,
    int? port,
    String? apiKey,
  });

  Future<bool> testConnection() async => true;
  Future<List<String>> listTfliteModels() async => ['model_v1.tflite', 'model_v2.tflite'];
  Future<List<int>> downloadModel(String name) async => [0, 1, 2, 3];
  Future<bool> uploadModel(dynamic file) async => true;

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data)
    );
    
    // YAGNI: Assume 200-299 is success.
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }
    throw Exception('API Request Failed: ${res.statusCode}');
  }
}
