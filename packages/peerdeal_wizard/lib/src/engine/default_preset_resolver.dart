import 'dart:convert';

import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import '../contracts/preset_resolver.dart';
import '../models/preset_models.dart';
import '../models/resolved_setup_draft.dart';
import '../models/setup_intent.dart';
import '../models/validated_setup_plan.dart';
import '../models/wizard_input_limits.dart';
import '../models/wizard_result_codes.dart';

class DefaultPresetResolver implements PresetResolver {
  const DefaultPresetResolver({
    this.maxPresetLayers = WizardInputLimits.defaultMaxPresetLayers,
    this.maxPresetValues = WizardInputLimits.defaultMaxPresetValues,
    this.maxMergedValues = WizardInputLimits.defaultMaxMergedValues,
    this.maxConflicts = WizardInputLimits.defaultMaxConflicts,
    this.maxHelperSuggestions = WizardInputLimits.defaultMaxHelperSuggestions,
    this.maxPartialSettings = WizardInputLimits.defaultMaxPartialSettings,
    this.maxAmbiguities = WizardInputLimits.defaultMaxAmbiguities,
    this.maxResolvedFields = WizardInputLimits.defaultMaxResolvedFields,
  });

  final int maxPresetLayers;
  final int maxPresetValues;
  final int maxMergedValues;
  final int maxConflicts;
  final int maxHelperSuggestions;
  final int maxPartialSettings;
  final int maxAmbiguities;
  final int maxResolvedFields;

  @override
  PresetResolutionResult mergeLayers(List<PresetLayer> layers) {
    _validateConfiguration();
    if (layers.length > maxPresetLayers) {
      return _blockedResolution(WizardResultCodes.presetLayerCountTooLarge);
    }

    final ordered = [...layers]
      ..sort((a, b) => a.priority.compareTo(b.priority));
    final merged = <String, Object?>{};
    final conflicts = <String>[];

    for (final layer in ordered) {
      if (layer.values.length > maxPresetValues) {
        return _blockedResolution(WizardResultCodes.presetValueCountTooLarge);
      }
      if (!_isCanonicalJsonBounded(
        layer.values,
        maxMapEntries: maxPresetValues,
      )) {
        return _blockedResolution(WizardResultCodes.presetValuesInvalid);
      }

      for (final entry in layer.values.entries) {
        if (!merged.containsKey(entry.key) &&
            merged.length >= maxMergedValues) {
          return _blockedResolution(WizardResultCodes.mergedValueCountTooLarge);
        }
        if (merged.containsKey(entry.key) && merged[entry.key] != entry.value) {
          if (conflicts.length >= maxConflicts) {
            return _blockedResolution(WizardResultCodes.conflictCountTooLarge);
          }
          conflicts.add(
            'Conflict on ${entry.key} resolved in favor of ${layer.presetId}.',
          );
        }
        merged[entry.key] = entry.value;
      }
    }

    return PresetResolutionResult(
      mergedValues: merged,
      appliedPresetIds: ordered
          .map((layer) => layer.presetId)
          .toList(growable: false),
      conflicts: conflicts,
    );
  }

