import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _secretPrefix = 'ble_secret_';

  Future<void> saveDeviceSecret(String deviceIdentifier, String secret) async {
    await _storage.write(
      key: '$_secretPrefix$deviceIdentifier',
      value: secret,
    );
  }

  Future<String?> getDeviceSecret(String deviceIdentifier) async {
    return await _storage.read(key: '$_secretPrefix$deviceIdentifier');
  }

  Future<void> deleteDeviceSecret(String deviceIdentifier) async {
    await _storage.delete(key: '$_secretPrefix$deviceIdentifier');
  }
}
