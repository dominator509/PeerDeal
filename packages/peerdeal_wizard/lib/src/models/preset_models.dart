import 'package:meta/meta.dart';

@immutable
class PresetLayer {
  const PresetLayer({
    required this.presetId,
    required this.priority,
    required this.values,
    this.isLockedBuiltin = false,
  });

  final String presetId;
  final int priority;
  final Map<String, Object?> values;
  final bool isLockedBuiltin;
}

@immutable
class PresetResolutionResult {
  const PresetResolutionResult({
    required this.mergedValues,
    required this.appliedPresetIds,
    this.conflicts = const <String>[],
  });

  final Map<String, Object?> mergedValues;
  final List<String> appliedPresetIds;
  final List<String> conflicts;
}
