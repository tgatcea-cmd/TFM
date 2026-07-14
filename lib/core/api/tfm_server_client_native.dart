import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class TfmServerClient {
  final String serverUrl;
  final int port;
  final String apiKey;

  TfmServerClient({
    required this.serverUrl,
    required this.port,
    required this.apiKey,
  });

  String get _baseUrl => "$serverUrl:$port";

  Map<String, String> _headers([String contentType = 'application/json']) {
    final headers = {
      'Content-Type': contentType,
    };
    if (apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
    }
    return headers;
  }

  Future<bool> testConnection() async {
    try {
      final url = Uri.parse("$_baseUrl/api/files");
      final response = await http.get(url, headers: _headers()).timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<String>> listTfliteModels() async {
    try {
      final url = Uri.parse("$_baseUrl/api/files");
      final response = await http.get(url, headers: _headers()).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> files = data['files'] ?? [];
        return files.map((f) => f.toString()).where((f) => f.endsWith('.dart')).toList();
      }
    } catch (e) {
      print('TfmServerClient listDartModels error: $e');
    }
    return [];
  }

  Future<File?> downloadModel(String fileName) async {
    try {
      final url = Uri.parse("$_baseUrl/api/files/download?name=$fileName");
      final response = await http.get(url, headers: _headers('application/octet-stream')).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File(p.join(dir.path, fileName));
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
    } catch (e) {
      print('TfmServerClient downloadModel error: $e');
    }
    return null;
  }

  Future<bool> uploadModel(File file) async {
    try {
      final name = p.basename(file.path);
      final url = Uri.parse("$_baseUrl/api/files/upload?name=$name");
      final bytes = await file.readAsBytes();
      final response = await http.post(
        url,
        headers: _headers('application/octet-stream'),
        body: bytes,
      ).timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      print('TfmServerClient uploadModel error: $e');
      return false;
    }
  }

  Future<bool> uploadDatabase(String realmPath) async {
    try {
      final file = File(realmPath);
      if (!await file.exists()) {
        print('TfmServerClient: Realm file does not exist at $realmPath');
        return false;
      }
      final url = Uri.parse("$_baseUrl/api/database/upload");
      final bytes = await file.readAsBytes();
      final response = await http.post(
        url,
        headers: _headers('application/octet-stream'),
        body: bytes,
      ).timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      print('TfmServerClient uploadDatabase error: $e');
      return false;
    }
  }
}
