class TransportFrameValidationResult {
  const TransportFrameValidationResult({
    required this.isValid,
    this.warnings = const <String>[],
  });

  const TransportFrameValidationResult.valid()
    : isValid = true,
      warnings = const <String>[];

  final bool isValid;
  final List<String> warnings;
}
