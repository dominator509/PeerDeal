import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:test/test.dart';

void main() {
  test('authenticates and round-trips a bounded session payload', () {
    final authenticator = _authenticator();
    final input = _input();

    final encoded = SessionAuthenticatedPayloadCodec.encode(
      input: input,
      authenticator: authenticator,
    );
    final decoded = SessionAuthenticatedPayloadCodec.decode(
      encoded: encoded,
      sessionId: input.sessionId,
      senderPeerId: input.senderPeerId,
      recipientPeerId: input.recipientPeerId,
      sequence: input.sequence,
      authenticator: authenticator,
    );

    expect(decoded, input.payload);
    expect(encoded.length, input.payload.length + 6 + authenticator.tagLength);
  });

  test('binds the tag to scope, sequence, and payload', () {
    final authenticator = _authenticator();
    final input = _input();
    final encoded = SessionAuthenticatedPayloadCodec.encode(
      input: input,
      authenticator: authenticator,
    );

    for (final changed in <SessionAuthenticationInput>[
      SessionAuthenticationInput(
        sessionId: 'session_other',
        senderPeerId: input.senderPeerId,
        recipientPeerId: input.recipientPeerId,
        sequence: input.sequence,
        payload: input.payload,
      ),
      SessionAuthenticationInput(
        sessionId: input.sessionId,
        senderPeerId: 'peer_other',
        recipientPeerId: input.recipientPeerId,
        sequence: input.sequence,
        payload: input.payload,
      ),
      SessionAuthenticationInput(
        sessionId: input.sessionId,
        senderPeerId: input.senderPeerId,
        recipientPeerId: 'peer_other',
        sequence: input.sequence,
        payload: input.payload,
      ),
      SessionAuthenticationInput(
        sessionId: input.sessionId,
        senderPeerId: input.senderPeerId,
        recipientPeerId: input.recipientPeerId,
        sequence: input.sequence + 1,
        payload: input.payload,
      ),
    ]) {
      expect(
        () => SessionAuthenticatedPayloadCodec.decode(
          encoded: encoded,
          sessionId: changed.sessionId,
          senderPeerId: changed.senderPeerId,
          recipientPeerId: changed.recipientPeerId,
          sequence: changed.sequence,
          authenticator: authenticator,
        ),
        throwsFormatException,
      );
    }
  });

  test('rejects tampered envelope metadata and malformed framing', () {
    final authenticator = _authenticator();
    final input = _input();
    final encoded = SessionAuthenticatedPayloadCodec.encode(
      input: input,
      authenticator: authenticator,
    );

    final tampered = encoded.toList()..[encoded.length - 1] ^= 1;
    expect(
      () => SessionAuthenticatedPayloadCodec.decode(
        encoded: tampered,
        sessionId: input.sessionId,
        senderPeerId: input.senderPeerId,
        recipientPeerId: input.recipientPeerId,
        sequence: input.sequence,
        authenticator: authenticator,
      ),
      throwsFormatException,
    );

    for (final malformed in <List<int>>[
      const <int>[],
      <int>[0x50, 0x44, 0x41, 0x31, 2, 32],
      <int>[0x50, 0x44, 0x41, 0x31, 1, 31],
    ]) {
      expect(
        () => SessionAuthenticatedPayloadCodec.decode(
          encoded: malformed,
          sessionId: input.sessionId,
          senderPeerId: input.senderPeerId,
          recipientPeerId: input.recipientPeerId,
          sequence: input.sequence,
          authenticator: authenticator,
        ),
        throwsFormatException,
      );
    }
  });

  test('rejects weak keys and unsafe authentication input', () {
    expect(
      () => HmacSha256SessionMessageAuthenticator(key: List<int>.filled(31, 1)),
      throwsArgumentError,
    );

    final authenticator = _authenticator();
    for (final invalid in <SessionAuthenticationInput>[
      SessionAuthenticationInput(
        sessionId: ' session_001',
        senderPeerId: 'peer_sender',
        recipientPeerId: 'peer_recipient',
        sequence: 1,
        payload: <int>[1],
      ),
      SessionAuthenticationInput(
        sessionId: 'session_001',
        senderPeerId: 'peer_sender\u0085',
        recipientPeerId: 'peer_recipient',
        sequence: 1,
        payload: <int>[1],
      ),
      SessionAuthenticationInput(
        sessionId: 'session_001',
        senderPeerId: 'peer_sender',
        recipientPeerId: 'peer_recipient',
        sequence: -1,
        payload: <int>[1],
      ),
      SessionAuthenticationInput(
        sessionId: 'session_001',
        senderPeerId: 'peer_sender',
        recipientPeerId: 'peer_recipient',
        sequence: 1,
        payload: const <int>[],
      ),
    ]) {
      expect(() => authenticator.createTag(invalid), throwsArgumentError);
    }
  });
}

HmacSha256SessionMessageAuthenticator _authenticator() {
  return HmacSha256SessionMessageAuthenticator(
    key: List<int>.generate(32, (index) => index),
  );
}

SessionAuthenticationInput _input() {
    return SessionAuthenticationInput(
    sessionId: 'session_001',
    senderPeerId: 'peer_sender',
    recipientPeerId: 'peer_recipient',
    sequence: 7,
    payload: <int>[1, 2, 3, 255],
  );
}
