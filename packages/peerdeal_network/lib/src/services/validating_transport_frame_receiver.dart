import 'dart:async';

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
    int maxInFlightFrames = defaultMaxInFlightFrames,
  }) : _handler = handler,
       _validator = validator,
       _replayGuard = replayGuard ?? SlidingWindowTransportFrameReplayGuard(),
       _maxInFlightFrames = _validatePositiveLimit(
         maxInFlightFrames,
         'maxInFlightFrames',
       );

  static const defaultMaxInFlightFrames = 128;
  static const maximumInFlightFrames =
      SlidingWindowTransportFrameReplayGuard.maximumSequenceWindow;

  final TransportFrameHandler _handler;
  final TransportFrameValidator _validator;
  final TransportFrameReplayGuard _replayGuard;
  final int _maxInFlightFrames;
  final Set<_TransportFrameReplayKey> _inFlight = <_TransportFrameReplayKey>{};
  final Set<_TransportFrameReplayScope> _knownScopes =
      <_TransportFrameReplayScope>{};
  final Map<_TransportFrameReplayScope, Future<void>> _scopeQueueTails =
      <_TransportFrameReplayScope, Future<void>>{};
  Future<void>? _newScopeQueueTail;

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
    if (_inFlight.contains(replayKey)) {
      return TransportFrameReceiveResult.rejected(
        reasonCode: 'ERR_TRANSPORT_FRAME_REPLAY_IN_FLIGHT',
        warnings: const <String>['transport_frame_replay_in_flight'],
      );
    }
    if (_inFlight.length >= _maxInFlightFrames) {
      return TransportFrameReceiveResult.rejected(
        reasonCode: 'ERR_TRANSPORT_FRAME_RECEIVE_QUEUE_LIMIT',
        warnings: const <String>['transport_frame_receive_queue_limit'],
      );
    }
    _inFlight.add(replayKey);

    final scope = _TransportFrameReplayScope.from(frame);
    final wasKnown = _knownScopes.contains(scope);
    final queued = _enqueue(
      wasKnown ? _scopeQueueTails[scope] : _newScopeQueueTail,
      () => _receiveValidatedFrame(frame, replayKey),
    );
    if (wasKnown) {
      _scopeQueueTails[scope] = queued.tail;
    } else {
      _newScopeQueueTail = queued.tail;
    }
    unawaited(
      queued.result.then<void>(
        (result) {
          if (wasKnown) {
            if (identical(_scopeQueueTails[scope], queued.tail)) {
              _scopeQueueTails.remove(scope);
            }
          } else if (identical(_newScopeQueueTail, queued.tail)) {
            _newScopeQueueTail = null;
            if (result.accepted &&
                _knownScopes.length <
                    SlidingWindowTransportFrameReplayGuard.maximumScopes) {
              _knownScopes.add(scope);
            }
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (wasKnown && identical(_scopeQueueTails[scope], queued.tail)) {
            _scopeQueueTails.remove(scope);
          } else if (!wasKnown && identical(_newScopeQueueTail, queued.tail)) {
            _newScopeQueueTail = null;
          }
        },
      ),
    );
    return queued.result;
  }

  Future<TransportFrameReceiveResult> _receiveValidatedFrame(
    TransportFrame frame,
    _TransportFrameReplayKey replayKey,
  ) async {
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

  _TransportFrameReceiveQueueEntry _enqueue(
    Future<void>? previous,
    Future<TransportFrameReceiveResult> Function() operation,
  ) {
    final current = (previous ?? Future<void>.value())
        .then<TransportFrameReceiveResult>((_) => operation());
    final tail = current.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return _TransportFrameReceiveQueueEntry(result: current, tail: tail);
  }

  static int _validatePositiveLimit(int value, String fieldName) {
    if (value < 1 || value > maximumInFlightFrames) {
      throw ArgumentError.value(
        value,
        fieldName,
        'Transport receive in-flight limit is invalid.',
      );
    }
    return value;
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

class _TransportFrameReceiveQueueEntry {
  const _TransportFrameReceiveQueueEntry({
    required this.result,
    required this.tail,
  });

  final Future<TransportFrameReceiveResult> result;
  final Future<void> tail;
}
