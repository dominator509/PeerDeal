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
  })  : anchorHashCalculator = anchorHashCalculator ?? const AnchorHashCalculator(),
        eventWindowValidator = eventWindowValidator ?? const EventWindowValidator(),
        snapshotSuffixReplayer = snapshotSuffixReplayer ?? const SnapshotSuffixReplayer();

  final ReplayStateProjector<TState> projector;
  final AnchorHashCalculator anchorHashCalculator;
  final EventWindowValidator eventWindowValidator;
  final SnapshotSuffixReplayer snapshotSuffixReplayer;

  @override
  ReplayResult<TState> replay(ReplayRequest request) {
    final selectedEvents = _selectEvents(request);
    final mismatches = <ReplayMismatch>[
      ...eventWindowValidator.validate(selectedEvents),
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

    var state = projector.createBaseState(
      tableId: request.tableId,
      sessionId: request.sessionId,
      protocolVersion: request.protocolVersion,
    );

    for (final event in selectedEvents) {
      state = projector.applyEvent(state: state, event: event);
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
      finalAppliedEventSeq:
          selectedEvents.isEmpty ? request.snapshot?.snapshotBaseEventSeq : selectedEvents.last.eventSeq,
      reconstructedAnchor: reconstructedAnchor,
      mismatches: mismatches,
      warnings: request.snapshot == null
          ? const <String>[]
          : const <String>['Replay used snapshot + suffix planning path.'],
    );
  }

  List<EventEnvelope> _selectEvents(ReplayRequest request) {
    final scopedEvents = request.events.where((event) {
      if (request.fromEventSeq != null && event.eventSeq < request.fromEventSeq!) {
        return false;
      }
      if (request.toEventSeq != null && event.eventSeq > request.toEventSeq!) {
        return false;
      }
      return true;
    }).toList(growable: false);

    if (request.snapshot == null) {
      return scopedEvents;
    }

    return snapshotSuffixReplayer.plan(
      snapshot: request.snapshot!,
      events: scopedEvents,
    ).eventsToApply;
  }
}
