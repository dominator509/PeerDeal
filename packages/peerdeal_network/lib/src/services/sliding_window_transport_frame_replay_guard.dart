import '../contracts/transport_frame_replay_guard.dart';
import '../models/network_input_limits.dart';
import '../models/transport_frame.dart';
import '../models/transport_frame_replay_result.dart';

/// Bounded replay protection keyed by the complete transport frame scope.
///
/// A frame sequence may arrive out of order while it remains inside the
/// configured window. Sequence reuse and sequences that have fallen behind
/// the window are rejected. Scope state is never evicted implicitly; once the
/// configured scope limit is reached, a new scope fails closed.
class SlidingWindowTransportFrameReplayGuard
    implements TransportFrameReplayGuard {
  SlidingWindowTransportFrameReplayGuard({
    int maxScopes = defaultMaxScopes,
    int maxSequenceWindow = defaultMaxSequenceWindow,
  }) : maxScopes = _validatePositiveLimit(maxScopes, 'maxScopes'),
       maxSequenceWindow = _validatePositiveLimit(
         maxSequenceWindow,
         'maxSequenceWindow',
       ) {
    if (this.maxScopes > maximumScopes) {
      throw ArgumentError.value(
        maxScopes,
        'maxScopes',
        'Transport replay scope limit is too large.',
      );
    }
    if (this.maxSequenceWindow > maximumSequenceWindow) {
      throw ArgumentError.value(
        maxSequenceWindow,
        'maxSequenceWindow',
        'Transport replay sequence window is too large.',
      );
    }
  }

  static const defaultMaxScopes = 32;
  static const defaultMaxSequenceWindow = 128;
  static const maximumScopes = 256;
  static const maximumSequenceWindow = 4096;

  final int maxScopes;
  final int maxSequenceWindow;
  final Map<_TransportFrameReplayScope, _SequenceWindow> _scopes =
      <_TransportFrameReplayScope, _SequenceWindow>{};

  @override
  TransportFrameReplayResult check(TransportFrame frame) {
    if (!_isValidFrame(frame)) {
      return const TransportFrameReplayResult.rejected(
        disposition: TransportFrameReplayDisposition.invalid,
        reasonCode: 'ERR_TRANSPORT_FRAME_REPLAY_INPUT_INVALID',
      );
    }

    final scope = _TransportFrameReplayScope.from(frame);
    final window = _scopes[scope];
    if (window == null) {
      if (_scopes.length >= maxScopes) {
        return const TransportFrameReplayResult.rejected(
          disposition: TransportFrameReplayDisposition.scopeLimit,
          reasonCode: 'ERR_TRANSPORT_FRAME_REPLAY_SCOPE_LIMIT',
        );
      }
      return const TransportFrameReplayResult.accepted();
    }
    if (window.seenSequences.contains(frame.sequence)) {
      return const TransportFrameReplayResult.rejected(
        disposition: TransportFrameReplayDisposition.duplicate,
        reasonCode: 'ERR_TRANSPORT_FRAME_REPLAYED',
      );
    }
    if (window.isStale(frame.sequence, maxSequenceWindow)) {
      return const TransportFrameReplayResult.rejected(
        disposition: TransportFrameReplayDisposition.stale,
        reasonCode: 'ERR_TRANSPORT_FRAME_REPLAY_STALE',
      );
    }
    return const TransportFrameReplayResult.accepted();
  }

  @override
  void record(TransportFrame frame) {
    if (!_isValidFrame(frame)) {
      throw ArgumentError.value(
        frame,
        'frame',
        'Transport replay frame input is invalid.',
      );
    }

    final scope = _TransportFrameReplayScope.from(frame);
    final window = _scopes[scope];
    if (window == null) {
      if (_scopes.length >= maxScopes) {
        throw StateError('Transport replay scope limit reached.');
      }
      _scopes[scope] = _SequenceWindow(frame.sequence);
      return;
    }
    window.add(frame.sequence, maxSequenceWindow);
  }

  bool _isValidFrame(TransportFrame frame) {
    return NetworkInputLimits.isSafePeerIdentity(frame.sessionId) &&
        NetworkInputLimits.isOperationalPeerIdentity(frame.fromPeerId) &&
        NetworkInputLimits.isOperationalPeerIdentity(frame.toPeerId) &&
        frame.fromPeerId != frame.toPeerId &&
        frame.sequence > 0;
  }

  static int _validatePositiveLimit(int value, String fieldName) {
    if (value < 1) {
      throw ArgumentError.value(
        value,
        fieldName,
        'Transport replay limit must be positive.',
      );
    }
    return value;
  }
}

class _TransportFrameReplayScope {
  const _TransportFrameReplayScope({
    required this.sessionId,
    required this.senderPeerId,
    required this.recipientPeerId,
  });

  factory _TransportFrameReplayScope.from(TransportFrame frame) {
    return _TransportFrameReplayScope(
      sessionId: frame.sessionId,
      senderPeerId: frame.fromPeerId,
      recipientPeerId: frame.toPeerId,
    );
  }

  final String sessionId;
  final String senderPeerId;
  final String recipientPeerId;

  @override
  bool operator ==(Object other) {
    return other is _TransportFrameReplayScope &&
        other.sessionId == sessionId &&
        other.senderPeerId == senderPeerId &&
        other.recipientPeerId == recipientPeerId;
  }

  @override
  int get hashCode => Object.hash(sessionId, senderPeerId, recipientPeerId);
}

class _SequenceWindow {
  _SequenceWindow(int firstSequence)
    : highestSequence = firstSequence,
      seenSequences = <int>{firstSequence};

  int highestSequence;
  final Set<int> seenSequences;

  bool isStale(int sequence, int windowSize) {
    return highestSequence - sequence >= windowSize;
  }

  void add(int sequence, int windowSize) {
    if (sequence > highestSequence) highestSequence = sequence;
    seenSequences.add(sequence);
    final floor = highestSequence - windowSize + 1;
    seenSequences.removeWhere((candidate) => candidate < floor);
  }
}
