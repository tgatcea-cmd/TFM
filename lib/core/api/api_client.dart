// ponytail: Ultra clean ApiClient matching python server test suite exactly
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  String baseUrl;
  String? apiKey;

  ApiClient({
    this.baseUrl = "http://localhost:3000",
    String? serverUrl,
    int? port,
    this.apiKey,
  }) {
    if (serverUrl != null && serverUrl.isNotEmpty) {
      String sanitized = serverUrl.trim();
      if (!sanitized.startsWith('http://') && !sanitized.startsWith('https://')) {
        sanitized = 'http://$sanitized';
      }
      try {
        final uri = Uri.parse(sanitized);
        final host = uri.host.isNotEmpty ? uri.host : 'localhost';
        final effectivePort = (port != null && port != 0) ? port : (uri.hasPort ? uri.port : 3000);
        baseUrl = '${uri.scheme}://$host:$effectivePort/api';
      } catch (_) {}
    }
  }

  Map<String, String> get _headers => {
        if (apiKey != null) 'Authorization': 'Bearer $apiKey',
      };

  // ==========================================
  // 1. DEVICE TELEMETRY SYNC SERVICE
  // ==========================================

  /// Pushes telemetry records to POST /api/sync
  Future<void> syncTelemetryPush(List<Map<String, dynamic>> records) async {
    final res = await http.post(
      Uri.parse('$baseUrl/sync'),
      headers: _headers..['Content-Type'] = 'application/json',
      body: jsonEncode({'records': records}),
    );
    if (res.statusCode != 200) {
      throw Exception('Push failed (${res.statusCode}): ${res.body}');
    }
  }

  /// Pulls telemetry records from GET /api/sync
  Future<List<dynamic>> syncTelemetryPull(String deviceId, int sinceMs) async {
    final uri = Uri.parse('$baseUrl/sync').replace(queryParameters: {
      'deviceIdentifier': deviceId,
      'since': sinceMs.toString(),
    });
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 200) {
      return jsonDecode(res.body)['records'] ?? [];
    }
    throw Exception('Pull failed (${res.statusCode}): ${res.body}');
  }

  // ==========================================
  // 2. FILE SHARING SERVICE
  // ==========================================

  /// Lists shared files from GET /api/files
  Future<List<String>> listFiles() async {
    final res = await http.get(Uri.parse('$baseUrl/files'), headers: _headers);
    if (res.statusCode == 200) {
      return List<String>.from(jsonDecode(res.body)['files'] ?? []);
    }
    throw Exception('List files failed (${res.statusCode}): ${res.body}');
  }

  /// Downloads file from GET /api/files/download?name=<filename>
  Future<List<int>> downloadFile(String name) async {
    final uri = Uri.parse('$baseUrl/files/download').replace(queryParameters: {'name': name});
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 200) return res.bodyBytes;
    throw Exception('Download failed (${res.statusCode}): ${res.body}');
  }

  /// Uploads file to POST /api/files/upload?name=<filename>
  Future<void> uploadFile(String name, List<int> bytes) async {
    final uri = Uri.parse('$baseUrl/files/upload').replace(queryParameters: {'name': name});
    final res = await http.post(
      uri,
      headers: _headers..['Content-Type'] = 'application/octet-stream',
      body: bytes,
    );
    if (res.statusCode != 200) {
      throw Exception('Upload failed (${res.statusCode}): ${res.body}');
    }
  }

  /// Deletes file from POST /api/files/delete?name=<filename>
  Future<void> deleteSharedFile(String name) async {
    final uri = Uri.parse('$baseUrl/files/delete').replace(queryParameters: {'name': name});
    final res = await http.post(
      uri, 
      headers: _headers..['X-Confirm-Filename'] = name,
    );
    if (res.statusCode != 200) {
      throw Exception('Delete failed (${res.statusCode}): ${res.body}');
    }
  }

  // ==========================================
  // LEGACY COMPATIBILITY STUBS
  // ==========================================

  Future<bool> testConnection() async {
    try {
      await listFiles();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<String>> listTfliteModels() async {
    try {
      final files = await listFiles();
      return files.where((f) => f.endsWith('.tflite')).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<int>> downloadModel(String name) => downloadFile(name);
  Future<bool> uploadModel(dynamic fileBytesOrPath) async => true;
}
