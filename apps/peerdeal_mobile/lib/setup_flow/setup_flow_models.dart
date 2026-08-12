enum SetupFlowStatus { compiled, rejected }

Object? _freezeSetupValue(Object? value) {
  if (value is Map) {
    final frozenEntries = <Object?, Object?>{};
    for (final entry in value.entries) {
      frozenEntries[entry.key] = _freezeSetupValue(entry.value);
    }
    return Map<Object?, Object?>.unmodifiable(frozenEntries);
  }
  if (value is List) {
    return List<Object?>.unmodifiable(value.map<Object?>(_freezeSetupValue));
  }
  if (value is Set) {
    return Set<Object?>.unmodifiable(value.map<Object?>(_freezeSetupValue));
  }
  return value;
}

Map<String, Object?> _freezeSetupObjectMap(Map<String, Object?> source) {
  return Map<String, Object?>.unmodifiable(<String, Object?>{
    for (final entry in source.entries)
      entry.key: _freezeSetupValue(entry.value),
  });
}

class SetupFlowOutcome {
  SetupFlowOutcome({
    required this.status,
    required this.resultCode,
    Map<String, Object?>? gameFile,
    List<String> errors = const <String>[],
    List<String> warnings = const <String>[],
  }) : gameFile = gameFile == null ? null : _freezeSetupObjectMap(gameFile),
       errors = List<String>.unmodifiable(errors),
       warnings = List<String>.unmodifiable(warnings);

  final SetupFlowStatus status;
  final String resultCode;
  final Map<String, Object?>? gameFile;
  final List<String> errors;
  final List<String> warnings;
}
