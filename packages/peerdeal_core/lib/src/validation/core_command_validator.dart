import 'package:peerdeal_protocol/peerdeal_protocol.dart';

class CoreCommandValidator {
  const CoreCommandValidator();

  List<String> validate(CommandEnvelope command) {
    final errors = <String>[];

    if (command.commandId.trim().isEmpty) {
      errors.add('command_id is required');
    }

    if (command.commandType.trim().isEmpty) {
      errors.add('command_type is required');
    }

    if (command.commandVersion.trim().isEmpty) {
      errors.add('command_version is required');
    }

    if (command.protocolVersion.trim().isEmpty) {
      errors.add('protocol_version is required');
    }

    if (command.issuedAt.trim().isEmpty) {
      errors.add('issued_at is required');
    }

    if (command.actorRef.trim().isEmpty) {
      errors.add('actor_ref is required');
    }

    if (command.commandType == 'OpenTableSession' &&
        (command.tableId == null || command.tableId!.trim().isEmpty)) {
      errors.add('OpenTableSession requires table_id');
    }

    return errors;
  }
}
