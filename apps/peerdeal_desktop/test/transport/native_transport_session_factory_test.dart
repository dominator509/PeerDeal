import 'package:peerdeal_desktop/transport/native_transport_session_factory.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_network/peerdeal_network.dart';
import 'package:test/test.dart';

void main() {
  test('creates validated sender backed by native transport', () async {
    final bridge = _FakeNativeTransportBridge();
    final sender = NativeTransportSessionFactory(bridge: bridge).createSender();

    final result = await sender.send(_frame());

    expect(result.sent, isTrue);
    expect(bridge.sentFrames, hasLength(1));
    expect(bridge.sentFrames.single.senderPeerId, 'peer_a');
  });

  test(
    'factory sender rejects invalid frame before native transport',
    () async {
      final bridge = _FakeNativeTransportBridge();
      final sender = NativeTransportSessionFactory(
        bridge: bridge,
      ).createSender();

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
    },
  );

  test('creates native drain backed by validating receiver', () async {
    final handler = _RecordingTransportFrameHandler();
    final drain = NativeTransportSessionFactory(
      bridge: _FakeNativeTransportBridge(receiveFrames: [_nativeFrame()]),
    ).createDrain(handler: handler);

    final result = await drain.drain(sessionId: 'session_1', peerId: 'peer_b');

    expect(result.available, isTrue);
    expect(result.results.single.accepted, isTrue);
    expect(handler.frames.single.toPeerId, 'peer_b');
  });

  test('factory drain rejects invalid native frames', () async {
    final handler = _RecordingTransportFrameHandler();
    final drain = NativeTransportSessionFactory(
      bridge: _FakeNativeTransportBridge(
        receiveFrames: const <NativeTransportFrame>[
          NativeTransportFrame(
            sessionId: 'session_1',
            senderPeerId: '',
            recipientPeerId: 'peer_b',
            sequence: 1,
            payloadBytes: <int>[1],
          ),
        ],
      ),
    ).createDrain(handler: handler);

    final result = await drain.drain(sessionId: 'session_1', peerId: 'peer_b');

    expect(result.available, isTrue);
    expect(result.results.single.accepted, isFalse);
    expect(result.results.single.reasonCode, 'ERR_TRANSPORT_FRAME_REJECTED');
    expect(handler.frames, isEmpty);
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
    List<NativeTransportFrame> receiveFrames = const <NativeTransportFrame>[],
  }) : _receiveFrames = receiveFrames;

  final List<NativeTransportFrame> _receiveFrames;
  final List<NativeTransportFrame> sentFrames = <NativeTransportFrame>[];

  @override
  Future<NativeTransportCapability> getCapability() async {
    return const NativeTransportCapability.unavailable();
  }

  @override
  Future<NativeTransportReceiveSnapshot> receiveFrames({
    required String sessionId,
    required String peerId,
  }) async {
    return NativeTransportReceiveSnapshot(
      available: true,
      frames: _receiveFrames,
    );
  }

  @override
  Future<NativeTransportSendResult> sendFrame(
    NativeTransportFrame frame,
  ) async {
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
