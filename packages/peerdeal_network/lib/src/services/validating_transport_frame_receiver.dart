import '../contracts/transport_frame_handler.dart';
import '../contracts/transport_frame_replay_guard.dart';
import '../contracts/transport_frame_receiver.dart';
import '../contracts/transport_frame_validator.dart';
import '../models/transport_frame.dart';
import '../models/transport_frame_receive_result.dart';
import '../models/transport_frame_replay_result.dart';
import 'sliding_window_transport_frame_replay_guard.dart';
import 'basic_transport_frame_validator.dart';

class ValidatingTransportFrameReceiver implements TransportFrameReceiver {
  ValidatingTransportFrameReceiver({
    required TransportFrameHandler handler,
    TransportFrameValidator validator = const BasicTransportFrameValidator(),
    TransportFrameReplayGuard? replayGuard,
  }) : _handler = handler,
       _validator = validator,
       _replayGuard = replayGuard ?? SlidingWindowTransportFrameReplayGuard();

  final TransportFrameHandler _handler;
  final TransportFrameValidator _validator;
  final TransportFrameReplayGuard _replayGuard;
  final Set<_TransportFrameReplayKey> _inFlight = <_TransportFrameReplayKey>{};

  @override
  Future<TransportFrameReceiveResult> receive(TransportFrame frame) async {
    final validation = _validator.validate(frame);
    if (!validation.isValid) {
      return TransportFrameReceiveResult.rejected(
        reasonCode: 'ERR_TRANSPORT_FRAME_REJECTED',
        warnings: validation.warnings,
      );
    }

    final replayKey = _TransportFrameReplayKey.from(frame);
    if (!_inFlight.add(replayKey)) {
      return TransportFrameReceiveResult.rejected(
        reasonCode: 'ERR_TRANSPORT_FRAME_REPLAY_IN_FLIGHT',
        warnings: const <String>['transport_frame_replay_in_flight'],
      );
    }

    late final TransportFrameReplayResult replay;
    try {
      replay = _replayGuard.check(frame);
    } on Object {
      _inFlight.remove(replayKey);
      return TransportFrameReceiveResult.rejected(
        reasonCode: 'ERR_TRANSPORT_FRAME_REPLAY_CHECK_FAILED',
        warnings: const <String>['transport_frame_replay_check_failed'],
      );
    }
    if (!replay.isAccepted) {
      _inFlight.remove(replayKey);
      return TransportFrameReceiveResult.rejected(
        reasonCode: replay.reasonCode,
        warnings: <String>[replay.reasonCode],
      );
    }

    try {
      await _handler.handleFrame(frame);
    } on Object {
      _inFlight.remove(replayKey);
      return TransportFrameReceiveResult.rejected(
        reasonCode: 'ERR_TRANSPORT_FRAME_RECEIVE_FAILED',
        warnings: <String>['transport_frame_handler_failed'],
      );
    }

    try {
      _replayGuard.record(frame);
    } on Object {
      _inFlight.remove(replayKey);
      return TransportFrameReceiveResult.rejected(
        reasonCode: 'ERR_TRANSPORT_FRAME_REPLAY_RECORD_FAILED',
        warnings: const <String>['transport_frame_replay_record_failed'],
      );
    }
    _inFlight.remove(replayKey);

    return const TransportFrameReceiveResult.accepted();
  }
}

class _TransportFrameReplayKey {
  const _TransportFrameReplayKey({
    required this.sessionId,
    required this.senderPeerId,
    required this.recipientPeerId,
    required this.sequence,
  });

  factory _TransportFrameReplayKey.from(TransportFrame frame) {
    return _TransportFrameReplayKey(
      sessionId: frame.sessionId,
      senderPeerId: frame.fromPeerId,
      recipientPeerId: frame.toPeerId,
      sequence: frame.sequence,
    );
  }

  final String sessionId;
  final String senderPeerId;
  final String recipientPeerId;
  final int sequence;

  @override
  bool operator ==(Object other) {
    return other is _TransportFrameReplayKey &&
        other.sessionId == sessionId &&
        other.senderPeerId == senderPeerId &&
        other.recipientPeerId == recipientPeerId &&
        other.sequence == sequence;
  }

  @override
  int get hashCode =>
      Object.hash(sessionId, senderPeerId, recipientPeerId, sequence);
}
