import 'dart:convert';

import 'package:peerdeal_protocol/peerdeal_protocol.dart';

class CoreCommandValidator {
  const CoreCommandValidator({this.protocolCatalog = const ProtocolCatalog()});

  final ProtocolCatalog protocolCatalog;

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

    _addUnsafeIdentityError(errors, 'command_id', command.commandId);
    _addUnsafeIdentityError(errors, 'command_type', command.commandType);
    _addUnsafeIdentityError(errors, 'command_version', command.commandVersion);
    _addUnsafeIdentityError(
      errors,
      'protocol_version',
      command.protocolVersion,
    );
    _addUnsafeIdentityError(errors, 'issued_at', command.issuedAt);
    _addUnsafeIdentityError(errors, 'actor_ref', command.actorRef);
    _addUnsafeIdentityError(errors, 'table_id', command.tableId);
    _addUnsafeIdentityError(errors, 'session_id', command.sessionId);
    _addUnsafeIdentityError(errors, 'hand_id', command.handId);

    final commandIdentityIsValid =
        command.commandType.trim().isNotEmpty &&
        command.commandVersion.trim().isNotEmpty &&
        command.protocolVersion.trim().isNotEmpty &&
        _isSafeIdentity(command.commandType) &&
        _isSafeIdentity(command.commandVersion) &&
        _isSafeIdentity(command.protocolVersion);
    if (commandIdentityIsValid) {
      final compatibility = protocolCatalog.checkCommandEnvelope(command);
      if (!compatibility.isSupported) {
        if (compatibility.resultCode == ResultCode.errProtocolIncompatible) {
          errors.add('protocol_version is unsupported');
        } else {
          errors.add('command artifact is unsupported');
        }
      }
    }

    if (command.commandType == 'OpenTableSession' &&
        (command.tableId == null || command.tableId!.trim().isEmpty)) {
      errors.add('OpenTableSession requires table_id');
    }

    return errors;
  }

  void _addUnsafeIdentityError(
    List<String> errors,
    String fieldName,
    String? value,
  ) {
    if (value != null && value.trim().isNotEmpty && !_isSafeIdentity(value)) {
      errors.add('$fieldName contains unsafe characters');
    }
  }

  bool _isSafeIdentity(String value) {
    if (value.trim() != value) {
      return false;
    }

    if (utf8.encode(value).length > const CanonicalJsonLimits().maxTextBytes) {
      return false;
    }

    return value.codeUnits.every(
      (unit) => unit >= 0x20 && !(unit >= 0x7f && unit <= 0x9f),
    );
  }
}
