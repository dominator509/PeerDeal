import 'package:peerdeal_protocol/peerdeal_protocol.dart';

class CoreCommandValidator {
  const CoreCommandValidator();

  List<String> validate(CommandEnvelope command) {
    final errors = <String>[];

    if (command.commandType.isEmpty) {
      errors.add('command_type is required');
    }

    if (command.actorRef.isEmpty) {
      errors.add('actor_ref is required');
    }

    if (command.commandType == 'OpenTableSession' && command.tableId == null) {
      errors.add('OpenTableSession requires table_id');
    }

    return errors;
  }
}
