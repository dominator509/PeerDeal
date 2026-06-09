import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import '../contracts/replay_engine.dart';
import '../contracts/replay_state_projector.dart';
import '../models/replay_request.dart';
import '../models/replay_result.dart';
import '../models/replay_mismatch.dart';
import 'anchor_hash_calculator.dart';
import 'event_window_validator.dart';
import 'snapshot_suffix_replayer.dart';

class BasicReplayEngine<TState> implements ReplayEngine<TState> {
  BasicReplayEngine({
    required this.projector,
    AnchorHashCalculator? anchorHashCalculator,
    EventWindowValidator? eventWindowValidator,
    SnapshotSuffixReplayer? snapshotSuffixReplayer,
    this.protocolCatalog = const ProtocolCatalog(),
  }) : anchorHashCalculator =
           anchorHashCalculator ?? const AnchorHashCalculator(),
       eventWindowValidator =
           eventWindowValidator ?? const EventWindowValidator(),
       snapshotSuffixReplayer =
           snapshotSuffixReplayer ?? const SnapshotSuffixReplayer();

  final ReplayStateProjector<TState> projector;
  final AnchorHashCalculator anchorHashCalculator;
  final EventWindowValidator eventWindowValidator;
  final SnapshotSuffixReplayer snapshotSuffixReplayer;
  final ProtocolCatalog protocolCatalog;

  @override
  ReplayResult<TState> replay(ReplayRequest request) {
    final mismatches = <ReplayMismatch>[
      ..._validateProtocolVersions(request),
      ..._validateReplayScope(request),
      ..._validateReplayRange(request),
    ];

    if (mismatches.isNotEmpty) {
      return ReplayResult<TState>(
        isSuccess: false,
        state: null,
        finalAppliedEventSeq: null,
        reconstructedAnchor: null,
        mismatches: mismatches,
      );
    }

    final selectedEvents = _selectEvents(request);
    mismatches.addAll(
      eventWindowValidator.validate(
        selectedEvents,
        expectedPreviousEventSeq: request.snapshot?.snapshotBaseEventSeq,
      ),
    );

    if (mismatches.isNotEmpty) {
      return ReplayResult<TState>(
        isSuccess: false,
        state: null,
        finalAppliedEventSeq: null,
        reconstructedAnchor: null,
        mismatches: mismatches,
      );
    }

    late TState state;
    try {
      state = projector.createBaseState(
        tableId: request.tableId,
        sessionId: request.sessionId,
        protocolVersion: request.protocolVersion,
      );

      for (final event in selectedEvents) {
        state = projector.applyEvent(state: state, event: event);
      }
    } on Object catch (error) {
      return ReplayResult<TState>(
        isSuccess: false,
        state: null,
        finalAppliedEventSeq: null,
        reconstructedAnchor: null,
        mismatches: <ReplayMismatch>[
          ReplayMismatch(
            code: 'ERR_REPLAY_PROJECTOR_FAILURE',
            message: 'Replay projector failed during reconstruction.',
            actual: error.runtimeType.toString(),
          ),
        ],
      );
    }

    final reconstructedAnchor = anchorHashCalculator.calculate(
      scope: request.scope,
      events: selectedEvents,
    );

    if (request.expectedAnchor != null &&
        request.expectedAnchor != reconstructedAnchor) {
      mismatches.add(
        ReplayMismatch(
          code: 'ERR_REPLAY_ANCHOR_MISMATCH',
          message: 'Expected anchor does not match reconstructed anchor.',
          expected: request.expectedAnchor.toString(),
          actual: reconstructedAnchor.toString(),
        ),
      );
    }

    return ReplayResult<TState>(
      isSuccess: mismatches.isEmpty,
      state: state,
      finalAppliedEventSeq: selectedEvents.isEmpty
          ? request.snapshot?.snapshotBaseEventSeq
          : selectedEvents.last.eventSeq,
      reconstructedAnchor: reconstructedAnchor,
      mismatches: mismatches,
      warnings: request.snapshot == null
          ? const <String>[]
          : const <String>['Replay used snapshot + suffix planning path.'],
    );
  }

  List<EventEnvelope> _selectEvents(ReplayRequest request) {
    final scopedEvents = request.events
        .where((event) {
          if (request.fromEventSeq != null &&
              event.eventSeq < request.fromEventSeq!) {
            return false;
          }
          if (request.toEventSeq != null &&
              event.eventSeq > request.toEventSeq!) {
            return false;
          }
          return true;
        })
        .toList(growable: false);

    if (request.snapshot == null) {
      return scopedEvents;
    }

    return snapshotSuffixReplayer
        .plan(snapshot: request.snapshot!, events: scopedEvents)
        .eventsToApply;
  }

