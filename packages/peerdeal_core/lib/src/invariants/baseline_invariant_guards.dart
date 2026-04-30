import '../contracts/invariant_guard.dart';
import '../models/invariant_violation.dart';
import '../models/table_phase.dart';
import '../models/table_state.dart';

class ActiveHandRequiresLivePhaseGuard implements InvariantGuard {
  const ActiveHandRequiresLivePhaseGuard();

  @override
  Iterable<InvariantViolation> evaluate(TableState state) sync* {
    if (state.hasActiveHand && state.phase != TablePhase.liveActive) {
      yield const InvariantViolation(
        code: 'ERR_ACTIVE_HAND_OUTSIDE_LIVE_PHASE',
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
        code: 'ERR_SEATED_EXCEEDS_CONNECTED',
        message: 'Seated players cannot exceed connected players.',
      );
    }
  }
}

class WipedPhaseMustNotHaveActiveStateGuard implements InvariantGuard {
  const WipedPhaseMustNotHaveActiveStateGuard();

  @override
  Iterable<InvariantViolation> evaluate(TableState state) sync* {
    if (state.phase == TablePhase.wiped &&
        (state.hasActiveHand || state.playersConnected > 0 || state.playersSeated > 0)) {
      yield const InvariantViolation(
        code: 'ERR_WIPED_STATE_NOT_TERMINAL',
        message: 'Wiped phase must not retain active hand or participants.',
      );
    }
  }
}
