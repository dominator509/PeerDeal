import 'package:peerdeal_network/peerdeal_network.dart';
import 'package:test/test.dart';

void main() {
  test('rejects reserved peer sentinels as replay scope identities', () {
    final guard = SlidingWindowTransportFrameReplayGuard();
    final invalid = _frame(sequence: 1, senderPeerId: 'none');

    expect(
      guard.check(invalid).reasonCode,
      'ERR_TRANSPORT_FRAME_REPLAY_INPUT_INVALID',
    );
    expect(() => guard.record(invalid), throwsArgumentError);
  });

  test('rejects sequence reuse after an accepted frame', () {
    final guard = SlidingWindowTransportFrameReplayGuard();
    final frame = _frame(sequence: 1);

    expect(guard.check(frame).isAccepted, isTrue);
    guard.record(frame);

    final replay = guard.check(frame);
    expect(replay.isRejected, isTrue);
    expect(replay.disposition, TransportFrameReplayDisposition.duplicate);
    expect(replay.reasonCode, 'ERR_TRANSPORT_FRAME_REPLAYED');
  });

  test('accepts unique out-of-order frames inside the bounded window', () {
    final guard = SlidingWindowTransportFrameReplayGuard(maxSequenceWindow: 4);
    final first = _frame(sequence: 10);
    final newest = _frame(sequence: 12);
    final delayed = _frame(sequence: 9);

    for (final frame in <TransportFrame>[first, newest]) {
      expect(guard.check(frame).isAccepted, isTrue);
      guard.record(frame);
    }

    expect(guard.check(delayed).isAccepted, isTrue);
    guard.record(delayed);

    final stale = guard.check(_frame(sequence: 8));
    expect(stale.isRejected, isTrue);
    expect(stale.disposition, TransportFrameReplayDisposition.stale);
    expect(stale.reasonCode, 'ERR_TRANSPORT_FRAME_REPLAY_STALE');
  });

  test('isolates sequence windows by complete frame scope', () {
    final guard = SlidingWindowTransportFrameReplayGuard();
    final firstScope = _frame(sequence: 1);
    final secondScope = _frame(
      sequence: 1,
      sessionId: 'session_other',
      senderPeerId: 'peer_other',
    );

    guard.record(firstScope);

    expect(guard.check(firstScope).isRejected, isTrue);
    expect(guard.check(secondScope).isAccepted, isTrue);
  });

  test('fails closed at the bounded scope limit without evicting state', () {
    final guard = SlidingWindowTransportFrameReplayGuard(maxScopes: 1);
    guard.record(_frame(sequence: 1));

    final newScope = guard.check(
      _frame(
        sequence: 1,
        sessionId: 'session_other',
        senderPeerId: 'peer_other',
      ),
    );
    expect(newScope.disposition, TransportFrameReplayDisposition.scopeLimit);
    expect(newScope.reasonCode, 'ERR_TRANSPORT_FRAME_REPLAY_SCOPE_LIMIT');
    expect(guard.check(_frame(sequence: 2)).isAccepted, isTrue);
  });

  test('rejects invalid inputs and invalid limits', () {
    expect(
      () => SlidingWindowTransportFrameReplayGuard(maxScopes: 0),
      throwsArgumentError,
    );
    expect(
      () => SlidingWindowTransportFrameReplayGuard(maxSequenceWindow: 0),
      throwsArgumentError,
    );

    final guard = SlidingWindowTransportFrameReplayGuard();
    final invalid = _frame(sequence: 0);
    expect(
      guard.check(invalid).disposition,
      TransportFrameReplayDisposition.invalid,
    );
    expect(() => guard.record(invalid), throwsArgumentError);
  });

  test('rejects sequences above the native signed 32-bit ceiling', () {
    final guard = SlidingWindowTransportFrameReplayGuard();
    final invalid = _frame(
      sequence: NetworkInputLimits.maxTransportSequence + 1,
    );

    expect(
      guard.check(invalid).disposition,
      TransportFrameReplayDisposition.invalid,
    );
    expect(() => guard.record(invalid), throwsArgumentError);
  });
}

TransportFrame _frame({
  required int sequence,
  String sessionId = 'session_1',
  String senderPeerId = 'peer_a',
  String recipientPeerId = 'peer_b',
}) {
  return TransportFrame(
    sessionId: sessionId,
    fromPeerId: senderPeerId,
    toPeerId: recipientPeerId,
    sequence: sequence,
    payload: <int>[sequence & 0xff],
  );
}
