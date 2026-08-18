import 'package:peerdeal_wizard/peerdeal_wizard.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultPresetResolver', () {
    test('later layers override earlier layers deterministically', () {
      const resolver = DefaultPresetResolver();
      final layers = <PresetLayer>[
        PresetLayer(
          presetId: 'builtin_open_table',
          priority: 1,
          values: <String, Object?>{'mode_type': 'open_table', 'seat_count': 6},
          isLockedBuiltin: true,
        ),
        PresetLayer(
          presetId: 'host_override',
          priority: 2,
          values: <String, Object?>{'seat_count': 8},
        ),
      ];

      final result = resolver.mergeLayers(layers);
      expect(result.mergedValues['mode_type'], 'open_table');
      expect(result.mergedValues['seat_count'], 8);
      expect(result.conflicts, isNotEmpty);
    });

    test('fails closed when the preset layer collection exceeds its limit', () {
      const resolver = DefaultPresetResolver(maxPresetLayers: 1);
      final result = resolver.mergeLayers(
        List<PresetLayer>.generate(
          2,
          (index) => PresetLayer(
            presetId: 'preset-${index + 1}',
            priority: index,
            values: const <String, Object?>{},
          ),
          growable: false,
        ),
      );

      expect(result.mergedValues, isEmpty);
      expect(result.appliedPresetIds, isEmpty);
      expect(result.errors, [WizardResultCodes.presetLayerCountTooLarge]);
    });

    test('fails closed when a preset value map exceeds its limit', () {
      const resolver = DefaultPresetResolver(maxPresetValues: 1);
      final result = resolver.mergeLayers(<PresetLayer>[
        PresetLayer(
          presetId: 'preset-1',
          priority: 1,
          values: <String, Object?>{'first': true, 'second': false},
        ),
      ]);

      expect(result.errors, [WizardResultCodes.presetValueCountTooLarge]);
      expect(result.mergedValues, isEmpty);
    });

    test('rejects unsupported nested preset values before merging', () {
      const resolver = DefaultPresetResolver();
      final result = resolver.mergeLayers(<PresetLayer>[
        PresetLayer(
          presetId: 'preset-1',
          priority: 1,
          values: <String, Object?>{'unsupported': Object()},
        ),
      ]);

      expect(result.errors, [WizardResultCodes.presetValuesInvalid]);
      expect(result.mergedValues, isEmpty);
    });

    test('fails closed when merged values exceed their limit', () {
      const resolver = DefaultPresetResolver(maxMergedValues: 1);
      final result = resolver.mergeLayers(<PresetLayer>[
        PresetLayer(
          presetId: 'preset-1',
          priority: 1,
          values: <String, Object?>{'first': true, 'second': false},
        ),
      ]);

      expect(result.errors, [WizardResultCodes.mergedValueCountTooLarge]);
      expect(result.mergedValues, isEmpty);
    });

    test('rejects unsupported partial settings before resolution', () {
      const resolver = DefaultPresetResolver();
      final intent = SetupIntent(
        intentId: 'intent_partial_invalid',
        sourceType: SetupSurface.simple,
        hostPseudonymousId: 'host_1',
        partialSettings: <String, Object?>{'unsupported': Object()},
      );

      final draft = resolver.resolveIntent(
        intent: intent,
        presetLayers: <PresetLayer>[],
      );

      expect(draft.unresolvedIssues, [
        WizardResultCodes.partialSettingsInvalid,
      ]);
      expect(resolver.validateDraft(draft).buildReady, isFalse);
    });

    test('does not coerce non-string mode or variant selections', () {
      const resolver = DefaultPresetResolver();
      final intent = SetupIntent(
        intentId: 'intent_selection_types',
        sourceType: SetupSurface.simple,
        hostPseudonymousId: 'host_1',
        partialSettings: <String, Object?>{
          'mode_type': 7,
          'variant_id': true,
          'seat_count': 6,
        },
      );

      final draft = resolver.resolveIntent(
        intent: intent,
        presetLayers: <PresetLayer>[],
      );

      expect(draft.modeId, isEmpty);
      expect(draft.variantId, isEmpty);
      final result = resolver.validateDraft(draft);
      expect(result.buildReady, isFalse);
      expect(
        result.validationResult.errors,
        contains('unsupported_mode_id'),
      );
      expect(
        result.validationResult.errors,
        contains('unsupported_variant_id'),
      );
    });

    test('fails closed when helper suggestions exceed their limit', () {
      const resolver = DefaultPresetResolver(maxHelperSuggestions: 1);
      final intent = SetupIntent(
        intentId: 'intent_helper_overflow',
        sourceType: SetupSurface.simple,
        hostPseudonymousId: 'host_1',
        modePreference: 'open_table',
        variantPreference: 'holdem_nlhe',
        seatCountPreference: 6,
        helperEnabled: true,
        helperSuggestions: List<HelperSuggestion>.generate(
          2,
          (index) => HelperSuggestion(
            key: 'helper-$index',
            value: true,
            reason: 'test',
          ),
          growable: false,
        ),
      );

      final draft = resolver.resolveIntent(
        intent: intent,
        presetLayers: <PresetLayer>[],
      );

      expect(draft.unresolvedIssues, [
        WizardResultCodes.helperSuggestionCountTooLarge,
      ]);
      expect(resolver.validateDraft(draft).buildReady, isFalse);
    });

    test('rejects oversized direct drafts before Game File compilation', () {
      const resolver = DefaultPresetResolver();
      final draft = ResolvedSetupDraft(
        intentId: 'intent_fields_overflow',
        modeId: 'open_table',
        variantId: 'holdem_nlhe',
        resolvedFields: <String, Object?>{
          for (
            var index = 0;
            index < WizardInputLimits.defaultMaxResolvedFields + 1;
            index++
          )
            'field-$index': index,
        },
        appliedPresetIds: const <String>[],
      );

      final result = resolver.validateDraft(draft);

      expect(result.buildReady, isFalse);
      expect(
        result.validationResult.errors,
        contains(WizardResultCodes.resolvedFieldCountTooLarge),
      );
    });

    test('rejects unsupported variants before Game File compilation', () {
      const resolver = DefaultPresetResolver();
      final draft = ResolvedSetupDraft(
        intentId: 'intent_unsupported_variant',
        modeId: 'open_table',
        variantId: 'omaha_plo',
        resolvedFields: <String, Object?>{'seat_count': 6},
        appliedPresetIds: <String>['builtin_open_table'],
      );

      final result = resolver.validateDraft(draft);

      expect(result.buildReady, isFalse);
      expect(result.validationResult.isValid, isFalse);
      expect(
        result.validationResult.errors,
        contains('unsupported_variant_id'),
      );
      expect(result.validationResult.warnings, isEmpty);
    });

    test('rejects malformed setup identity before Game File compilation', () {
      const resolver = DefaultPresetResolver();
      final intent = SetupIntent(
        intentId: '   ',
        sourceType: SetupSurface.simple,
        hostPseudonymousId: '   ',
        modePreference: 'open_table',
        variantPreference: 'holdem_nlhe',
        seatCountPreference: 6,
      );

      final draft = resolver.resolveIntent(
        intent: intent,
        presetLayers: <PresetLayer>[],
      );
      final result = resolver.validateDraft(draft);

      expect(draft.intentId, isEmpty);
      expect(result.buildReady, isFalse);
      expect(result.validationResult.isValid, isFalse);
      expect(result.validationResult.errors, <String>[
        'setup_intent_id_missing',
        'setup_host_missing',
      ]);
    });

    test('accepts supported Holdem variant draft', () {
      const resolver = DefaultPresetResolver();
      final draft = ResolvedSetupDraft(
        intentId: 'intent_holdem',
        modeId: 'open_table',
        variantId: 'holdem_nlhe',
        resolvedFields: <String, Object?>{'seat_count': 6},
        appliedPresetIds: <String>['builtin_open_table'],
      );

      final result = resolver.validateDraft(draft);

      expect(result.buildReady, isTrue);
      expect(result.validationResult.isValid, isTrue);
      expect(result.validationResult.errors, isEmpty);
      expect(result.validationResult.warnings, isEmpty);
    });

    test('rejects coerced or unsafe policy profile inputs', () {
      const resolver = DefaultPresetResolver();
      final draft = ResolvedSetupDraft(
        intentId: 'intent_invalid_policy',
        modeId: 'open_table',
        variantId: 'holdem_nlhe',
        resolvedFields: <String, Object?>{
          'seat_count': 6,
          'retention_profile': 7,
          'table_capture_policy': ' capture.protected',
        },
        appliedPresetIds: const <String>[],
      );

      final result = resolver.validateDraft(draft);

      expect(result.buildReady, isFalse);
      expect(
        result.validationResult.errors,
        contains(WizardResultCodes.policyProfilesInvalid),
      );
      expect(result.policyProfileIds['privacy_profile'], 'privacy.default');
      expect(
        result.policyProfileIds['capture_profile'],
        'capture.protected',
      );
    });
  });
}
