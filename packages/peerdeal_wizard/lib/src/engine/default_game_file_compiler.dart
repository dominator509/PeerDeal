import '../contracts/game_file_compiler.dart';
import '../models/validated_setup_plan.dart';

class DefaultGameFileCompiler implements GameFileCompiler {
  const DefaultGameFileCompiler();

  @override
  Map<String, Object?> compile(ValidatedSetupPlan plan) {
    if (!plan.buildReady || !plan.validationResult.isValid) {
      throw StateError('ValidatedSetupPlan is not build-ready.');
    }

    return <String, Object?>{
      'game_file_version': '1.0.0',
      'protocol_version': '1.x',
      'schema_id': 'peerdeal.gamefile',
      'config_id': plan.planId,
      'mode': <String, Object?>{
        'mode_type': plan.modeId,
        'display_name': plan.modeId == 'open_table' ? 'Open Table Mode' : 'Tournament Mode',
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