  @override
  ResolvedSetupDraft resolveIntent({
    required SetupIntent intent,
    required List<PresetLayer> presetLayers,
  }) {
    _validateConfiguration();
    final intentId = intent.intentId.trim();
    final hostPseudonymousId = intent.hostPseudonymousId.trim();
    final intentInputError = _intentInputError(intent);
    if (intentInputError != null) {
      return _blockedDraft(intentId, intentInputError);
    }

    if (presetLayers.length > maxPresetLayers) {
      return _blockedDraft(
        intentId,
        WizardResultCodes.presetLayerCountTooLarge,
      );
    }
    final selectedPresetLayers = _selectPresetLayers(
      intent.presetRefs,
      presetLayers,
    );
    if (selectedPresetLayers == null) {
      return _blockedDraft(intentId, WizardResultCodes.presetIdsInvalid);
    }

    final presetResolution = mergeLayers(selectedPresetLayers);
    if (presetResolution.errors.isNotEmpty) {
      return _blockedDraft(intentId, presetResolution.errors.first);
    }

    final resolved = <String, Object?>{
      ...presetResolution.mergedValues,
      ...intent.partialSettings,
    };
    if (resolved.length > maxResolvedFields ||
        !_isCanonicalJsonBounded(resolved, maxMapEntries: maxResolvedFields)) {
      return _blockedDraft(
        intentId,
        resolved.length > maxResolvedFields
            ? WizardResultCodes.resolvedFieldCountTooLarge
            : WizardResultCodes.resolvedFieldsInvalid,
      );
    }

    final helperApplied = <String>[];
    if (intent.helperEnabled) {
      for (final suggestion in intent.helperSuggestions) {
        if (!_isCanonicalJsonBounded(<String, Object?>{
          suggestion.key: suggestion.value,
        }, maxMapEntries: 1)) {
          return _blockedDraft(
            intentId,
            WizardResultCodes.helperSuggestionInvalid,
          );
        }
        if (!resolved.containsKey(suggestion.key) &&
            resolved.length >= maxResolvedFields) {
          return _blockedDraft(
            intentId,
            WizardResultCodes.resolvedFieldCountTooLarge,
          );
        }
        resolved.putIfAbsent(suggestion.key, () {
          helperApplied.add(suggestion.key);
          return suggestion.value;
        });
      }
    }

    final modeId = _safeSelectionId(
      intent.modePreference ?? resolved['mode_type'] ?? 'open_table',
    );
    final variantId = _safeSelectionId(
      intent.variantPreference ?? resolved['variant_id'] ?? 'holdem_nlhe',
    );

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
    if (intentId.isEmpty) {
      unresolvedIssues.add('setup_intent_id_missing');
    }
    if (hostPseudonymousId.isEmpty) {
      unresolvedIssues.add('setup_host_missing');
    }
    if (resolved['seat_count'] == null) {
      unresolvedIssues.add('seat_count_missing');
    }

    return ResolvedSetupDraft(
      intentId: intentId,
      modeId: modeId,
      variantId: variantId,
      hostPseudonymousId: hostPseudonymousId,
      resolvedFields: resolved,
      appliedPresetIds: presetResolution.appliedPresetIds,
      unresolvedIssues: unresolvedIssues,
      helperApplied: helperApplied,
    );
  }

