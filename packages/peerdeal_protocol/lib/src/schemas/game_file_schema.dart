import '../serialization/canonical_json.dart';
import '../serialization/canonical_json_limits.dart';

class GameFileSchema {
  static const _textLimits = CanonicalJsonLimits();

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

  static const _requiredTextKeys = <String>{
    'game_file_version',
    'protocol_version',
    'config_id',
    'created_at',
    'created_by',
  };

  static const _requiredObjectKeys = <String>{
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

    try {
      canonicalJsonEncode(input);
    } on Object {
      errors.add('Game File payload exceeds canonical protocol limits');
    }

    for (final key in requiredTopLevelKeys) {
      if (!input.containsKey(key)) {
        errors.add('Missing key: $key');
      }
    }

    if (input['schema_id'] != 'peerdeal.gamefile') {
      errors.add('schema_id must be peerdeal.gamefile');
    }

    for (final key in _requiredTextKeys) {
      if (!input.containsKey(key)) continue;
      _validateTextField(key, input[key], errors);
    }

    for (final key in _requiredObjectKeys) {
      if (input.containsKey(key) && input[key] is! Map) {
        errors.add('$key must be an object');
      }
    }

    final mode = input['mode'];
    if (mode is Map) {
      final modeType = mode['mode_type'];
      if (modeType is! String) {
        errors.add('mode.mode_type must be a string');
      } else if (modeType != 'tournament' && modeType != 'open_table') {
        errors.add('mode.mode_type must be tournament or open_table');
      }
    }

    final variant = input['variant'];
    if (variant is Map) {
      if (!variant.containsKey('variant_id') || variant['variant_id'] == null) {
        errors.add('variant.variant_id is required');
      } else {
        _validateTextField('variant.variant_id', variant['variant_id'], errors);
      }
    }

    return errors;
  }

  bool isValid(Map<String, Object?> input) => validate(input).isEmpty;

  static void _validateTextField(
    String key,
    Object? value,
    List<String> errors,
  ) {
    if (value is! String) {
      errors.add('$key must be a string');
      return;
    }
    if (value.trim().isEmpty || value.trim() != value) {
      errors.add('$key must be non-empty and unpadded');
    }
    if (!_textLimits.isWithinUtf8TextLimit(value)) {
      errors.add('$key exceeds the protocol UTF-8 text byte limit');
    }
    if (value.codeUnits.any(
      (unit) => unit < 0x20 || (unit >= 0x7f && unit <= 0x9f),
    )) {
      errors.add('$key contains a control character');
    }
  }
}
