import 'package:peerdeal_mobile/transport/native_transport_frame_adapter.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_network/peerdeal_network.dart';
import 'package:test/test.dart';

void main() {
  test('sends validated network frames through native transport', () async {
    final bridge = _FakeNativeTransportBridge();
    final sender = ValidatingTransportFrameSender(
      sink: NativeTransportFrameSink(bridge: bridge),
    );

    final result = await sender.send(_frame());

    expect(result.sent, isTrue);
    expect(bridge.sentFrames, hasLength(1));
    expect(bridge.sentFrames.single.senderPeerId, 'peer_a');
    expect(bridge.sentFrames.single.recipientPeerId, 'peer_b');
    expect(bridge.sentFrames.single.payloadBytes, [1, 2, 3]);
  });

  test('rejects invalid frames before native transport sees them', () async {
    final bridge = _FakeNativeTransportBridge();
    final sender = ValidatingTransportFrameSender(
      sink: NativeTransportFrameSink(bridge: bridge),
    );

    final result = await sender.send(
      const TransportFrame(
        sessionId: 'session_1',
        fromPeerId: 'peer_a',
        toPeerId: 'peer_a',
        sequence: 1,
        payload: <int>[1],
      ),
    );

    expect(result.sent, isFalse);
    expect(result.reasonCode, 'ERR_TRANSPORT_FRAME_REJECTED');
    expect(bridge.sentFrames, isEmpty);
  });

  test('converts native send failure into network send rejection', () async {
    final bridge = _FakeNativeTransportBridge(sendWarning: 'socket closed');
    final sender = ValidatingTransportFrameSender(
      sink: NativeTransportFrameSink(bridge: bridge),
    );

    final result = await sender.send(_frame());

    expect(result.sent, isFalse);
    expect(result.reasonCode, 'ERR_TRANSPORT_FRAME_SEND_FAILED');
    expect(result.warnings, ['transport_frame_sink_failed']);
  });

  test('drains native frames through validating network receiver', () async {
    final handler = _RecordingTransportFrameHandler();
    final drain = NativeTransportFrameDrain(
      bridge: _FakeNativeTransportBridge(receiveFrames: [_nativeFrame()]),
      receiver: ValidatingTransportFrameReceiver(handler: handler),
    );

    final result = await drain.drain(sessionId: 'session_1', peerId: 'peer_b');

    expect(result.available, isTrue);
    expect(result.results.single.accepted, isTrue);
    expect(handler.frames.single.fromPeerId, 'peer_a');
    expect(handler.frames.single.payload, [1, 2, 3]);
  });

  test('rejects invalid native frames through network receiver', () async {
    final handler = _RecordingTransportFrameHandler();
    final drain = NativeTransportFrameDrain(
      bridge: _FakeNativeTransportBridge(
        receiveFrames: const <NativeTransportFrame>[
          NativeTransportFrame(
            sessionId: 'session_1',
            senderPeerId: 'peer_a',
            recipientPeerId: 'peer_a',
            sequence: 1,
            payloadBytes: <int>[1],
          ),
        ],
      ),
      receiver: ValidatingTransportFrameReceiver(handler: handler),
    );

    final result = await drain.drain(sessionId: 'session_1', peerId: 'peer_a');

    expect(result.available, isTrue);
    expect(result.results.single.accepted, isFalse);
    expect(result.results.single.reasonCode, 'ERR_TRANSPORT_FRAME_REJECTED');
    expect(handler.frames, isEmpty);
  });

  test('fails closed when native receive is unavailable', () async {
    final drain = NativeTransportFrameDrain(
      bridge: _FakeNativeTransportBridge(receiveWarning: 'transport locked'),
      receiver: ValidatingTransportFrameReceiver(
        handler: _RecordingTransportFrameHandler(),
      ),
    );

    final result = await drain.drain(sessionId: 'session_1', peerId: 'peer_b');

    expect(result.available, isFalse);
    expect(result.results, isEmpty);
    expect(result.warnings, ['transport locked']);
  });
}

TransportFrame _frame() {
  return const TransportFrame(
    sessionId: 'session_1',
    fromPeerId: 'peer_a',
    toPeerId: 'peer_b',
    sequence: 1,
    payload: <int>[1, 2, 3],
  );
}

NativeTransportFrame _nativeFrame() {
  return const NativeTransportFrame(
    sessionId: 'session_1',
    senderPeerId: 'peer_a',
    recipientPeerId: 'peer_b',
    sequence: 1,
    payloadBytes: <int>[1, 2, 3],
  );
}

class _FakeNativeTransportBridge implements NativeTransportBridge {
  _FakeNativeTransportBridge({
    this.sendWarning,
    this.receiveWarning,
    List<NativeTransportFrame> receiveFrames = const <NativeTransportFrame>[],
  }) : _receiveFrames = receiveFrames;

  final String? sendWarning;
  final String? receiveWarning;
  final List<NativeTransportFrame> _receiveFrames;
  final List<NativeTransportFrame> sentFrames = <NativeTransportFrame>[];

  @override
  Future<NativeTransportCapability> getCapability() async {
    return const NativeTransportCapability(
      available: true,
      sendSupported: true,
      receiveSupported: true,
      maxPayloadBytes: 4096,
      notes: 'test',
    );
  }

  @override
  Future<NativeTransportReceiveSnapshot> receiveFrames({
    required String sessionId,
    required String peerId,
  }) async {
    if (receiveWarning != null) {
      return NativeTransportReceiveSnapshot.unavailable(
        warning: receiveWarning,
      );
    }
    return NativeTransportReceiveSnapshot(
      available: true,
      frames: _receiveFrames,
    );
  }

  @override
  Future<NativeTransportSendResult> sendFrame(
    NativeTransportFrame frame,
  ) async {
    if (sendWarning != null) {
      return NativeTransportSendResult.failure(warning: sendWarning);
    }
    sentFrames.add(frame);
    return const NativeTransportSendResult(isSuccess: true);
  }
}

class _RecordingTransportFrameHandler implements TransportFrameHandler {
  final List<TransportFrame> frames = <TransportFrame>[];

  @override
  Future<void> handleFrame(TransportFrame frame) async {
    frames.add(frame);
  }
}
