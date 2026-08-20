import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import '../contracts/game_file_compiler.dart';
import '../models/game_file_compile_result.dart';
import '../models/validated_setup_plan.dart';
import '../models/wizard_input_limits.dart';
import '../models/wizard_result_codes.dart';

class DefaultGameFileCompiler implements GameFileCompiler {
  const DefaultGameFileCompiler({this.createdAtFactory});

  final DateTime Function()? createdAtFactory;

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
    if (!plan.buildReady || !plan.validationResult.isValid) {
      final validationMessageError = _validationMessageError(plan);
      final errors = validationMessageError != null
          ? <String>[validationMessageError]
          : plan.validationResult.errors.isEmpty
          ? const <String>['setup_plan_not_build_ready']
          : plan.validationResult.errors;
      return GameFileCompileResult.rejected(
        errors: List<String>.unmodifiable(errors),
        warnings: _safeWarnings(plan),
      );
    }

    final buildReadyErrors = _buildReadyErrors(plan);
    if (buildReadyErrors.isNotEmpty) {
      return GameFileCompileResult.rejected(
        errors: buildReadyErrors,
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

    if (plan.createdBy.trim().isEmpty) {
      errors.add('setup_created_by_missing');
    } else if (!_isSafeMetadataText(plan.createdBy)) {
      errors.add('setup_created_by_invalid');
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
    if (plan.appliedPresetIds.length >
        WizardInputLimits.defaultMaxPresetLayers) {
      errors.add(WizardResultCodes.presetLayerCountTooLarge);
    } else if (plan.appliedPresetIds.any(
      (presetId) => !_isSafeMetadataText(presetId),
    )) {
      errors.add(WizardResultCodes.presetIdsInvalid);
    }
    final validationMessageError = _validationMessageError(plan);
    if (validationMessageError != null) {
      errors.add(validationMessageError);
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
      (codeUnit) => codeUnit < 0x20 || (codeUnit >= 0x7f && codeUnit <= 0x9f),
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

  String? _validationMessageError(ValidatedSetupPlan plan) {
    if (_validationMessageOverflow(plan)) {
      return WizardResultCodes.validationMessageCountTooLarge;
    }
    if (plan.validationResult.errors.any(
          (message) => !_isSafeMetadataText(message),
        ) ||
        plan.validationResult.warnings.any(
          (message) => !_isSafeMetadataText(message),
        )) {
      return WizardResultCodes.validationMessagesInvalid;
    }
    return null;
  }

  List<String> _safeWarnings(ValidatedSetupPlan plan) {
    if (_validationMessageError(plan) != null) {
      return const <String>[];
    }
    return List<String>.unmodifiable(plan.validationResult.warnings);
  }

  Map<String, Object?> _compileBuildReadyPlan(ValidatedSetupPlan plan) {
    final isTournament = plan.modeId == 'tournament';
    final tableName = _safeMetadataValue(
      plan.resolvedFields['table_name'],
      fallback: plan.planId,
    );
    final setupMode = _safeMetadataValue(
      plan.resolvedFields['setup_mode'],
      fallback: 'simple',
    );
    final captureProfile =
        plan.policyProfileIds['capture_profile'] ?? 'capture.protected';
    final privacyProfile =
        plan.policyProfileIds['privacy_profile'] ?? 'privacy.default';
    final networkProfile =
        plan.policyProfileIds['network_profile'] ?? 'network.hybrid_default';
    final retentionProfile =
        plan.policyProfileIds['retention_profile'] ?? 'retention.standard';
    final gameFile = <String, Object?>{
      'game_file_version': '1.0.0',
      'protocol_version': currentProtocolVersion.toWire(),
      'schema_id': 'peerdeal.gamefile',
      'config_id': plan.planId,
      'created_at': (createdAtFactory ?? _defaultCreatedAt)()
          .toUtc()
          .toIso8601String(),
      'created_by': plan.createdBy,
      'mode': <String, Object?>{
        'mode_type': plan.modeId,
        'display_name': plan.modeId == 'open_table'
            ? 'Open Table Mode'
            : 'Tournament Mode',
        'allow_live_join': !isTournament,
        'allow_live_leave': true,
        'session_close_behavior': 'finish_current_hand',
        'supports_personal_ledger': true,
        'supports_receipts': true,
        'supports_spectators': true,
        'supports_cohosts': true,
      },
      'variant': <String, Object?>{
        'variant_id': plan.variantId,
        'display_name': "Texas Hold'em",
        'betting_structure': 'no_limit',
        'hole_card_count': 2,
        'board_card_count': 5,
        'seat_count_min': 2,
        'seat_count_max': 9,
      },
      'table': <String, Object?>{
        'table_name': tableName,
        'seat_count': plan.resolvedFields['seat_count'],
      },
      'session': <String, Object?>{
        'session_type': isTournament ? 'tournament_owned' : 'table_owned',
        'retention_mode': retentionProfile,
      },
      'privacy': <String, Object?>{
        'export_minimal_identity': true,
        'privacy_profile': privacyProfile,
      },
      'capture': <String, Object?>{
        'table_capture_policy': captureProfile,
        'sensitive_view_policy': 'strict',
      },
      'network': <String, Object?>{
        'remote_play_enabled': true,
        'lan_mode_enabled': true,
        'network_profile': networkProfile,
      },
      'roles': <String, Object?>{
        'host_required': true,
        'cohost_enabled': true,
        'spectator_mode': 'invite_only',
      },
      'wizard': <String, Object?>{
        'setup_mode': setupMode,
        'helper_enabled': plan.resolvedFields['helper_enabled'] is bool
            ? plan.resolvedFields['helper_enabled']
            : false,
      },
      'resolved_fields': plan.resolvedFields,
      'policy_profile_ids': plan.policyProfileIds,
      'presets': <String, Object?>{
        'is_preset': plan.appliedPresetIds.isNotEmpty,
        'applied_preset_ids': plan.appliedPresetIds,
      },
      'invite': <String, Object?>{
        'invite_mode': 'private_code_only',
        'invite_code_required': true,
      },
      'validation': <String, Object?>{
        'is_valid': plan.validationResult.isValid,
        'warnings': plan.validationResult.warnings,
        'errors': plan.validationResult.errors,
      },
    };
    final schemaErrors = GameFileSchema().validate(gameFile);
    final compatibility = const ProtocolCatalog().checkGameFileJson(gameFile);
    if (schemaErrors.isNotEmpty || !compatibility.isSupported) {
      throw StateError('Compiled Game File failed protocol validation.');
    }
    return gameFile;
  }

  String _safeMetadataValue(Object? value, {required String fallback}) {
    return value is String && _isSafeMetadataText(value) ? value : fallback;
  }

  static DateTime _defaultCreatedAt() => DateTime.now().toUtc();
}