  @override
  ValidatedSetupPlan validateDraft(ResolvedSetupDraft draft) {
    _validateConfiguration();
    final errors = <String>[];
    final warnings = <String>[];

    if (draft.unresolvedIssues.length > maxAmbiguities) {
      errors.add(WizardResultCodes.ambiguityCountTooLarge);
    } else if (draft.unresolvedIssues.isNotEmpty) {
      errors.addAll(draft.unresolvedIssues);
    }
    if (draft.appliedPresetIds.length > maxPresetLayers) {
      errors.add(WizardResultCodes.presetLayerCountTooLarge);
    } else if (draft.appliedPresetIds.any(
      (presetId) => !_isSafePresetId(presetId),
    )) {
      errors.add(WizardResultCodes.presetIdsInvalid);
    }
    if (draft.helperApplied.length > maxHelperSuggestions) {
      errors.add(WizardResultCodes.helperSuggestionCountTooLarge);
    }
    if (draft.resolvedFields.length > maxResolvedFields) {
      errors.add(WizardResultCodes.resolvedFieldCountTooLarge);
    } else if (!_isCanonicalJsonBounded(
      draft.resolvedFields,
      maxMapEntries: maxResolvedFields,
    )) {
      errors.add(WizardResultCodes.resolvedFieldsInvalid);
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

    var policyProfilesValid = true;
    String policyProfileValue(String key, String fallback) {
      if (!draft.resolvedFields.containsKey(key)) return fallback;
      final value = draft.resolvedFields[key];
      if (value is! String || !_isSafePolicyProfile(value)) {
        policyProfilesValid = false;
        return fallback;
      }
      return value;
    }

    final policyProfiles = <String, String>{
      'privacy_profile': policyProfileValue(
        'retention_profile',
        'privacy.default',
      ),
      'capture_profile': policyProfileValue(
        'table_capture_policy',
        'capture.protected',
      ),
      'network_profile': 'network.hybrid_default',
      'retention_profile': policyProfileValue(
        'retention_profile',
        'retention.standard',
      ),
    };
    if (!policyProfilesValid) {
      errors.add(WizardResultCodes.policyProfilesInvalid);
    }

    return ValidatedSetupPlan(
      planId: 'plan_${draft.intentId}',
      modeId: draft.modeId,
      variantId: draft.variantId,
      createdBy: draft.hostPseudonymousId,
      policyProfileIds: policyProfiles,
      resolvedFields: draft.resolvedFields,
      appliedPresetIds: draft.appliedPresetIds,
      validationResult: ValidationResult(
        isValid: errors.isEmpty,
        warnings: warnings,
        errors: errors,
      ),
      buildReady: errors.isEmpty,
    );
  }

  void _validateConfiguration() {
    _validatePositiveLimit(maxPresetLayers, 'maxPresetLayers');
    _validatePositiveLimit(maxPresetValues, 'maxPresetValues');
    _validatePositiveLimit(maxMergedValues, 'maxMergedValues');
    _validatePositiveLimit(maxConflicts, 'maxConflicts');
    _validatePositiveLimit(maxHelperSuggestions, 'maxHelperSuggestions');
    _validatePositiveLimit(maxPartialSettings, 'maxPartialSettings');
    _validatePositiveLimit(maxAmbiguities, 'maxAmbiguities');
    _validatePositiveLimit(maxResolvedFields, 'maxResolvedFields');
  }

  PresetResolutionResult _blockedResolution(String code) {
    return PresetResolutionResult(
      mergedValues: const <String, Object?>{},
      appliedPresetIds: const <String>[],
      errors: <String>[code],
    );
  }

  ResolvedSetupDraft _blockedDraft(String intentId, String code) {
    return ResolvedSetupDraft(
      intentId: intentId,
      modeId: '',
      variantId: '',
      resolvedFields: const <String, Object?>{},
      appliedPresetIds: const <String>[],
      unresolvedIssues: <String>[code],
    );
  }

  String? _intentInputError(SetupIntent intent) {
    if (intent.presetRefs.length > maxPresetLayers) {
      return WizardResultCodes.presetLayerCountTooLarge;
    }
    if (intent.partialSettings.length > maxPartialSettings) {
      return WizardResultCodes.partialSettingCountTooLarge;
    }
    if (!_isCanonicalJsonBounded(
      intent.partialSettings,
      maxMapEntries: maxPartialSettings,
    )) {
      return WizardResultCodes.partialSettingsInvalid;
    }
    if (intent.helperSuggestions.length > maxHelperSuggestions) {
      return WizardResultCodes.helperSuggestionCountTooLarge;
    }
    if (intent.ambiguities.length > maxAmbiguities) {
      return WizardResultCodes.ambiguityCountTooLarge;
    }
    return null;
  }

  List<PresetLayer>? _selectPresetLayers(
    List<String> presetRefs,
    List<PresetLayer> presetLayers,
  ) {
    // An empty reference list preserves the existing caller-supplied layer
    // behavior. Explicit references opt into exact, least-privilege selection.
    if (presetRefs.isEmpty) return presetLayers;

    final seenRefs = <String>{};
    final selected = <PresetLayer>[];
    for (final presetRef in presetRefs) {
      if (!_isSafePresetId(presetRef) || !seenRefs.add(presetRef)) {
        return null;
      }

      PresetLayer? match;
      var matchCount = 0;
      for (final layer in presetLayers) {
        if (layer.presetId == presetRef) {
          match = layer;
          matchCount += 1;
        }
      }
      if (matchCount != 1 || match == null) return null;
      selected.add(match);
    }
    return selected;
  }

  bool _isCanonicalJsonBounded(Object? value, {required int maxMapEntries}) {
    try {
      canonicalJsonEncode(
        value,
        limits: CanonicalJsonLimits(
          maxMapEntries: maxMapEntries,
          maxListItems: WizardInputLimits.defaultMaxPresetValues,
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

  bool _isSafePolicyProfile(String value) {
    if (value.trim().isEmpty || value.trim() != value) return false;
    return value.codeUnits.every(
      (codeUnit) => codeUnit >= 0x20 && !(codeUnit >= 0x7f && codeUnit <= 0x9f),
    );
  }

  String _safeSelectionId(Object? value) {
    if (value is! String || value.isEmpty || value.trim() != value) {
      return '';
    }
    final bytes = utf8.encode(value);
    if (bytes.length > WizardInputLimits.defaultMaxCanonicalTextBytes) {
      return '';
    }
    try {
      if (utf8.decode(bytes) != value) return '';
    } on FormatException {
      return '';
    }
    if (value.codeUnits.any(
      (unit) => unit < 0x20 || (unit >= 0x7f && unit <= 0x9f),
    )) {
      return '';
    }
    return value;
  }

  bool _isSafePresetId(String value) {
    return value.isNotEmpty && _safeSelectionId(value) == value;
  }
}

void _validatePositiveLimit(int value, String name) {
  if (value <= 0) {
    throw ArgumentError.value(value, name, 'must be positive');
  }
}
