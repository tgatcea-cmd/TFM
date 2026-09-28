# 1. Overview Section
**Name:** Network Core  
**Description:** HTTP client wrapper for communicating with the Cloud API, handling endpoint configuration, authentication, and structured requests for telemetry, predictions, and file sharing.  
**Location:** `lib/core/network`  
**Language:** Dart  
**Purpose:** Provide communication services between the client application and the Cloud API for data synchronization (telemetry and predictions), device metadata updates, file sharing, and model management.

# 2. Code Elements Section

## Class: `ApiClient`
**Description:** HTTP client wrapper for communicating with the Cloud API. Handles endpoint configuration, authentication, and structured requests for telemetry, predictions, and file sharing.  
**Location:** `lib/core/network/cloud_api.dart`  
**Dependencies:** `http` (`package:http/http.dart`), `dart:convert`  

### Properties
- `String baseUrl`: The base URL of the Cloud API.
- `String? apiKey`: The optional API key for authentication.
- `Map<String, String> _headers` (getter): Returns standard request headers including Content-Type and Authorization.

### Methods
- `ApiClient({String baseUrl = "http://localhost:3000/api", String? serverUrl, int? port, String? apiKey})`
  - **Description:** Initializes the API client and optionally configures the endpoint.
  
- `void updateEndpoint(String scheme, String hostOrUrl, int port)`
  - **Description:** Updates the `baseUrl` configuration based on the provided scheme, host, and port.

- `Future<List<dynamic>> syncTelemetryPull(String deviceId, int sinceMs)`
  - **Description:** Pulls telemetry data for a specific device from the server logged after a specific timestamp.
  
- `Future<List<dynamic>> getRegisteredDevices()`
  - **Description:** Retrieves the list of all registered stations/devices from the cloud server.

- `Future<Map<String, dynamic>> getStationStatus(String deviceId)`
  - **Description:** Retrieves the current status and metadata of a specific station.

- `Future<List<dynamic>> syncPredictionsPull(String deviceId, int sinceMs)`
  - **Description:** Pulls prediction records for a specific device from the server after a given timestamp.

- `Future<void> syncTelemetryPush(List<Map<String, dynamic>> records)`
  - **Description:** Pushes a batch of telemetry records to the cloud server.

- `Future<void> syncPredictionsPush(List<Map<String, dynamic>> records)`
  - **Description:** Pushes a batch of prediction records to the cloud server.

- `Future<Map<String, dynamic>> emulateCloudRecommendation(String deviceId, {bool useHistoricalDate = true})`
  - **Description:** Triggers a server-side emulation for recommendations.

- `Future<void> updateStationMetadata(String deviceId, {String? name, double? lat, double? lon})`
  - **Description:** Updates metadata for a specific station on the cloud server.

- `Future<List<String>> listFiles()`
  - **Description:** Retrieves a list of available files from the file sharing service.

- `Future<List<int>> downloadFile(String name)`
  - **Description:** Downloads a specific file from the server as bytes.

- `Future<void> uploadFile(String name, List<int> bytes)`
  - **Description:** Uploads a file to the server.

- `Future<void> deleteSharedFile(String name)`
  - **Description:** Deletes a specified shared file on the server.

- `Future<bool> testConnection()`
  - **Description:** Performs a fast multi-endpoint ping test to verify server connectivity.

- `Future<List<String>> listTfliteModels()`
  - **Description:** Returns a list of TFLite models available on the server.

- `Future<List<int>> downloadModel(String name)`
  - **Description:** Alias for `downloadFile` specifically for downloading model files.

- `Future<bool> uploadModel(dynamic fileBytesOrPath)`
  - **Description:** Uploads a model file.

- `Future<List<Map<String, dynamic>>> getAvailableRfModels()`
  - **Description:** Retrieves a catalog of available RF models from multiple endpoints.

- `Future<String> downloadRfModel(String modelId)`
  - **Description:** Downloads the payload for a specific RF model.

# 3. Dependencies Section
**Internal Dependencies:**
- None inside the `lib/core/network` package itself.

**External Dependencies:**
- `package:http/http.dart`: Used for making HTTP GET, POST requests and handling network timeouts.
- `dart:convert`: Used to serialize and deserialize JSON payloads for HTTP requests and responses.

# 4. Relationships Section
- The application uses `ApiClient` as the central gateway for all interactions with the Cloud API backend.
- `ApiClient` establishes network boundaries, mapping complex backend JSON responses into Dart primitives (Lists, Maps) via `dart:convert`.
- Error handling inside `ApiClient` throws exceptions that must be handled by the caller services in the application logic.
