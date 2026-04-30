import 'package:meta/meta.dart';

@immutable
class ValidationResult {
  const ValidationResult({
    required this.isValid,
    this.warnings = const <String>[],
    this.errors = const <String>[],
  });

  final bool isValid;
  final List<String> warnings;
  final List<String> errors;
}

@immutable
class ValidatedSetupPlan {
  const ValidatedSetupPlan({
    required this.planId,
    required this.modeId,
    required this.variantId,
    required this.policyProfileIds,
    required this.resolvedFields,
    required this.validationResult,
    required this.buildReady,
  });

  final String planId;
  final String modeId;
  final String variantId;
  final Map<String, String> policyProfileIds;
  final Map<String, Object?> resolvedFields;
  final ValidationResult validationResult;
  final bool buildReady;
}