  List<ReplayMismatch> _validateProtocolVersions(ReplayRequest request) {
    final mismatches = <ReplayMismatch>[];

    if (!protocolCatalog.supportsProtocolVersion(request.protocolVersion)) {
      mismatches.add(
        ReplayMismatch(
          code: ProtocolResultCodes.errReplayProtocolIncompatible,
          message: 'Replay request protocol version is not supported.',
          expected: currentProtocolVersion.toWire(),
          actual: request.protocolVersion,
        ),
      );
      return mismatches;
    }

    final snapshot = request.snapshot;
    if (snapshot != null) {
      final snapshotCompatibility = protocolCatalog.checkSnapshotEnvelope(
        snapshot,
      );
      if (snapshotCompatibility.resultCode ==
          ResultCode.errProtocolIncompatible) {
        mismatches.add(
          ReplayMismatch(
            code: ProtocolResultCodes.errReplaySnapshotProtocolIncompatible,
            message: 'Replay snapshot protocol version is not supported.',
            expected: currentProtocolVersion.toWire(),
            actual: snapshot.protocolVersion,
          ),
        );
      } else if (snapshot.protocolVersion != request.protocolVersion) {
        mismatches.add(
          ReplayMismatch(
            code: ProtocolResultCodes.errReplaySnapshotProtocolMismatch,
            message:
                'Snapshot protocol version does not match the replay request.',
            expected: request.protocolVersion,
            actual: snapshot.protocolVersion,
          ),
        );
      } else if (!snapshotCompatibility.isSupported) {
        mismatches.add(
          ReplayMismatch(
            code: ProtocolResultCodes.errReplaySnapshotSchemaUnsupported,
            message:
                'Replay snapshot artifact is not supported by the protocol catalog.',
            expected: 'supported snapshot artifact',
            actual: '${snapshot.snapshotType}@${snapshot.snapshotVersion}',
          ),
        );
      }
    }

    for (final event in request.events) {
      final eventCompatibility = protocolCatalog.checkEventEnvelope(event);
      if (eventCompatibility.resultCode == ResultCode.errProtocolIncompatible) {
        mismatches.add(
          ReplayMismatch(
            code: ProtocolResultCodes.errReplayEventProtocolIncompatible,
            message: 'Replay event protocol version is not supported.',
            expected: currentProtocolVersion.toWire(),
            actual: event.protocolVersion,
          ),
        );
      } else if (event.protocolVersion != request.protocolVersion) {
        mismatches.add(
          ReplayMismatch(
            code: ProtocolResultCodes.errReplayEventProtocolMismatch,
            message:
                'Replay event protocol version does not match the request.',
            expected: request.protocolVersion,
            actual: event.protocolVersion,
          ),
        );
      } else if (!eventCompatibility.isSupported) {
        mismatches.add(
          ReplayMismatch(
            code: ProtocolResultCodes.errReplayEventSchemaUnsupported,
            message:
                'Replay event artifact is not supported by the protocol catalog.',
            expected: 'supported event artifact',
            actual: '${event.eventType}@${event.eventVersion}',
          ),
        );
      }
    }

    return mismatches;
  }

  List<ReplayMismatch> _validateReplayScope(ReplayRequest request) {
    final mismatches = <ReplayMismatch>[];
    final snapshot = request.snapshot;
    if (snapshot != null &&
        (snapshot.tableId != request.tableId ||
            snapshot.sessionId != request.sessionId)) {
      mismatches.add(
        ReplayMismatch(
          code: 'ERR_REPLAY_SNAPSHOT_SCOPE_MISMATCH',
          message: 'Replay snapshot scope does not match the request.',
          expected: '${request.tableId}/${request.sessionId}',
          actual: '${snapshot.tableId}/${snapshot.sessionId}',
        ),
      );
    }

    for (final event in request.events) {
      if (event.tableId == request.tableId &&
          event.sessionId == request.sessionId) {
        continue;
      }
      mismatches.add(
        ReplayMismatch(
          code: 'ERR_REPLAY_EVENT_SCOPE_MISMATCH',
          message: 'Replay event scope does not match the request.',
          expected: '${request.tableId}/${request.sessionId}',
          actual: '${event.tableId}/${event.sessionId}',
        ),
      );
    }

    return mismatches;
  }

  List<ReplayMismatch> _validateReplayRange(ReplayRequest request) {
    final mismatches = <ReplayMismatch>[];
    final fromEventSeq = request.fromEventSeq;
    final toEventSeq = request.toEventSeq;

    if (fromEventSeq != null && fromEventSeq < 1) {
      mismatches.add(
        ReplayMismatch(
          code: 'ERR_REPLAY_EVENT_RANGE_INVALID',
          message: 'Replay from-event sequence must be positive.',
          expected: '>=1',
          actual: fromEventSeq,
        ),
      );
    }

    if (toEventSeq != null && toEventSeq < 1) {
      mismatches.add(
        ReplayMismatch(
          code: 'ERR_REPLAY_EVENT_RANGE_INVALID',
          message: 'Replay to-event sequence must be positive.',
          expected: '>=1',
          actual: toEventSeq,
        ),
      );
    }

    if (fromEventSeq != null &&
        toEventSeq != null &&
        fromEventSeq > toEventSeq) {
      mismatches.add(
        ReplayMismatch(
          code: 'ERR_REPLAY_EVENT_RANGE_INVALID',
          message:
              'Replay from-event sequence must not exceed to-event sequence.',
          expected: '<=$toEventSeq',
          actual: fromEventSeq,
        ),
      );
    }

    return mismatches;
  }
}
