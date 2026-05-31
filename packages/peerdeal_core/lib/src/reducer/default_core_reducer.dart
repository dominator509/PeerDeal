import '../contracts/core_reducer.dart';
import '../contracts/invariant_guard.dart';
import '../invariants/baseline_invariant_guards.dart';
import '../models/command_application_result.dart';
import '../models/core_event.dart';
import '../models/invariant_violation.dart';
import '../models/reducer_context.dart';
import '../models/table_phase.dart';
import '../models/table_state.dart';

class DefaultCoreReducer implements CoreReducer {
  DefaultCoreReducer({
    List<InvariantGuard> invariantGuards = baselineInvariantGuards,
  }) : _invariantGuards = List<InvariantGuard>.unmodifiable(invariantGuards);

  final List<InvariantGuard> _invariantGuards;

  @override
  TableState applyEvent({
    required TableState state,
    required CoreEvent event,
    required ReducerContext context,
  }) {
    final int nextSequence = state.eventSequence + 1;
    switch (event.eventType) {
      case 'OpenTableSessionOpened':
        return state.copyWith(
          phase: TablePhase.openReady,
          eventSequence: nextSequence,
        );
      case 'ParticipantConnected':
        return state.copyWith(
          playersConnected: state.playersConnected + 1,
          eventSequence: nextSequence,
        );
      case 'ParticipantSeated':
        return state.copyWith(
          playersSeated: state.playersSeated + 1,
          eventSequence: nextSequence,
        );
      case 'HandStarted':
        return state.copyWith(
          phase: TablePhase.liveActive,
          activeHandId: event.payload['hand_id'] as String?,
          eventSequence: nextSequence,
        );
      case 'HandSettled':
        return state.copyWith(
          activeHandId: null,
          phase: state.closeRequested
              ? TablePhase.closing
              : TablePhase.liveActive,
          eventSequence: nextSequence,
        );
      case 'SessionCloseRequested':
        return state.copyWith(
          closeRequested: true,
          phase: state.hasActiveHand
              ? TablePhase.liveActive
              : TablePhase.closing,
          eventSequence: nextSequence,
        );
      case 'SessionClosed':
        return state.copyWith(
          phase: TablePhase.closed,
          activeHandId: null,
          closeRequested: true,
          playersConnected: 0,
          playersSeated: 0,
          eventSequence: nextSequence,
        );
      case 'SessionWiped':
        return state.copyWith(
          phase: TablePhase.wiped,
          activeHandId: null,
          playersConnected: 0,
          playersSeated: 0,
          closeRequested: true,
          eventSequence: nextSequence,
        );
      default:
        return state.copyWith(eventSequence: nextSequence);
    }
  }

  @override
  CommandApplicationResult applyEvents({
    required TableState initialState,
    required List<CoreEvent> events,
    required ReducerContext context,
  }) {
    TableState state = initialState;
    final emittedEvents = <CoreEvent>[];
    for (final CoreEvent event in events) {
      state = applyEvent(state: state, event: event, context: context);
      emittedEvents.add(event);
      final violations = _evaluateInvariants(state);
      if (context.strictInvariantMode && violations.isNotEmpty) {
        return CommandApplicationResult(
          state: state,
          emittedEvents: List<CoreEvent>.unmodifiable(emittedEvents),
          violations: violations,
        );
      }
    }
    final violations = _evaluateInvariants(state);
    return CommandApplicationResult(
      state: state,
      emittedEvents: List<CoreEvent>.unmodifiable(emittedEvents),
      violations: violations,
    );
  }

  List<InvariantViolation> _evaluateInvariants(TableState state) {
    return List<InvariantViolation>.unmodifiable(<InvariantViolation>[
      for (final guard in _invariantGuards) ...guard.evaluate(state),
    ]);
  }
}
