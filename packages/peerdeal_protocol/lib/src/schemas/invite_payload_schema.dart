class InvitePayloadSchema {
  static const requiredKeys = <String>{
    'invite_version',
    'invite_id',
    'config_id',
    'session_id',
    'table_id',
    'mode_type',
    'variant_id',
    'protocol_version',
    'invite_code',
    'role_hint',
    'signature',
  };

  static const _requiredTextKeys = <String>{
    'invite_version',
    'invite_id',
    'config_id',
    'session_id',
    'table_id',
    'mode_type',
    'variant_id',
    'protocol_version',
    'invite_code',
    'role_hint',
    'signature',
  };

  List<String> validate(Map<String, Object?> input) {
    final errors = <String>[];

    for (final key in requiredKeys) {
      if (!input.containsKey(key)) {
        errors.add('Missing key: $key');
      }
    }

    for (final key in _requiredTextKeys) {
      if (!input.containsKey(key)) {
        continue;
      }
      final value = input[key];
      if (value is! String) {
        errors.add('$key must be a string');
        continue;
      }
      if (value.trim().isEmpty || value.trim() != value) {
        errors.add('$key must be non-empty and unpadded');
      }
      if (value.codeUnits.any(
        (unit) => unit < 0x20 || (unit >= 0x7f && unit <= 0x9f),
      )) {
        errors.add('$key contains a control character');
      }
    }

    final modeType = input['mode_type'];
    if (modeType is String &&
        modeType != 'tournament' &&
        modeType != 'open_table') {
      errors.add('mode_type must be tournament or open_table');
    }

    final roleHint = input['role_hint'];
    const allowedRoles = {'player', 'spectator', 'cohost'};
    if (roleHint is String && !allowedRoles.contains(roleHint)) {
      errors.add('role_hint must be player, spectator, or cohost');
    }

    return errors;
  }
}
