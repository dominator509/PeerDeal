class GameFileSchema {
  static const requiredTopLevelKeys = <String>{
    'game_file_version',
    'protocol_version',
    'schema_id',
    'config_id',
    'created_at',
    'created_by',
    'mode',
    'variant',
    'table',
    'session',
    'privacy',
    'capture',
    'network',
    'roles',
    'wizard',
    'presets',
    'invite',
    'validation',
  };

  List<String> validate(Map<String, Object?> input) {
    final errors = <String>[];

    for (final key in requiredTopLevelKeys) {
      if (!input.containsKey(key)) {
        errors.add('Missing key: $key');
      }
    }

    if (input['schema_id'] != 'peerdeal.gamefile') {
      errors.add('schema_id must be peerdeal.gamefile');
    }

    final mode = input['mode'];
    if (mode is! Map<String, Object?>) {
      errors.add('mode must be an object');
    } else {
      final modeType = mode['mode_type'];
      if (modeType != 'tournament' && modeType != 'open_table') {
        errors.add('mode.mode_type must be tournament or open_table');
      }
    }

    final variant = input['variant'];
    if (variant is! Map<String, Object?>) {
      errors.add('variant must be an object');
    } else if (variant['variant_id'] == null) {
      errors.add('variant.variant_id is required');
    }

    return errors;
  }

  bool isValid(Map<String, Object?> input) => validate(input).isEmpty;
}
