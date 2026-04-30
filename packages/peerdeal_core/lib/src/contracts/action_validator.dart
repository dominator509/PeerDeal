import '../models/command_validation_result.dart';
import '../models/core_command.dart';
import '../models/table_state.dart';

abstract interface class ActionValidator {
  CommandValidationResult validate({
    required TableState state,
    required CoreCommand command,
  });
}
