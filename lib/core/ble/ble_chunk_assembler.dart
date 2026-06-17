import 'dart:async';
import 'cbor_helper.dart';

class BleChunkAssembler {
  final Map<int, List<int>> _chunks = {};
  int _totalChunks = 0;
  bool _isAssembled = false;

  final _completedController = StreamController<List<int>>.broadcast();
  Stream<List<int>> get completedStream => _completedController.stream;

  void reset() {
    _chunks.clear();
    _totalChunks = 0;
    _isAssembled = false;
  }

  /// Processes an incoming raw chunk packet (bytes)
  void processChunkBytes(List<int> bytes) {
    if (_isAssembled) return;

    try {
      final decoded = CborHelper.decode(bytes);
      final map = CborHelper.asMap(decoded);
      if (map == null) {
        print('BleChunkAssembler Error: Decoded chunk is not a map!');
        return;
      }

      final String? op = map['op'] as String?;
      if (op != 'chunk') {
        print('BleChunkAssembler Error: Map is not a chunk operation (op: $op)');
        return;
      }

      final int s = map['s'] as int;       // sequence index
      final int t = map['t'] as int;       // total chunks count
      final bool eof = map['eof'] as bool; // true in last chunk
      
      final Object? payloadRaw = map['p'];
      if (payloadRaw == null) {
        print('BleChunkAssembler Error: Chunk payload p is missing!');
        return;
      }

      final List<int> p;
      if (payloadRaw is List) {
        p = List<int>.from(payloadRaw);
      } else {
        print('BleChunkAssembler Error: Chunk payload p is not a List!');
        return;
      }

      _totalChunks = t;
      _chunks[s] = p;

      // Update progress
      final double progress = _totalChunks > 0 ? _chunks.length / _totalChunks : 0.0;
      print('BleChunkAssembler: Received chunk $s/$t (progress: ${(progress * 100).toStringAsFixed(1)}%)');

      // Check if all chunks received
      if (_chunks.length == _totalChunks || eof) {
        // Double check we have all sequences from 0 to totalChunks - 1
        bool complete = true;
        for (int i = 0; i < _totalChunks; i++) {
          if (!_chunks.containsKey(i)) {
            complete = false;
            break;
          }
        }

        if (complete) {
          _isAssembled = true;
          
          // Assemble
          final List<int> fullPayload = [];
          for (int i = 0; i < _totalChunks; i++) {
            fullPayload.addAll(_chunks[i]!);
          }
          
          print('BleChunkAssembler: Successfully assembled $t chunks, total size ${fullPayload.length} bytes');
          _completedController.add(fullPayload);
        }
      }
    } catch (e) {
      print('BleChunkAssembler Error parsing chunk: $e');
    }
  }

  void dispose() {
    _completedController.close();
  }
}
