import 'package:peerdeal_wizard/peerdeal_wizard.dart';
import 'package:test/test.dart';

void main() {
  group('Wizard equivalence', () {
    test(
      'simple and conversational intents can converge on the same validated output',
      () {
        const resolver = DefaultPresetResolver();
        final presetLayers = <PresetLayer>[
          PresetLayer(
            presetId: 'builtin_open_table',
            priority: 1,
            values: <String, Object?>{
              'mode_type': 'open_table',
              'variant_id': 'holdem_nlhe',
              'seat_count': 6,
            },
            isLockedBuiltin: true,
          ),
        ];

        final simple = SetupIntent(
          intentId: 'simple_1',
          sourceType: SetupSurface.simple,
          hostPseudonymousId: 'host_x',
          modePreference: 'open_table',
          variantPreference: 'holdem_nlhe',
          seatCountPreference: 6,
        );

        final conversational = SetupIntent(
          intentId: 'conv_1',
          sourceType: SetupSurface.conversational,
          hostPseudonymousId: 'host_x',
          promptText: "Set up a 6-max open table hold'em game.",
          modePreference: 'open_table',
          variantPreference: 'holdem_nlhe',
          seatCountPreference: 6,
        );

        final simplePlan = resolver.validateDraft(
          resolver.resolveIntent(intent: simple, presetLayers: presetLayers),
        );
        final conversationalPlan = resolver.validateDraft(
          resolver.resolveIntent(
            intent: conversational,
            presetLayers: presetLayers,
          ),
        );

        expect(simplePlan.validationResult.isValid, isTrue);
        expect(conversationalPlan.validationResult.isValid, isTrue);
        expect(simplePlan.modeId, conversationalPlan.modeId);
        expect(simplePlan.variantId, conversationalPlan.variantId);
        expect(
          simplePlan.resolvedFields['seat_count'],
          conversationalPlan.resolvedFields['seat_count'],
        );
      },
    );
  });
}
