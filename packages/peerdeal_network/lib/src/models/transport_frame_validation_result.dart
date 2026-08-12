class TransportFrameValidationResult {
  TransportFrameValidationResult({
    required this.isValid,
    List<String> warnings = const <String>[],
  }) : warnings = List<String>.unmodifiable(warnings);

  const TransportFrameValidationResult.valid()
    : isValid = true,
      warnings = const <String>[];

  final bool isValid;
  final List<String> warnings;
}
