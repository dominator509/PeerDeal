import 'dart:io';

import 'package:peerdeal_wizard/peerdeal_wizard.dart';
import 'package:test/test.dart';

import 'fixture_loader.dart';

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

    test('fixture setup surfaces converge through the validated boundary', () {
      final resolver = const DefaultPresetResolver();
      final presetLayers = loadPresetLayersFixture('preset_stack.json');
      final fixtureFiles = Directory('test/fixtures')
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('_setup_intent.json'))
          .toList(growable: false);

      expect(fixtureFiles, hasLength(3));
      final plans = <String, ValidatedSetupPlan>{};
      final helperAppliedBySource = <String, List<String>>{};
      for (final file in fixtureFiles) {
        final intent = loadSetupIntentFixture(file.uri.pathSegments.last);
        final draft = resolver.resolveIntent(
          intent: intent,
          presetLayers: presetLayers,
        );
        final plan = resolver.validateDraft(draft);
        expect(plan.buildReady, isTrue, reason: file.path);
        expect(plan.validationResult.isValid, isTrue, reason: file.path);
        plans[intent.sourceType.name] = plan;
        helperAppliedBySource[intent.sourceType.name] = draft.helperApplied;
      }

      expect(plans.keys, containsAll(['simple', 'advanced', 'conversational']));
      expect(plans['simple']!.modeId, 'open_table');
      expect(plans['conversational']!.modeId, 'open_table');
      expect(plans['simple']!.variantId, plans['conversational']!.variantId);
      expect(
        plans['simple']!.resolvedFields['seat_count'],
        plans['conversational']!.resolvedFields['seat_count'],
      );
      expect(plans['advanced']!.modeId, 'tournament');
      expect(plans['advanced']!.resolvedFields['seat_count'], 9);
      expect(helperAppliedBySource['conversational'], ['retention_profile']);
    });

    test('fixture preset stack preserves deterministic priority order', () {
      final result = const DefaultPresetResolver().mergeLayers(
        loadPresetLayersFixture('preset_stack.json'),
      );

      expect(result.errors, isEmpty);
      expect(result.appliedPresetIds, [
        'builtin_open_table',
        'capture_protected',
        'host_fast_join',
      ]);
      expect(result.mergedValues['mode_type'], 'open_table');
      expect(result.mergedValues['table_capture_policy'], 'protected');
      expect(result.mergedValues['allow_mid_session_join'], isTrue);
    });
  });
}
