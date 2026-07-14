class TfmServerClient {
  final String serverUrl;
  final int port;
  final String apiKey;

  TfmServerClient({
    required this.serverUrl,
    required this.port,
    required this.apiKey,
  });

  Future<bool> testConnection() async => true;
  Future<List<String>> listTfliteModels() async => ['random_forest.dart'];
  Future<dynamic> downloadModel(String fileName) async => null;
  Future<bool> uploadModel(dynamic file) async => true;
  Future<bool> uploadDatabase(String realmPath) async => true;
}
