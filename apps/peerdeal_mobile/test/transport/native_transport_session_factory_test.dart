import 'package:peerdeal_mobile/transport/native_transport_session_factory.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_network/peerdeal_network.dart';
import 'package:test/test.dart';

void main() {
  test(
    'loads available session only when native transport supports it',
    () async {
      final bridge = _FakeNativeTransportBridge(
        capability: const NativeTransportCapability(
          available: true,
          sendSupported: true,
          receiveSupported: true,
          maxPayloadBytes: 4096,
          notes: 'native-ready',
        ),
        receiveFrames: [_nativeFrame()],
      );
      final handler = _RecordingTransportFrameHandler();

      final result = await NativeTransportSessionFactory(
        bridge: bridge,
      ).loadSession(handler: handler);

      expect(result.available, isTrue);
      expect(result.session?.maxPayloadBytes, 4096);
      expect(result.session?.nativeNotes, 'native-ready');

      final send = await result.session!.sender.send(_frame());
      final receive = await result.session!.drain.drain(
        sessionId: 'session_1',
        peerId: 'peer_b',
      );

      expect(send.sent, isTrue);
      expect(receive.available, isTrue);
      expect(handler.frames.single.fromPeerId, 'peer_a');
    },
  );

  test(
    'loadSession fails closed when native transport is unsupported',
    () async {
      final result = await NativeTransportSessionFactory(
        bridge: _FakeNativeTransportBridge(
          capability: const NativeTransportCapability.unavailable(
            warning: 'transport disabled',
          ),
        ),
      ).loadSession(handler: _RecordingTransportFrameHandler());

      expect(result.available, isFalse);
      expect(result.session, isNull);
      expect(result.warnings, ['transport disabled']);
    },
  );

  test('loadSession fails closed when capability lookup throws', () async {
    final result = await NativeTransportSessionFactory(
      bridge: _ThrowingCapabilityTransportBridge(),
    ).loadSession(handler: _RecordingTransportFrameHandler());

    expect(result.available, isFalse);
    expect(result.session, isNull);
    expect(result.warnings, [
      'Native transport capability could not be loaded.',
    ]);
  });

  test(
    'loadSession rejects native payload limits above app validator',
    () async {
      final result = await NativeTransportSessionFactory(
        bridge: _FakeNativeTransportBridge(
          capability: const NativeTransportCapability(
            available: true,
            sendSupported: true,
            receiveSupported: true,
            maxPayloadBytes: 4096,
            notes: 'native-too-large',
          ),
        ),
        maxPayloadBytes: 1024,
      ).loadSession(handler: _RecordingTransportFrameHandler());

      expect(result.available, isFalse);
      expect(result.session, isNull);
      expect(result.warnings, <String>[
        'Native transport payload limit exceeds app validator limit.',
      ]);
    },
  );

  test('loadSession rejects invalid native payload limits', () async {
    final result = await NativeTransportSessionFactory(
      bridge: _FakeNativeTransportBridge(
        capability: const NativeTransportCapability(
          available: true,
          sendSupported: true,
          receiveSupported: true,
          maxPayloadBytes: 0,
          notes: 'native-invalid',
        ),
      ),
    ).loadSession(handler: _RecordingTransportFrameHandler());

    expect(result.available, isFalse);
    expect(result.session, isNull);
    expect(result.warnings, <String>[
      'Native transport payload limit is invalid.',
    ]);
  });

  test('creates validated sender backed by native transport', () async {
    final bridge = _FakeNativeTransportBridge();
    final sender = NativeTransportSessionFactory(bridge: bridge).createSender();

    final result = await sender.send(_frame());

    expect(result.sent, isTrue);
    expect(bridge.sentFrames, hasLength(1));
    expect(bridge.sentFrames.single.senderPeerId, 'peer_a');
  });

  test('factory sender applies configured app payload limit', () async {
    final bridge = _FakeNativeTransportBridge();
    final sender = NativeTransportSessionFactory(
      bridge: bridge,
      maxPayloadBytes: 2,
    ).createSender();

    final result = await sender.send(_frame());

    expect(result.sent, isFalse);
    expect(result.reasonCode, 'ERR_TRANSPORT_FRAME_REJECTED');
    expect(result.warnings, contains('ERR_TRANSPORT_FRAME_PAYLOAD_TOO_LARGE'));
    expect(bridge.sentFrames, isEmpty);
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
    this.capability = const NativeTransportCapability(
      available: true,
      sendSupported: true,
      receiveSupported: true,
      maxPayloadBytes: 4096,
      notes: 'test',
    ),
    List<NativeTransportFrame> receiveFrames = const <NativeTransportFrame>[],
  }) : _receiveFrames = receiveFrames;

  final NativeTransportCapability capability;
  final List<NativeTransportFrame> _receiveFrames;
  final List<NativeTransportFrame> sentFrames = <NativeTransportFrame>[];

  @override
  Future<NativeTransportCapability> getCapability() async {
    return capability;
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

class _ThrowingCapabilityTransportBridge implements NativeTransportBridge {
  @override
  Future<NativeTransportCapability> getCapability() async {
    throw StateError('capability failed');
  }

  @override
  Future<NativeTransportReceiveSnapshot> receiveFrames({
    required String sessionId,
    required String peerId,
  }) async {
    return const NativeTransportReceiveSnapshot.unavailable();
  }

  @override
  Future<NativeTransportSendResult> sendFrame(
    NativeTransportFrame frame,
  ) async {
    return const NativeTransportSendResult.failure(warning: 'unavailable');
  }
}

class _RecordingTransportFrameHandler implements TransportFrameHandler {
  final List<TransportFrame> frames = <TransportFrame>[];

  @override
  Future<void> handleFrame(TransportFrame frame) async {
    frames.add(frame);
  }
}
