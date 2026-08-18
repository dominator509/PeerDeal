import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import '../contracts/game_file_compiler.dart';
import '../models/game_file_compile_result.dart';
import '../models/validated_setup_plan.dart';
import '../models/wizard_input_limits.dart';
import '../models/wizard_result_codes.dart';

class DefaultGameFileCompiler implements GameFileCompiler {
  const DefaultGameFileCompiler();

  @override
  Map<String, Object?> compile(ValidatedSetupPlan plan) {
    final buildReadyErrors = _buildReadyErrors(plan);
    if (!plan.buildReady ||
        !plan.validationResult.isValid ||
        buildReadyErrors.isNotEmpty) {
      throw StateError('ValidatedSetupPlan is not build-ready.');
    }

    return _compileBuildReadyPlan(plan);
  }

  @override
  GameFileCompileResult tryCompile(ValidatedSetupPlan plan) {
    final buildReadyErrors = _buildReadyErrors(plan);
    if (!plan.buildReady ||
        !plan.validationResult.isValid ||
        buildReadyErrors.isNotEmpty) {
      final errors = _validationMessageOverflow(plan)
          ? const <String>[WizardResultCodes.validationMessageCountTooLarge]
          : plan.validationResult.errors.isEmpty
          ? buildReadyErrors.isEmpty
                ? const <String>['setup_plan_not_build_ready']
                : buildReadyErrors
          : plan.validationResult.errors;
      return GameFileCompileResult.rejected(
        errors: List<String>.unmodifiable(errors),
        warnings: _safeWarnings(plan),
      );
    }

    try {
      return GameFileCompileResult.compiled(
        gameFile: _compileBuildReadyPlan(plan),
        warnings: _safeWarnings(plan),
      );
    } on Object {
      return GameFileCompileResult.rejected(
        errors: const <String>['game_file_compile_failed'],
        warnings: _safeWarnings(plan),
      );
    }
  }

  List<String> _buildReadyErrors(ValidatedSetupPlan plan) {
    final errors = <String>[];
    if (plan.planId.trim().isEmpty) {
      errors.add('setup_plan_id_missing');
    } else if (!_isSafeMetadataText(plan.planId)) {
      errors.add(WizardResultCodes.planIdInvalid);
    }

    if (plan.modeId != 'open_table' && plan.modeId != 'tournament') {
      errors.add('unsupported_mode_id');
    }

    if (plan.variantId != 'holdem_nlhe') {
      errors.add('unsupported_variant_id');
    }

    if (plan.resolvedFields.length >
        WizardInputLimits.defaultMaxResolvedFields) {
      errors.add(WizardResultCodes.resolvedFieldCountTooLarge);
    } else if (!_isCanonicalJsonBounded(
      plan.resolvedFields,
      maxMapEntries: WizardInputLimits.defaultMaxResolvedFields,
    )) {
      errors.add(WizardResultCodes.resolvedFieldsInvalid);
    }
    if (plan.policyProfileIds.length >
        WizardInputLimits.defaultMaxPolicyProfileIds) {
      errors.add(WizardResultCodes.policyProfileCountTooLarge);
    } else if (!_isCanonicalJsonBounded(
      plan.policyProfileIds,
      maxMapEntries: WizardInputLimits.defaultMaxPolicyProfileIds,
    ) ||
        !_hasSafePolicyProfileMetadata(plan.policyProfileIds)) {
      errors.add(WizardResultCodes.policyProfilesInvalid);
    }
    if (plan.validationResult.errors.length >
            WizardInputLimits.defaultMaxValidationMessages ||
        plan.validationResult.warnings.length >
            WizardInputLimits.defaultMaxValidationMessages) {
      errors.add(WizardResultCodes.validationMessageCountTooLarge);
    }

    return List<String>.unmodifiable(errors);
  }

  bool _isCanonicalJsonBounded(Object? value, {required int maxMapEntries}) {
    try {
      canonicalJsonEncode(
        value,
        limits: CanonicalJsonLimits(
          maxMapEntries: maxMapEntries,
          maxListItems: WizardInputLimits.defaultMaxValidationMessages,
          maxDepth: WizardInputLimits.defaultMaxCanonicalDepth,
          maxTextBytes: WizardInputLimits.defaultMaxCanonicalTextBytes,
          maxNodes: WizardInputLimits.defaultMaxCanonicalNodes,
          maxEncodedBytes: WizardInputLimits.defaultMaxCanonicalEncodedBytes,
        ),
      );
      return true;
    } on Object {
      return false;
    }
  }

  bool _hasSafePolicyProfileMetadata(Map<String, String> profiles) {
    return profiles.entries.every(
      (entry) =>
          _isSafeMetadataText(entry.key) && _isSafeMetadataText(entry.value),
    );
  }

  bool _isSafeMetadataText(String value) {
    if (value.trim().isEmpty || value.trim() != value) return false;
    if (value.codeUnits.any(
      (codeUnit) =>
          codeUnit < 0x20 || (codeUnit >= 0x7f && codeUnit <= 0x9f),
    )) {
      return false;
    }
    return _isCanonicalJsonBounded(value, maxMapEntries: 1);
  }

  bool _validationMessageOverflow(ValidatedSetupPlan plan) {
    return plan.validationResult.errors.length >
            WizardInputLimits.defaultMaxValidationMessages ||
        plan.validationResult.warnings.length >
            WizardInputLimits.defaultMaxValidationMessages;
  }

  List<String> _safeWarnings(ValidatedSetupPlan plan) {
    if (_validationMessageOverflow(plan)) {
      return const <String>[];
    }
    return List<String>.unmodifiable(plan.validationResult.warnings);
  }

  Map<String, Object?> _compileBuildReadyPlan(ValidatedSetupPlan plan) {
    return <String, Object?>{
      'game_file_version': '1.0.0',
      'protocol_version': '1.x',
      'schema_id': 'peerdeal.gamefile',
      'config_id': plan.planId,
      'mode': <String, Object?>{
        'mode_type': plan.modeId,
        'display_name': plan.modeId == 'open_table'
            ? 'Open Table Mode'
            : 'Tournament Mode',
      },
      'variant': <String, Object?>{
        'variant_id': plan.variantId,
        'display_name': "Texas Hold'em",
      },
      'wizard': <String, Object?>{
        'setup_mode': plan.resolvedFields['setup_mode'] ?? 'simple',
        'helper_enabled': plan.resolvedFields['helper_enabled'] ?? false,
      },
      'resolved_fields': plan.resolvedFields,
      'policy_profile_ids': plan.policyProfileIds,
      'validation': <String, Object?>{
        'is_valid': plan.validationResult.isValid,
        'warnings': plan.validationResult.warnings,
        'errors': plan.validationResult.errors,
      },
    };
  }
}
