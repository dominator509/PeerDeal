import 'package:peerdeal_network/peerdeal_network.dart';
import 'package:test/test.dart';

void main() {
  test('sends valid frames through the transport sink', () async {
    final sink = _RecordingTransportFrameSink();
    final sender = ValidatingTransportFrameSender(sink: sink);
    const frame = TransportFrame(
      sessionId: 'session_1',
      fromPeerId: 'peer_a',
      toPeerId: 'peer_b',
      sequence: 1,
      payload: <int>[1, 2, 3],
    );

    final result = await sender.send(frame);

    expect(result.sent, isTrue);
    expect(result.reasonCode, 'OK_TRANSPORT_FRAME_SENT');
    expect(sink.frames, <TransportFrame>[frame]);
  });

  test('rejects invalid frames before the sink sees them', () async {
    final sink = _RecordingTransportFrameSink();
    final sender = ValidatingTransportFrameSender(sink: sink);

    final result = await sender.send(
      const TransportFrame(
        sessionId: '',
        fromPeerId: 'peer_a',
        toPeerId: 'peer_a',
        sequence: 0,
        payload: <int>[],
      ),
    );

    expect(result.sent, isFalse);
    expect(result.reasonCode, 'ERR_TRANSPORT_FRAME_REJECTED');
    expect(result.warnings, contains('ERR_TRANSPORT_FRAME_SESSION_REQUIRED'));
    expect(result.warnings, contains('ERR_TRANSPORT_FRAME_SELF_SEND'));
    expect(result.warnings, contains('ERR_TRANSPORT_FRAME_SEQUENCE_INVALID'));
    expect(result.warnings, contains('ERR_TRANSPORT_FRAME_PAYLOAD_REQUIRED'));
    expect(sink.frames, isEmpty);
  });

  test('fails closed when the transport sink throws', () async {
    final sender = ValidatingTransportFrameSender(
      sink: _ThrowingTransportFrameSink(),
    );

    final result = await sender.send(
      const TransportFrame(
        sessionId: 'session_1',
        fromPeerId: 'peer_a',
        toPeerId: 'peer_b',
        sequence: 1,
        payload: <int>[1],
      ),
    );

    expect(result.sent, isFalse);
    expect(result.reasonCode, 'ERR_TRANSPORT_FRAME_SEND_FAILED');
    expect(result.warnings, ['transport_frame_sink_failed']);
  });
}

class _RecordingTransportFrameSink implements TransportFrameSink {
  final List<TransportFrame> frames = <TransportFrame>[];

  @override
  Future<void> sendFrame(TransportFrame frame) async {
    frames.add(frame);
  }
}

class _ThrowingTransportFrameSink implements TransportFrameSink {
  @override
  Future<void> sendFrame(TransportFrame frame) async {
    throw StateError('transport unavailable');
  }
}
