import '../contracts/preset_resolver.dart';
import '../models/preset_models.dart';
import '../models/resolved_setup_draft.dart';
import '../models/setup_intent.dart';
import '../models/validated_setup_plan.dart';

class DefaultPresetResolver implements PresetResolver {
  const DefaultPresetResolver();

  @override
  PresetResolutionResult mergeLayers(List<PresetLayer> layers) {
    final ordered = [...layers]..sort((a, b) => a.priority.compareTo(b.priority));
    final merged = <String, Object?>{};
    final conflicts = <String>[];

    for (final layer in ordered) {
      for (final entry in layer.values.entries) {
        if (merged.containsKey(entry.key) && merged[entry.key] != entry.value) {
          conflicts.add('Conflict on ${entry.key} resolved in favor of ${layer.presetId}.');
        }
        merged[entry.key] = entry.value;
      }
    }

    return PresetResolutionResult(
      mergedValues: merged,
      appliedPresetIds: ordered.map((layer) => layer.presetId).toList(growable: false),
      conflicts: conflicts,
    );
  }

  @override
  ResolvedSetupDraft resolveIntent({
    required SetupIntent intent,
    required List<PresetLayer> presetLayers,
  }) {
    final presetResolution = mergeLayers(presetLayers);
    final resolved = <String, Object?>{
      ...presetResolution.mergedValues,
      ...intent.partialSettings,
    };

    final helperApplied = <String>[];
    if (intent.helperEnabled) {
      for (final suggestion in intent.helperSuggestions) {
        resolved.putIfAbsent(suggestion.key, () {
          helperApplied.add(suggestion.key);
          return suggestion.value;
        });
      }
    }

    final modeId = (intent.modePreference ?? resolved['mode_type'] ?? 'open_table').toString();
    final variantId = (intent.variantPreference ?? resolved['variant_id'] ?? 'holdem_nlhe').toString();

    if (intent.seatCountPreference != null) {
      resolved['seat_count'] = intent.seatCountPreference;
    }
    if (intent.capturePreference != null) {
      resolved['table_capture_policy'] = intent.capturePreference;
    }
    if (intent.privacyPreference != null) {
      resolved['retention_profile'] = intent.privacyPreference;
    }

    final unresolvedIssues = <String>[...intent.ambiguities];
    if (resolved['seat_count'] == null) {
      unresolvedIssues.add('seat_count_missing');
    }

    return ResolvedSetupDraft(
      intentId: intent.intentId,
      modeId: modeId,
      variantId: variantId,
      resolvedFields: resolved,
      appliedPresetIds: presetResolution.appliedPresetIds,
      unresolvedIssues: unresolvedIssues,
      helperApplied: helperApplied,
    );
  }

  @override
  ValidatedSetupPlan validateDraft(ResolvedSetupDraft draft) {
    final errors = <String>[];
    final warnings = <String>[];

    if (draft.unresolvedIssues.isNotEmpty) {
      errors.addAll(draft.unresolvedIssues);
    }

    final seatCount = draft.resolvedFields['seat_count'];
    if (seatCount is! int || seatCount < 2 || seatCount > 9) {
      errors.add('seat_count_out_of_range');
    }

    final modeId = draft.modeId;
    if (modeId != 'open_table' && modeId != 'tournament') {
      errors.add('unsupported_mode_id');
    }

    if (draft.variantId != 'holdem_nlhe') {
      errors.add('unsupported_variant_id');
    }

    final policyProfiles = <String, String>{
      'privacy_profile': (draft.resolvedFields['retention_profile'] ?? 'privacy.default').toString(),
      'capture_profile': (draft.resolvedFields['table_capture_policy'] ?? 'capture.protected').toString(),
      'network_profile': 'network.hybrid_default',
      'retention_profile': (draft.resolvedFields['retention_profile'] ?? 'retention.standard').toString(),
    };

    return ValidatedSetupPlan(
      planId: 'plan_${draft.intentId}',
      modeId: draft.modeId,
      variantId: draft.variantId,
      policyProfileIds: policyProfiles,
      resolvedFields: draft.resolvedFields,
      validationResult: ValidationResult(
        isValid: errors.isEmpty,
        warnings: warnings,
        errors: errors,
      ),
      buildReady: errors.isEmpty,
    );
  }
}
