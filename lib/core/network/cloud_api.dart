// ponytail: Ultra clean ApiClient matching latest Savia LoRaWAN & Cloud API spec
// ignore_for_file: unintended_html_in_doc_comment

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
      updateEndpoint('http', serverUrl, port ?? 3000);
    }
  }

  void updateEndpoint(String scheme, String hostOrUrl, int port) {
    String sanitized = hostOrUrl.trim();
    if (!sanitized.startsWith('http://') && !sanitized.startsWith('https://')) {
      sanitized = '$scheme://$sanitized';
    }
    try {
      final uri = Uri.parse(sanitized);
      final host = uri.host.isNotEmpty ? uri.host : 'localhost';
      final effectivePort = (port != 0) ? port : (uri.hasPort ? uri.port : 3000);
      baseUrl = '${uri.scheme}://$host:$effectivePort/api';
    } catch (_) {}
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (apiKey != null) 'Authorization': 'Bearer $apiKey',
      };

  // ==========================================
  // 1. READ ENDPOINTS
  // ==========================================

  /// GET /api/sync?deviceIdentifier=<ID>&since=<tsMs>
  Future<List<dynamic>> syncTelemetryPull(String deviceId, int sinceMs) async {
    final uri = Uri.parse('$baseUrl/sync').replace(queryParameters: {
      'deviceIdentifier': deviceId,
      'since': sinceMs.toString(),
    });
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 200) return jsonDecode(res.body)['records'] ?? [];
    throw Exception('Pull failed (${res.statusCode}): ${res.body}');
  }

  /// GET /api/picos (Aliases: GET /api/devices, GET /api/stations) -> returns list of registered stations
  Future<List<dynamic>> getRegisteredDevices() async {
    print('[CloudAPI Verbose] Starting Pico station discovery from Cloud server...');
    print('[CloudAPI Verbose] Target BaseURL: $baseUrl');

    final endpoints = ['$baseUrl/picos', '$baseUrl/devices', '$baseUrl/stations'];

    for (var ep in endpoints) {
      final uri = Uri.parse(ep);
      try {
        print('[CloudAPI Verbose] Sending GET request to $uri ...');
        final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 5));
        print('[CloudAPI Verbose] Response Status: ${res.statusCode}');
        print('[CloudAPI Verbose] Response Body: ${res.body}');
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          if (body is Map) return body['picos'] ?? body['devices'] ?? body['stations'] ?? body['records'] ?? [];
          if (body is List) return body;
        }
      } catch (e) {
        print('[CloudAPI Verbose] GET $uri failed: $e');
      }
    }

    print('[CloudAPI Verbose] Pico station discovery completed: No registered stations returned.');
    return [];
  }

  /// GET /api/station/status?deviceIdentifier=<ID>
  /// Returns { lat, lon, utcOffset, updatedAt, pendingDownlinks }
  Future<Map<String, dynamic>> getStationStatus(String deviceId) async {
    final uri = Uri.parse('$baseUrl/station/status').replace(queryParameters: {
      'deviceIdentifier': deviceId,
    });
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Get station status failed (${res.statusCode}): ${res.body}');
  }

  /// GET /api/predictions?deviceIdentifier=<ID>&since=<tsMs> (Section 1.4.2)
  Future<List<dynamic>> syncPredictionsPull(String deviceId, int sinceMs) async {
    final uri = Uri.parse('$baseUrl/predictions').replace(queryParameters: {
      'deviceIdentifier': deviceId,
      'since': sinceMs.toString(),
    });
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 200) return jsonDecode(res.body)['records'] ?? [];
    throw Exception('Prediction pull failed (${res.statusCode}): ${res.body}');
  }

  // ==========================================
  // 2. WRITE ENDPOINTS
  // ==========================================

  /// POST /api/sync -> Bulk telemetry records [{ deviceIdentifier, tsMs, value, depthCm }]
  Future<void> syncTelemetryPush(List<Map<String, dynamic>> records) async {
    final res = await http.post(
      Uri.parse('$baseUrl/sync'),
      headers: _headers,
      body: jsonEncode({'records': records}),
    );
    if (res.statusCode != 200) throw Exception('Push failed (${res.statusCode}): ${res.body}');
  }

  /// POST /api/predictions -> Bulk prediction records (Section 1.4.1)
  Future<void> syncPredictionsPush(List<Map<String, dynamic>> records) async {
    final res = await http.post(
      Uri.parse('$baseUrl/predictions'),
      headers: _headers,
      body: jsonEncode({'records': records}),
    );
    if (res.statusCode != 200) throw Exception('Prediction push failed (${res.statusCode}): ${res.body}');
  }

  /// POST /api/emulate/recommendation -> Triggers server-side recommendation emulation (Section 1.5)
  Future<Map<String, dynamic>> emulateCloudRecommendation(String deviceId, {bool useHistoricalDate = true}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/emulate/recommendation'),
      headers: _headers,
      body: jsonEncode({
        'deviceIdentifier': deviceId,
        'useHistoricalDate': useHistoricalDate,
      }),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Server-side emulation failed (${res.statusCode}): ${res.body}');
  }

  /// POST /api/station/update -> Update station metadata (name, lat, lon)
  Future<void> updateStationMetadata(String deviceId, {String? name, double? lat, double? lon}) async {
    final Map<String, dynamic> body = {'deviceIdentifier': deviceId};
    if (name != null) body['name'] = name;
    if (lat != null) {
      body['lat'] = lat;
      body['latitude'] = lat;
    }
    if (lon != null) {
      body['lon'] = lon;
      body['longitude'] = lon;
    }
    try {
      await http.post(
        Uri.parse('$baseUrl/station/update'),
        headers: _headers,
        body: jsonEncode(body),
      );
    } catch (_) {}
  }

  // ==========================================
  // 3. FILE SHARING SERVICE
  // ==========================================

  Future<List<String>> listFiles() async {
    final res = await http.get(Uri.parse('$baseUrl/files'), headers: _headers).timeout(const Duration(seconds: 4));
    if (res.statusCode == 200) return List<String>.from(jsonDecode(res.body)['files'] ?? []);
    throw Exception('List files failed (${res.statusCode}): ${res.body}');
  }

  Future<List<int>> downloadFile(String name) async {
    final uri = Uri.parse('$baseUrl/files/download').replace(queryParameters: {'name': name});
    final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 5));
    if (res.statusCode == 200) return res.bodyBytes;
    throw Exception('Download failed (${res.statusCode}): ${res.body}');
  }

  Future<void> uploadFile(String name, List<int> bytes) async {
    final uri = Uri.parse('$baseUrl/files/upload').replace(queryParameters: {'name': name});
    final res = await http.post(
      uri,
      headers: _headers..['Content-Type'] = 'application/octet-stream',
      body: bytes,
    ).timeout(const Duration(seconds: 5));
    if (res.statusCode != 200) throw Exception('Upload failed (${res.statusCode}): ${res.body}');
  }

  Future<void> deleteSharedFile(String name) async {
    final uri = Uri.parse('$baseUrl/files/delete').replace(queryParameters: {'name': name});
    final res = await http.post(uri, headers: _headers..['X-Confirm-Filename'] = name).timeout(const Duration(seconds: 4));
    if (res.statusCode != 200) throw Exception('Delete failed (${res.statusCode}): ${res.body}');
  }

  // ponytail: fast multi-endpoint ping test with strict 3s timeout per probe
  Future<bool> testConnection() async {
    final rootUrl = baseUrl.replaceAll(RegExp(r'/api$'), '');
    final pingEndpoints = [
      '$rootUrl/health',
      '$baseUrl/ping',
      '$baseUrl/picos',
      '$baseUrl/sync',
      '$baseUrl/devices',
    ];
    for (final ep in pingEndpoints) {
      try {
        final res = await http
            .get(Uri.parse(ep), headers: _headers)
            .timeout(const Duration(seconds: 3));
        if (res.statusCode >= 200 && res.statusCode < 300) return true;
      } catch (_) {}
    }
    return false;
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
