import 'package:cbor/cbor.dart';

class CborHelper {
  /// Encodes a Dart Map/List/Object to CBOR bytes.
  static List<int> encode(Object? object) {
    return cbor.encode(CborValue(object));
  }

  /// Decodes CBOR bytes into a Dart Map/List/Object.
  static Object? decode(List<int> bytes) {
    if (bytes.isEmpty) return null;
    final decoded = cbor.decode(bytes);
    return decoded.toObject();
  }

  /// Helper to safely cast a decoded object to a `Map<String, dynamic>`
  static Map<String, dynamic>? asMap(Object? object) {
    if (object is Map) {
      return object.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }
}
