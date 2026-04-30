import '../contracts/action_validator.dart';
import '../models/command_validation_result.dart';
import '../models/core_command.dart';
import '../models/table_phase.dart';
import '../models/table_state.dart';

class BasicActionValidator implements ActionValidator {
  const BasicActionValidator();

  @override
  CommandValidationResult validate({
    required TableState state,
    required CoreCommand command,
  }) {
    switch (command.commandType) {
      case 'OpenTableSession':
        if (state.phase != TablePhase.draft) {
          return const CommandValidationResult.rejected(
            resultCode: 'ERR_OPEN_REQUIRES_DRAFT',
            message: 'Table may only open from draft state.',
          );
        }
        return const CommandValidationResult.accepted();
      case 'StartHand':
        if (state.phase != TablePhase.openReady && state.phase != TablePhase.liveActive) {
          return const CommandValidationResult.rejected(
            resultCode: 'ERR_START_HAND_REQUIRES_OPEN_OR_LIVE',
            message: 'Hand start requires openReady or liveActive phase.',
          );
        }
        if (state.playersSeated < 2) {
          return const CommandValidationResult.rejected(
            resultCode: 'ERR_NEED_TWO_SEATED_PLAYERS',
            message: 'At least two seated players are required to start a hand.',
          );
        }
        if (state.hasActiveHand) {
          return const CommandValidationResult.rejected(
            resultCode: 'ERR_HAND_ALREADY_ACTIVE',
            message: 'Cannot start a new hand while another hand is active.',
          );
        }
        return const CommandValidationResult.accepted();
      case 'RequestSessionClose':
        if (state.phase == TablePhase.closed || state.phase == TablePhase.wiped) {
          return const CommandValidationResult.rejected(
            resultCode: 'ERR_SESSION_ALREADY_TERMINAL',
            message: 'Session is already closed or wiped.',
          );
        }
        return const CommandValidationResult.accepted();
      default:
        return const CommandValidationResult.accepted();
    }
  }
}
