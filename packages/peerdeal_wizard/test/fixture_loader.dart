import 'dart:convert';
import 'dart:io';

import 'package:peerdeal_wizard/peerdeal_wizard.dart';

Map<String, Object?> loadFixture(String name) {
  final file = File('test/fixtures/$name');
  return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
}

SetupIntent loadSetupIntentFixture(String name) {
  final json = loadFixture(name);
  final rawHelperSuggestions = json['helper_suggestions'];
  if (rawHelperSuggestions != null && rawHelperSuggestions is! List) {
    throw const FormatException('helper_suggestions must be an array.');
  }
  final helperSuggestionsJson = rawHelperSuggestions == null
      ? const <Object?>[]
      : rawHelperSuggestions as List;

  final helperSuggestions = <HelperSuggestion>[];
  for (final rawSuggestion in helperSuggestionsJson) {
    if (rawSuggestion is! Map) {
      throw const FormatException(
        'helper_suggestions entries must be objects.',
      );
    }
    final suggestion = rawSuggestion.cast<String, Object?>();
    helperSuggestions.add(
      HelperSuggestion(
        key: _requiredString(suggestion, 'key'),
        value: suggestion['value'],
        reason: _requiredString(suggestion, 'reason'),
        confidence: _optionalDouble(suggestion, 'confidence') ?? 0.5,
      ),
    );
  }

  return SetupIntent(
    intentId: _requiredString(json, 'intent_id'),
    sourceType: _setupSurface(_requiredString(json, 'source_type')),
    hostPseudonymousId: _requiredString(json, 'host_pseudonymous_id'),
    promptText: _optionalString(json, 'prompt_text'),
    modePreference: _optionalString(json, 'mode_preference'),
    variantPreference: _optionalString(json, 'variant_preference'),
    seatCountPreference: _optionalInt(json, 'seat_count_preference'),
    speedPreference: _optionalString(json, 'speed_preference'),
    privacyPreference: _optionalString(json, 'privacy_preference'),
    capturePreference: _optionalString(json, 'capture_preference'),
    partialSettings: _requiredMap(json, 'partial_settings'),
    presetRefs: _stringList(json, 'preset_refs'),
    helperEnabled: _optionalBool(json, 'helper_enabled') ?? false,
    helperSuggestions: helperSuggestions,
    ambiguities: _stringList(json, 'ambiguities'),
  );
}

List<PresetLayer> loadPresetLayersFixture(String name) {
  final json = loadFixture(name);
  final rawLayers = json['layers'];
  if (rawLayers is! List) {
    throw const FormatException('layers must be an array.');
  }

  final layers = <PresetLayer>[];
  for (final rawLayer in rawLayers) {
    if (rawLayer is! Map) {
      throw const FormatException('layers entries must be objects.');
    }
    final layer = rawLayer.cast<String, Object?>();
    layers.add(
      PresetLayer(
        presetId: _requiredString(layer, 'preset_id'),
        priority: _requiredInt(layer, 'priority'),
        values: _requiredMap(layer, 'values'),
        isLockedBuiltin: _optionalBool(layer, 'is_locked_builtin') ?? false,
      ),
    );
  }
  return List<PresetLayer>.unmodifiable(layers);
}

SetupSurface _setupSurface(String value) {
  switch (value) {
    case 'simple':
      return SetupSurface.simple;
    case 'advanced':
      return SetupSurface.advanced;
    case 'conversational':
      return SetupSurface.conversational;
    case 'preset':
      return SetupSurface.preset;
    default:
      throw FormatException('Unsupported setup surface: $value.');
  }
}

String _requiredString(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is String) return value;
  throw FormatException('$key must be a string.');
}

int _requiredInt(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is int) return value;
  throw FormatException('$key must be an integer.');
}

Map<String, Object?> _requiredMap(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is Map) return value.cast<String, Object?>();
  throw FormatException('$key must be an object.');
}

String? _optionalString(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is String) return value;
  throw FormatException('$key must be a string.');
}

int? _optionalInt(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is int) return value;
  throw FormatException('$key must be an integer.');
}

double? _optionalDouble(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is num) return value.toDouble();
  throw FormatException('$key must be a number.');
}

bool? _optionalBool(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is bool) return value;
  throw FormatException('$key must be a boolean.');
}

List<String> _stringList(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value == null) return const <String>[];
  if (value is! List || value.any((entry) => entry is! String)) {
    throw FormatException('$key must be an array of strings.');
  }
  return List<String>.unmodifiable(value.cast<String>());
}
