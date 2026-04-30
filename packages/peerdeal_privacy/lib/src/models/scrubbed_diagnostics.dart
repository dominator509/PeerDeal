class ScrubbedDiagnostics {
  const ScrubbedDiagnostics({
    required this.rawKeysRemoved,
    required this.redactedFields,
    required this.payload,
  });

  final int rawKeysRemoved;
  final List<String> redactedFields;
  final Map<String, Object?> payload;
}
