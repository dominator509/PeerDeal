import 'package:peerdeal_wizard/peerdeal_wizard.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultPresetResolver', () {
    test('later layers override earlier layers deterministically', () {
      const resolver = DefaultPresetResolver();
      const layers = <PresetLayer>[
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

    test('rejects unsupported variants before Game File compilation', () {
      const resolver = DefaultPresetResolver();
      const draft = ResolvedSetupDraft(
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
      const intent = SetupIntent(
        intentId: '   ',
        sourceType: SetupSurface.simple,
        hostPseudonymousId: '   ',
        modePreference: 'open_table',
        variantPreference: 'holdem_nlhe',
        seatCountPreference: 6,
      );

      final draft = resolver.resolveIntent(
        intent: intent,
        presetLayers: const <PresetLayer>[],
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
      const draft = ResolvedSetupDraft(
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
  });
}
