import 'package:peerdeal_network/peerdeal_network.dart';
import 'package:test/test.dart';

void main() {
  test('accepts a sendable transport frame', () {
    const validator = BasicTransportFrameValidator();

    final result = validator.validate(
      const TransportFrame(
        sessionId: 'session_1',
        fromPeerId: 'peer_a',
        toPeerId: 'peer_b',
        sequence: 1,
        payload: <int>[1, 2, 3],
      ),
    );

    expect(result.isValid, isTrue);
    expect(result.warnings, isEmpty);
  });

  test('rejects malformed frame identity and sequencing', () {
    const validator = BasicTransportFrameValidator();

    final result = validator.validate(
      const TransportFrame(
        sessionId: '',
        fromPeerId: '',
        toPeerId: '',
        sequence: 0,
        payload: <int>[],
      ),
    );

    expect(result.isValid, isFalse);
    expect(result.warnings, contains('ERR_TRANSPORT_FRAME_SESSION_REQUIRED'));
    expect(result.warnings, contains('ERR_TRANSPORT_FRAME_SENDER_REQUIRED'));
    expect(result.warnings, contains('ERR_TRANSPORT_FRAME_RECIPIENT_REQUIRED'));
    expect(result.warnings, contains('ERR_TRANSPORT_FRAME_SEQUENCE_INVALID'));
    expect(result.warnings, contains('ERR_TRANSPORT_FRAME_PAYLOAD_REQUIRED'));
  });

  test(
    'rejects self-send frames before transport implementation sees them',
    () {
      const validator = BasicTransportFrameValidator();

      final result = validator.validate(
        const TransportFrame(
          sessionId: 'session_1',
          fromPeerId: 'peer_a',
          toPeerId: 'peer_a',
          sequence: 1,
          payload: <int>[1],
        ),
      );

      expect(result.isValid, isFalse);
      expect(result.warnings, contains('ERR_TRANSPORT_FRAME_SELF_SEND'));
    },
  );

  test('rejects payloads over the configured transport frame limit', () {
    const validator = BasicTransportFrameValidator(maxPayloadBytes: 2);

    final result = validator.validate(
      const TransportFrame(
        sessionId: 'session_1',
        fromPeerId: 'peer_a',
        toPeerId: 'peer_b',
        sequence: 1,
        payload: <int>[1, 2, 3],
      ),
    );

    expect(result.isValid, isFalse);
    expect(result.warnings, contains('ERR_TRANSPORT_FRAME_PAYLOAD_TOO_LARGE'));
  });
}
