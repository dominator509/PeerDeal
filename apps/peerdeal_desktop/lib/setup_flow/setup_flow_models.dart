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

const _maximumSetupOutcomeMessageCount = 4;

List<String> _safeSetupOutcomeMessages(
  List<String> messages, {
  required String fallback,
  required String truncationMessage,
}) {
  final safeMessages = messages
      .take(_maximumSetupOutcomeMessageCount)
      .map((message) => _isSafeSetupToken(message) ? message : fallback)
      .toList();
  if (messages.length > _maximumSetupOutcomeMessageCount) {
    safeMessages.add(truncationMessage);
  }
  return List<String>.unmodifiable(safeMessages);
}

bool _isSafeSetupToken(String value) {
  if (value.trim() != value || value.isEmpty || value.length > 80) {
    return false;
  }
  return value.codeUnits.every(_isSafeSetupTokenCodeUnit);
}

bool _isSafeSetupTokenCodeUnit(int codeUnit) {
  return (codeUnit >= 0x30 && codeUnit <= 0x39) ||
      (codeUnit >= 0x41 && codeUnit <= 0x5A) ||
      (codeUnit >= 0x61 && codeUnit <= 0x7A) ||
      codeUnit == 0x2D ||
      codeUnit == 0x2E ||
      codeUnit == 0x5F;
}

class SetupFlowOutcome {
  SetupFlowOutcome({
    required this.status,
    required this.resultCode,
    Map<String, Object?>? gameFile,
    List<String> errors = const <String>[],
    List<String> warnings = const <String>[],
  }) : gameFile = gameFile == null ? null : _freezeSetupObjectMap(gameFile),
       errors = _safeSetupOutcomeMessages(
         errors,
         fallback: 'setup_error_unavailable',
         truncationMessage: 'setup_errors_truncated',
       ),
       warnings = _safeSetupOutcomeMessages(
         warnings,
         fallback: 'setup_warning_unavailable',
         truncationMessage: 'setup_warnings_truncated',
       );

  final SetupFlowStatus status;
  final String resultCode;
  final Map<String, Object?>? gameFile;
  final List<String> errors;
  final List<String> warnings;
}
