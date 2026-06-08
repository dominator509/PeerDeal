import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_network/peerdeal_network.dart';

class NativeTransportFrameSink implements TransportFrameSink {
  const NativeTransportFrameSink({required NativeTransportBridge bridge})
    : _bridge = bridge;

  final NativeTransportBridge _bridge;

  @override
  Future<void> sendFrame(TransportFrame frame) async {
    final result = await _bridge.sendFrame(_toNativeFrame(frame));
    if (!result.isSuccess) {
      throw StateError(result.warning ?? 'Native transport send failed.');
    }
  }
}

class NativeTransportFrameDrain {
  const NativeTransportFrameDrain({
    required NativeTransportBridge bridge,
    required TransportFrameReceiver receiver,
  }) : _bridge = bridge,
       _receiver = receiver;

  final NativeTransportBridge _bridge;
  final TransportFrameReceiver _receiver;

  Future<NativeTransportFrameDrainResult> drain({
    required String sessionId,
    required String peerId,
  }) async {
    final NativeTransportReceiveSnapshot snapshot;
    try {
      snapshot = await _bridge.receiveFrames(
        sessionId: sessionId,
        peerId: peerId,
      );
    } on Object {
      return const NativeTransportFrameDrainResult.unavailable(
        warnings: <String>['Native transport receive failed.'],
      );
    }

    if (!snapshot.available) {
      return NativeTransportFrameDrainResult.unavailable(
        warnings: <String>[
          snapshot.warning ?? 'Native transport receive unavailable.',
        ],
      );
    }

    final results = <TransportFrameReceiveResult>[];
    for (final frame in snapshot.frames) {
      try {
        results.add(await _receiver.receive(_fromNativeFrame(frame)));
      } on Object {
        results.add(
          const TransportFrameReceiveResult.rejected(
            reasonCode: 'ERR_NATIVE_TRANSPORT_FRAME_RECEIVE_FAILED',
            warnings: <String>['Native transport frame receive failed.'],
          ),
        );
      }
    }

    return NativeTransportFrameDrainResult(
      available: true,
      results: List<TransportFrameReceiveResult>.unmodifiable(results),
      warnings: snapshot.warning == null
          ? const <String>[]
          : <String>[snapshot.warning!],
    );
  }
}

class NativeTransportFrameDrainResult {
  const NativeTransportFrameDrainResult({
    required this.available,
    required this.results,
    this.warnings = const <String>[],
  });

  const NativeTransportFrameDrainResult.unavailable({
    this.warnings = const <String>[],
  }) : available = false,
       results = const <TransportFrameReceiveResult>[];

  final bool available;
  final List<TransportFrameReceiveResult> results;
  final List<String> warnings;
}

NativeTransportFrame _toNativeFrame(TransportFrame frame) {
  return NativeTransportFrame(
    sessionId: frame.sessionId,
    senderPeerId: frame.fromPeerId,
    recipientPeerId: frame.toPeerId,
    sequence: frame.sequence,
    payloadBytes: frame.payload,
  );
}

TransportFrame _fromNativeFrame(NativeTransportFrame frame) {
  return TransportFrame(
    sessionId: frame.sessionId,
    fromPeerId: frame.senderPeerId,
    toPeerId: frame.recipientPeerId,
    sequence: frame.sequence,
    payload: frame.payloadBytes,
  );
}
