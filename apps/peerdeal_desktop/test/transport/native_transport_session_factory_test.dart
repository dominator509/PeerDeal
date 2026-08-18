import 'package:peerdeal_desktop/transport/native_transport_session_factory.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_network/peerdeal_network.dart';
import 'package:test/test.dart';

void main() {
  test('copies and freezes native session load warnings', () {
    final warnings = <String>['warning_1'];
    final result = NativeTransportSessionLoadResult.unavailable(
      warnings: warnings,
    );

    warnings.add('warning_2');
    expect(result.warnings, ['warning_1']);
    expect(() => result.warnings.add('warning_3'), throwsUnsupportedError);
  });

  test('bounds and scrubs direct native session load warnings', () {
    final result = NativeTransportSessionLoadResult.unavailable(
      warnings: <String>[
        'warning_1',
        ' warning_2',
        'line\n${String.fromCharCode(0x85)}feed',
        'warning_4',
        'warning_5',
      ],
    );

    expect(result.warnings, [
      'warning_1',
      'Native transport session warning unavailable.',
      'Native transport session warning unavailable.',
      'Native transport session warnings truncated.',
    ]);
  });

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
    'loaded session enforces the native payload ceiling for send and receive',
    () async {
      final bridge = _FakeNativeTransportBridge(
        capability: const NativeTransportCapability(
          available: true,
          sendSupported: true,
          receiveSupported: true,
          maxPayloadBytes: 2,
          notes: 'native-ready',
        ),
        receiveFrames: [_nativeFrame()],
      );
      final handler = _RecordingTransportFrameHandler();
      final loaded = await NativeTransportSessionFactory(
        bridge: bridge,
      ).loadSession(handler: handler);

      final send = await loaded.session!.sender.send(_frame());
      final receive = await loaded.session!.drain.drain(
        sessionId: 'session_1',
        peerId: 'peer_b',
      );

      expect(send.sent, isFalse);
      expect(send.reasonCode, 'ERR_TRANSPORT_FRAME_REJECTED');
      expect(send.warnings, contains('ERR_TRANSPORT_FRAME_PAYLOAD_TOO_LARGE'));
      expect(receive.available, isTrue);
      expect(receive.results.single.accepted, isFalse);
      expect(receive.results.single.reasonCode, 'ERR_TRANSPORT_FRAME_REJECTED');
      expect(
        receive.results.single.warnings,
        contains('ERR_TRANSPORT_FRAME_PAYLOAD_TOO_LARGE'),
      );
      expect(bridge.sentFrames, isEmpty);
      expect(handler.frames, isEmpty);
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
      expect(result.warnings, [
        'Native transport reported a platform warning.',
      ]);
    },
  );

  test('loadSession scrubs native warning and note diagnostics', () async {
    final result = await NativeTransportSessionFactory(
      bridge: _FakeNativeTransportBridge(
        capability: NativeTransportCapability(
          available: true,
          sendSupported: true,
          receiveSupported: true,
          maxPayloadBytes: 4096,
          notes:
              '${'native '.padRight(120, 'x')}\n${String.fromCharCode(0x85)}secret',
          warning: 'transport_error: C:\\secret\\transport.log',
        ),
      ),
    ).loadSession(handler: _RecordingTransportFrameHandler());

    expect(result.available, isTrue);
    expect(result.warnings, ['Native transport reported a platform warning.']);
    expect(result.warnings.single, isNot(contains('transport.log')));
    expect(result.session!.nativeNotes, isNot(contains('\n')));
    expect(result.session!.nativeNotes.length, lessThanOrEqualTo(96));
  });

  test('loadSession scrubs sensitive native notes', () async {
    final result = await NativeTransportSessionFactory(
      bridge: _FakeNativeTransportBridge(
        capability: const NativeTransportCapability(
          available: true,
          sendSupported: true,
          receiveSupported: true,
          maxPayloadBytes: 4096,
          notes: r'transport token C:\secret\transport.log',
        ),
      ),
    ).loadSession(handler: _RecordingTransportFrameHandler());

    expect(result.available, isTrue);
    expect(result.session!.nativeNotes, 'unavailable');
    expect(result.session!.nativeNotes, isNot(contains('token')));
    expect(result.session!.nativeNotes, isNot(contains('secret')));
  });

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

  test(
    'loadSession rejects invalid app payload limits before native lookup',
    () async {
      final bridge = _FakeNativeTransportBridge();

      final result = await NativeTransportSessionFactory(
        bridge: bridge,
        maxPayloadBytes: 0,
      ).loadSession(handler: _RecordingTransportFrameHandler());

      expect(result.available, isFalse);
      expect(result.session, isNull);
      expect(result.warnings, <String>[
        'App transport payload limit is invalid.',
      ]);
      expect(bridge.capabilityLookups, 0);
    },
  );

  test(
    'rejects app payload limits above the native contract before native lookup',
    () async {
      final bridge = _FakeNativeTransportBridge();
      final factory = NativeTransportSessionFactory(
        bridge: bridge,
        maxPayloadBytes: NativeBridgePayloadLimits.maxTransportPayloadBytes + 1,
      );

      final loaded = await factory.loadSession(
        handler: _RecordingTransportFrameHandler(),
      );
      expect(loaded.available, isFalse);
      expect(loaded.warnings, <String>[
        'App transport payload limit is invalid.',
      ]);
      expect(bridge.capabilityLookups, 0);

      final send = await factory.createSender().send(_frame());
      expect(send.sent, isFalse);
      expect(send.reasonCode, 'ERR_TRANSPORT_UNAVAILABLE');
      expect(bridge.sentFrames, isEmpty);

      final drain = await factory
          .createDrain(handler: _RecordingTransportFrameHandler())
          .drain(sessionId: 'session_1', peerId: 'peer_b');
      expect(drain.available, isFalse);
      expect(drain.warnings, <String>[
        'App transport payload limit is invalid.',
      ]);
      expect(bridge.receiveLookups, 0);
    },
  );

  test(
    'rejects a native capability above the locked transport ceiling',
    () async {
      final bridge = _FakeNativeTransportBridge(
        capability: const NativeTransportCapability(
          available: true,
          sendSupported: true,
          receiveSupported: true,
          maxPayloadBytes:
              NativeBridgePayloadLimits.maxTransportPayloadBytes + 1,
          notes: 'native-invalid',
        ),
      );

      final result = await NativeTransportSessionFactory(
        bridge: bridge,
      ).loadSession(handler: _RecordingTransportFrameHandler());

      expect(result.available, isFalse);
      expect(result.warnings, <String>[
        'Native transport payload limit is invalid.',
      ]);
    },
  );

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
    'factory sender rejects invalid app payload limit before native transport',
    () async {
      final bridge = _FakeNativeTransportBridge();
      final sender = NativeTransportSessionFactory(
        bridge: bridge,
        maxPayloadBytes: 0,
      ).createSender();

      final result = await sender.send(_frame());

      expect(result.sent, isFalse);
      expect(result.reasonCode, 'ERR_TRANSPORT_UNAVAILABLE');
      expect(result.warnings, <String>[
        'App transport payload limit is invalid.',
      ]);
      expect(bridge.sentFrames, isEmpty);
    },
  );

  test(
    'factory sender rejects invalid frame before native transport',
    () async {
      final bridge = _FakeNativeTransportBridge();
      final sender = NativeTransportSessionFactory(
        bridge: bridge,
      ).createSender();

      final result = await sender.send(
        TransportFrame(
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

  test('creates a scoped app transport source from a loaded session', () async {
    final handler = _RecordingTransportFrameHandler();
    final loaded = await NativeTransportSessionFactory(
      bridge: _FakeNativeTransportBridge(receiveFrames: [_nativeFrame()]),
    ).loadSession(handler: handler);

    final source = loaded.session!.createSource(
      sessionId: 'session_1',
      peerId: 'peer_b',
      pollInterval: const Duration(milliseconds: 100),
    );
    final result = await source.pollNow();

    expect(result.available, isTrue);
    expect(result.acceptedFrameCount, 1);
    expect(handler.frames.single.toPeerId, 'peer_b');
  });

  test('factory drain rejects invalid native frames', () async {
    final handler = _RecordingTransportFrameHandler();
    final drain = NativeTransportSessionFactory(
      bridge: _FakeNativeTransportBridge(
        receiveFrames: <NativeTransportFrame>[
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

  test(
    'factory drain rejects invalid app payload limit before native receive',
    () async {
      final bridge = _FakeNativeTransportBridge(
        receiveFrames: [_nativeFrame()],
      );
      final handler = _RecordingTransportFrameHandler();
      final drain = NativeTransportSessionFactory(
        bridge: bridge,
        maxPayloadBytes: 0,
      ).createDrain(handler: handler);

      final result = await drain.drain(
        sessionId: 'session_1',
        peerId: 'peer_b',
      );

      expect(result.available, isFalse);
      expect(result.warnings, <String>[
        'App transport payload limit is invalid.',
      ]);
      expect(bridge.receiveLookups, 0);
      expect(handler.frames, isEmpty);
    },
  );
}

TransportFrame _frame() {
  return TransportFrame(
    sessionId: 'session_1',
    fromPeerId: 'peer_a',
    toPeerId: 'peer_b',
    sequence: 1,
    payload: <int>[1, 2, 3],
  );
}

NativeTransportFrame _nativeFrame() {
  return NativeTransportFrame(
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
  int capabilityLookups = 0;
  int receiveLookups = 0;

  @override
  Future<NativeTransportCapability> getCapability() async {
    capabilityLookups += 1;
    return capability;
  }

  @override
  Future<NativeTransportReceiveSnapshot> receiveFrames({
    required String sessionId,
    required String peerId,
  }) async {
    receiveLookups += 1;
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
