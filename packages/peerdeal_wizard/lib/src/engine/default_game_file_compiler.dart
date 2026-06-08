import '../contracts/game_file_compiler.dart';
import '../models/game_file_compile_result.dart';
import '../models/validated_setup_plan.dart';

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
      final errors = plan.validationResult.errors.isEmpty
          ? buildReadyErrors.isEmpty
                ? const <String>['setup_plan_not_build_ready']
                : buildReadyErrors
          : plan.validationResult.errors;
      return GameFileCompileResult.rejected(
        errors: List<String>.unmodifiable(errors),
        warnings: List<String>.unmodifiable(plan.validationResult.warnings),
      );
    }

    try {
      return GameFileCompileResult.compiled(
        gameFile: _compileBuildReadyPlan(plan),
        warnings: List<String>.unmodifiable(plan.validationResult.warnings),
      );
    } on Object {
      return GameFileCompileResult.rejected(
        errors: const <String>['game_file_compile_failed'],
        warnings: List<String>.unmodifiable(plan.validationResult.warnings),
      );
    }
  }

  List<String> _buildReadyErrors(ValidatedSetupPlan plan) {
    final errors = <String>[];
    if (plan.planId.trim().isEmpty) {
      errors.add('setup_plan_id_missing');
    }

    if (plan.modeId != 'open_table' && plan.modeId != 'tournament') {
      errors.add('unsupported_mode_id');
    }

    if (plan.variantId != 'holdem_nlhe') {
      errors.add('unsupported_variant_id');
    }

    return List<String>.unmodifiable(errors);
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
