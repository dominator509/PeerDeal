import 'package:peerdeal_network/peerdeal_network.dart';
import 'package:test/test.dart';

void main() {
  test('accepts valid frames through the transport handler', () async {
    final handler = _RecordingTransportFrameHandler();
    final receiver = ValidatingTransportFrameReceiver(handler: handler);
    final frame = TransportFrame(
      sessionId: 'session_1',
      fromPeerId: 'peer_a',
      toPeerId: 'peer_b',
      sequence: 1,
      payload: <int>[1, 2, 3],
    );

    final result = await receiver.receive(frame);

    expect(result.accepted, isTrue);
    expect(result.reasonCode, 'OK_TRANSPORT_FRAME_RECEIVED');
    expect(handler.frames, <TransportFrame>[frame]);
  });

  test('rejects invalid frames before the handler sees them', () async {
    final handler = _RecordingTransportFrameHandler();
    final receiver = ValidatingTransportFrameReceiver(handler: handler);

    final result = await receiver.receive(
      TransportFrame(
        sessionId: 'session_1',
        fromPeerId: '',
        toPeerId: 'peer_b',
        sequence: -1,
        payload: <int>[],
      ),
    );

    expect(result.accepted, isFalse);
    expect(result.reasonCode, 'ERR_TRANSPORT_FRAME_REJECTED');
    expect(result.warnings, contains('ERR_TRANSPORT_FRAME_SENDER_REQUIRED'));
    expect(result.warnings, contains('ERR_TRANSPORT_FRAME_SEQUENCE_INVALID'));
    expect(result.warnings, contains('ERR_TRANSPORT_FRAME_PAYLOAD_REQUIRED'));
    expect(handler.frames, isEmpty);
  });

  test('fails closed when the transport handler throws', () async {
    final receiver = ValidatingTransportFrameReceiver(
      handler: _ThrowingTransportFrameHandler(),
    );

    final result = await receiver.receive(
      TransportFrame(
        sessionId: 'session_1',
        fromPeerId: 'peer_a',
        toPeerId: 'peer_b',
        sequence: 1,
        payload: <int>[1],
      ),
    );

    expect(result.accepted, isFalse);
    expect(result.reasonCode, 'ERR_TRANSPORT_FRAME_RECEIVE_FAILED');
    expect(result.warnings, ['transport_frame_handler_failed']);
  });
}

class _RecordingTransportFrameHandler implements TransportFrameHandler {
  final List<TransportFrame> frames = <TransportFrame>[];

  @override
  Future<void> handleFrame(TransportFrame frame) async {
    frames.add(frame);
  }
}

class _ThrowingTransportFrameHandler implements TransportFrameHandler {
  @override
  Future<void> handleFrame(TransportFrame frame) async {
    throw StateError('session handler unavailable');
  }
}
