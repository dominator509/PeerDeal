import '../contracts/invariant_guard.dart';
import '../models/core_invariant_codes.dart';
import '../models/invariant_violation.dart';
import '../models/table_phase.dart';
import '../models/table_state.dart';

const baselineInvariantGuards = <InvariantGuard>[
  TableIdentityMustBePresentGuard(),
  CountsAndSequenceMustBeNonNegativeGuard(),
  ActiveHandIdentityMustBePresentGuard(),
  ActiveHandRequiresLivePhaseGuard(),
  SeatCountCannotExceedConnectedGuard(),
  ClosingPhaseRequiresCloseRequestGuard(),
  ClosedPhaseMustBeTerminalGuard(),
  WipedPhaseMustNotHaveActiveStateGuard(),
];

class TableIdentityMustBePresentGuard implements InvariantGuard {
  const TableIdentityMustBePresentGuard();

  @override
  Iterable<InvariantViolation> evaluate(TableState state) sync* {
    if (state.tableId.trim().isEmpty) {
      yield const InvariantViolation(
        code: CoreInvariantCodes.tableIdEmpty,
        message: 'A projected table state must keep a non-empty table_id.',
      );
    } else if (!_isSafeIdentity(state.tableId)) {
      yield const InvariantViolation(
        code: CoreInvariantCodes.tableIdUnsafe,
        message: 'A projected table state must keep a safe table_id.',
      );
    }
    if (state.sessionId.trim().isEmpty) {
      yield const InvariantViolation(
        code: CoreInvariantCodes.sessionIdEmpty,
        message: 'A projected table state must keep a non-empty session_id.',
      );
    } else if (!_isSafeIdentity(state.sessionId)) {
      yield const InvariantViolation(
        code: CoreInvariantCodes.sessionIdUnsafe,
        message: 'A projected table state must keep a safe session_id.',
      );
    }
    if (state.protocolVersion.trim().isEmpty) {
      yield const InvariantViolation(
        code: CoreInvariantCodes.protocolVersionEmpty,
        message:
            'A projected table state must keep a non-empty protocol_version.',
      );
    } else if (!_isSafeIdentity(state.protocolVersion)) {
      yield const InvariantViolation(
        code: CoreInvariantCodes.protocolVersionUnsafe,
        message: 'A projected table state must keep a safe protocol_version.',
      );
    }
  }
}

class CountsAndSequenceMustBeNonNegativeGuard implements InvariantGuard {
  const CountsAndSequenceMustBeNonNegativeGuard();

  @override
  Iterable<InvariantViolation> evaluate(TableState state) sync* {
    if (state.eventSequence < 0) {
      yield const InvariantViolation(
        code: CoreInvariantCodes.eventSequenceNegative,
        message: 'event_sequence cannot be negative.',
      );
    }
    if (state.playersConnected < 0) {
      yield const InvariantViolation(
        code: CoreInvariantCodes.connectedCountNegative,
        message: 'players_connected cannot be negative.',
      );
    }
    if (state.playersSeated < 0) {
      yield const InvariantViolation(
        code: CoreInvariantCodes.seatedCountNegative,
        message: 'players_seated cannot be negative.',
      );
    }
  }
}

class ActiveHandIdentityMustBePresentGuard implements InvariantGuard {
  const ActiveHandIdentityMustBePresentGuard();

  @override
  Iterable<InvariantViolation> evaluate(TableState state) sync* {
    if (state.activeHandId != null && state.activeHandId!.trim().isEmpty) {
      yield const InvariantViolation(
        code: CoreInvariantCodes.activeHandIdEmpty,
        message: 'active_hand_id cannot be empty when a hand is active.',
      );
    } else if (state.activeHandId != null &&
        !_isSafeIdentity(state.activeHandId!)) {
      yield const InvariantViolation(
        code: CoreInvariantCodes.activeHandIdUnsafe,
        message: 'active_hand_id must contain safe identity text.',
      );
    }
  }
}

class ActiveHandRequiresLivePhaseGuard implements InvariantGuard {
  const ActiveHandRequiresLivePhaseGuard();

  @override
  Iterable<InvariantViolation> evaluate(TableState state) sync* {
    if (state.hasActiveHand && state.phase != TablePhase.liveActive) {
      yield const InvariantViolation(
        code: CoreInvariantCodes.activeHandOutsideLivePhase,
        message: 'A hand cannot remain active outside liveActive phase.',
      );
    }
  }
}

class SeatCountCannotExceedConnectedGuard implements InvariantGuard {
  const SeatCountCannotExceedConnectedGuard();

  @override
  Iterable<InvariantViolation> evaluate(TableState state) sync* {
    if (state.playersSeated > state.playersConnected) {
      yield const InvariantViolation(
        code: CoreInvariantCodes.seatedExceedsConnected,
        message: 'Seated players cannot exceed connected players.',
      );
    }
  }
}

class ClosingPhaseRequiresCloseRequestGuard implements InvariantGuard {
  const ClosingPhaseRequiresCloseRequestGuard();

  @override
  Iterable<InvariantViolation> evaluate(TableState state) sync* {
    if (state.phase == TablePhase.closing && !state.closeRequested) {
      yield const InvariantViolation(
        code: CoreInvariantCodes.closingWithoutCloseRequest,
        message: 'closing phase requires a prior close request.',
      );
    }
  }
}

class ClosedPhaseMustBeTerminalGuard implements InvariantGuard {
  const ClosedPhaseMustBeTerminalGuard();

  @override
  Iterable<InvariantViolation> evaluate(TableState state) sync* {
    if (state.phase != TablePhase.closed) {
      return;
    }
    if (state.hasActiveHand ||
        state.playersConnected > 0 ||
        state.playersSeated > 0) {
      yield const InvariantViolation(
        code: CoreInvariantCodes.closedStateNotTerminal,
        message: 'Closed phase must not retain active hand or participants.',
      );
    }
    if (!state.closeRequested) {
      yield const InvariantViolation(
        code: CoreInvariantCodes.closedStateNotCloseRequested,
        message: 'Closed phase requires a prior close request.',
      );
    }
  }
}

class WipedPhaseMustNotHaveActiveStateGuard implements InvariantGuard {
  const WipedPhaseMustNotHaveActiveStateGuard();

  @override
  Iterable<InvariantViolation> evaluate(TableState state) sync* {
    if (state.phase != TablePhase.wiped) {
      return;
    }
    if (state.hasActiveHand ||
        state.playersConnected > 0 ||
        state.playersSeated > 0) {
      yield const InvariantViolation(
        code: CoreInvariantCodes.wipedStateNotTerminal,
        message: 'Wiped phase must not retain active hand or participants.',
      );
    }
    if (!state.closeRequested) {
      yield const InvariantViolation(
        code: CoreInvariantCodes.wipedStateNotCloseRequested,
        message: 'Wiped phase requires a terminal close marker.',
      );
    }
  }
}

bool _isSafeIdentity(String value) {
  if (value.trim() != value) return false;
  return value.codeUnits.every(
    (unit) => unit >= 0x20 && !(unit >= 0x7f && unit <= 0x9f),
  );
}
