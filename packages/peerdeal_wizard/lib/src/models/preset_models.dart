import 'package:meta/meta.dart';

import 'model_collection_ownership.dart';

@immutable
class PresetLayer {
  PresetLayer({
    required this.presetId,
    required this.priority,
    required Map<String, Object?> values,
    this.isLockedBuiltin = false,
  }) : values = freezeWizardObjectMap(values);

  final String presetId;
  final int priority;
  final Map<String, Object?> values;
  final bool isLockedBuiltin;
}

@immutable
class PresetResolutionResult {
  PresetResolutionResult({
    required Map<String, Object?> mergedValues,
    required List<String> appliedPresetIds,
    List<String> conflicts = const <String>[],
    List<String> errors = const <String>[],
  }) : mergedValues = freezeWizardObjectMap(mergedValues),
       appliedPresetIds = List<String>.unmodifiable(appliedPresetIds),
       conflicts = List<String>.unmodifiable(conflicts),
       errors = List<String>.unmodifiable(errors);

  final Map<String, Object?> mergedValues;
  final List<String> appliedPresetIds;
  final List<String> conflicts;
  final List<String> errors;
}
