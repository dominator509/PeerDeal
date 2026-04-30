import '../contracts/snapshot_applier.dart';
import '../contracts/snapshot_state_projector.dart';
import '../models/snapshot_apply_request.dart';
import '../models/snapshot_apply_result.dart';

class BasicSnapshotApplier<TState> implements SnapshotApplier<TState> {
  BasicSnapshotApplier({required this.projector});

  final SnapshotStateProjector<TState> projector;

  @override
  SnapshotApplyResult<TState> apply(SnapshotApplyRequest request) {
    var state = projector.createBaseState(
      tableId: request.tableId,
      sessionId: request.sessionId,
      protocolVersion: request.protocolVersion,
    );

    final warnings = <String>[];

    if (request.snapshot != null) {
      state = projector.applySnapshot(state: state, snapshot: request.snapshot!);
      warnings.add('Recovery used snapshot checkpoint as a reconstruction accelerator.');
    }

    final suffixEvents = request.snapshot == null
        ? request.events
        : request.events
            .where((event) => event.eventSeq > request.snapshot!.snapshotBaseEventSeq)
            .toList(growable: false);

    for (final event in suffixEvents) {
      state = projector.applyEvent(state: state, event: event);
    }

    return SnapshotApplyResult<TState>(
      state: state,
      appliedEventCount: suffixEvents.length,
      finalAppliedEventSeq: suffixEvents.isEmpty
          ? request.snapshot?.snapshotBaseEventSeq
          : suffixEvents.last.eventSeq,
      warnings: warnings,
    );
  }
}
