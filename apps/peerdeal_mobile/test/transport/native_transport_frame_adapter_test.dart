import 'dart:async';

import 'package:peerdeal_mobile/transport/native_transport_frame_adapter.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_network/peerdeal_network.dart';
import 'package:test/test.dart';

void main() {
  test('copies and freezes native frame drain collections', () {
    final results = <TransportFrameReceiveResult>[
      const TransportFrameReceiveResult.accepted(),
    ];
    final warnings = <String>['warning_1'];
    final result = NativeTransportFrameDrainResult(
      available: true,
      results: results,
      warnings: warnings,
    );

    results.clear();
    warnings.add('warning_2');
    expect(result.results, hasLength(1));
    expect(result.warnings, ['warning_1']);
    expect(() => result.results.clear(), throwsUnsupportedError);
    expect(() => result.warnings.add('warning_3'), throwsUnsupportedError);
  });

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

  test(
    'sink rejects invalid frames before native transport sees them',
    () async {
      final bridge = _FakeNativeTransportBridge();
      final sink = NativeTransportFrameSink(bridge: bridge);

      await expectLater(
        sink.sendFrame(
          const TransportFrame(
            sessionId: 'session_1',
            fromPeerId: 'peer_a',
            toPeerId: 'peer_a',
            sequence: 1,
            payload: <int>[1],
          ),
        ),
        throwsStateError,
      );

      expect(bridge.sentFrames, isEmpty);
    },
  );

  test(
    'sink rejects native identity violations before an injected bridge call',
    () async {
      final bridge = _FakeNativeTransportBridge();
      final sink = NativeTransportFrameSink(bridge: bridge);
      final invalidFrames = <TransportFrame>[
        TransportFrame(
          sessionId: 'session_${String.fromCharCode(1)}',
          fromPeerId: 'peer_a',
          toPeerId: 'peer_b',
          sequence: 1,
          payload: const <int>[1],
        ),
        TransportFrame(
          sessionId: 'session_1',
          fromPeerId: 'peer_${String.fromCharCode(0x85)}',
          toPeerId: 'peer_b',
          sequence: 1,
          payload: const <int>[1],
        ),
        TransportFrame(
          sessionId: 'session_1',
          fromPeerId: 'x' * 257,
          toPeerId: 'peer_b',
          sequence: 1,
          payload: const <int>[1],
        ),
      ];

      for (final frame in invalidFrames) {
        await expectLater(sink.sendFrame(frame), throwsStateError);
      }

      expect(bridge.sentFrames, isEmpty);
    },
  );

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

  test('does not deliver a late receive after cancellation', () async {
    final cancellation = Completer<void>();
    final receive = Completer<NativeTransportReceiveSnapshot>();
    final handler = _RecordingTransportFrameHandler();
    final drain = NativeTransportFrameDrain(
      bridge: _BlockingReceiveBridge(receive.future),
      receiver: ValidatingTransportFrameReceiver(handler: handler),
    );

    final result = drain.drain(
      sessionId: 'session_1',
      peerId: 'peer_b',
      cancellation: cancellation.future,
    );
    cancellation.complete();

    final cancelled = await result;
    expect(cancelled.available, isFalse);
    expect(cancelled.warnings, ['Native transport receive cancelled.']);

    receive.complete(
      NativeTransportReceiveSnapshot(
        available: true,
        frames: <NativeTransportFrame>[_nativeFrame()],
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(handler.frames, isEmpty);
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

  test('rejects invalid receive scope before native receive', () async {
    final bridge = _FakeNativeTransportBridge(receiveFrames: [_nativeFrame()]);
    final handler = _RecordingTransportFrameHandler();
    final drain = NativeTransportFrameDrain(
      bridge: bridge,
      receiver: ValidatingTransportFrameReceiver(handler: handler),
    );

    final result = await drain.drain(sessionId: 'session_1', peerId: ' peer_b');

    expect(result.available, isFalse);
    expect(result.results, isEmpty);
    expect(result.warnings, ['Native transport receive scope is invalid.']);
    expect(bridge.receiveLookups, 0);
    expect(handler.frames, isEmpty);
  });

  test(
    'rejects control-bearing and oversized receive scopes before native receive',
    () async {
      final bridge = _FakeNativeTransportBridge(
        receiveFrames: [_nativeFrame()],
      );
      final handler = _RecordingTransportFrameHandler();
      final drain = NativeTransportFrameDrain(
        bridge: bridge,
        receiver: ValidatingTransportFrameReceiver(handler: handler),
      );

      final invalidScopes = <List<String>>[
        <String>['session_${String.fromCharCode(1)}', 'peer_b'],
        <String>['session_1', 'peer_${String.fromCharCode(0x85)}'],
        <String>['x' * 257, 'peer_b'],
      ];
      for (final scopes in invalidScopes) {
        final result = await drain.drain(
          sessionId: scopes[0],
          peerId: scopes[1],
        );
        expect(result.available, isFalse);
        expect(result.results, isEmpty);
        expect(result.warnings, ['Native transport receive scope is invalid.']);
      }

      expect(bridge.receiveLookups, 0);
      expect(handler.frames, isEmpty);
    },
  );

  test('rejects invalid receive batch limit before native receive', () async {
    final bridge = _FakeNativeTransportBridge(receiveFrames: [_nativeFrame()]);
    final handler = _RecordingTransportFrameHandler();
    final drain = NativeTransportFrameDrain(
      bridge: bridge,
      receiver: ValidatingTransportFrameReceiver(handler: handler),
      maxFramesPerDrain: 0,
    );

    final result = await drain.drain(sessionId: 'session_1', peerId: 'peer_b');

    expect(result.available, isFalse);
    expect(result.results, isEmpty);
    expect(result.warnings, [
      'Native transport receive batch limit is invalid.',
    ]);
    expect(bridge.receiveLookups, 0);
    expect(handler.frames, isEmpty);
  });

  test(
    'bounds native receive frame batches before handlers see them',
    () async {
      final handler = _RecordingTransportFrameHandler();
      final drain = NativeTransportFrameDrain(
        bridge: _FakeNativeTransportBridge(
          receiveFrames: <NativeTransportFrame>[
            for (var index = 0; index < 5; index++)
              _nativeFrame(sequence: index + 1),
          ],
        ),
        receiver: ValidatingTransportFrameReceiver(handler: handler),
        maxFramesPerDrain: 3,
      );

      final result = await drain.drain(
        sessionId: 'session_1',
        peerId: 'peer_b',
      );

      expect(result.available, isTrue);
      expect(result.results, hasLength(3));
      expect(handler.frames.map((frame) => frame.sequence), <int>[1, 2, 3]);
      expect(result.warnings, [
        'Native transport receive batch limit reached.',
      ]);
    },
  );

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
    expect(result.warnings, ['Native transport reported a platform warning.']);
  });

  test('scrubs native receive warning detail while draining', () async {
    final drain = NativeTransportFrameDrain(
      bridge: _FakeNativeTransportBridge(
        receiveWarning: 'receive_failed: C:\\secret\\frames.log',
      ),
      receiver: ValidatingTransportFrameReceiver(
        handler: _RecordingTransportFrameHandler(),
      ),
    );

    final result = await drain.drain(sessionId: 'session_1', peerId: 'peer_b');

    expect(result.available, isFalse);
    expect(result.warnings, ['Native transport reported a platform warning.']);
    expect(result.warnings.single, isNot(contains('frames.log')));
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

NativeTransportFrame _nativeFrame({int sequence = 1}) {
  return NativeTransportFrame(
    sessionId: 'session_1',
    senderPeerId: 'peer_a',
    recipientPeerId: 'peer_b',
    sequence: sequence,
    payloadBytes: const <int>[1, 2, 3],
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
  int receiveLookups = 0;

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
    receiveLookups += 1;
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

class _BlockingReceiveBridge implements NativeTransportBridge {
  _BlockingReceiveBridge(this.receive);

  final Future<NativeTransportReceiveSnapshot> receive;

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
  }) => receive;

  @override
  Future<NativeTransportSendResult> sendFrame(
    NativeTransportFrame frame,
  ) async {
    return const NativeTransportSendResult(isSuccess: true);
  }
}
