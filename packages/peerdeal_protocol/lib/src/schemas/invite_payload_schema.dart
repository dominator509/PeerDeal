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

  List<String> validate(Map<String, Object?> input) {
    final errors = <String>[];

    for (final key in requiredKeys) {
      if (!input.containsKey(key)) {
        errors.add('Missing key: $key');
      }
    }

    final roleHint = input['role_hint'];
    const allowedRoles = {'player', 'spectator', 'cohost'};
    if (!allowedRoles.contains(roleHint)) {
      errors.add('role_hint must be player, spectator, or cohost');
    }

    return errors;
  }
}
