import 'package:meta/meta.dart';

import 'model_collection_ownership.dart';

@immutable
class ValidationResult {
  ValidationResult({
    required this.isValid,
    List<String> warnings = const <String>[],
    List<String> errors = const <String>[],
  }) : warnings = List<String>.unmodifiable(warnings),
       errors = List<String>.unmodifiable(errors);

  final bool isValid;
  final List<String> warnings;
  final List<String> errors;
}

@immutable
class ValidatedSetupPlan {
  ValidatedSetupPlan({
    required this.planId,
    required this.modeId,
    required this.variantId,
    this.createdBy = '',
    required Map<String, String> policyProfileIds,
    required Map<String, Object?> resolvedFields,
    List<String> appliedPresetIds = const <String>[],
    required this.validationResult,
    required this.buildReady,
  }) : policyProfileIds = Map<String, String>.unmodifiable(policyProfileIds),
       appliedPresetIds = List<String>.unmodifiable(appliedPresetIds),
       resolvedFields = freezeWizardObjectMap(resolvedFields);

  final String planId;
  final String modeId;
  final String variantId;
  final String createdBy;
  final Map<String, String> policyProfileIds;
  final Map<String, Object?> resolvedFields;
  final List<String> appliedPresetIds;
  final ValidationResult validationResult;
  final bool buildReady;
}
