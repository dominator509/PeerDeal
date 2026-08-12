import 'package:peerdeal_wizard/peerdeal_wizard.dart';
import 'package:test/test.dart';

void expectUnmodifiable(void Function() mutation) {
  expect(mutation, throwsUnsupportedError);
}

void main() {
  test('SetupIntent freezes source collections and nested values', () {
    final partialSettings = <String, Object?>{
      'nested': <String, Object?>{
        'values': <Object?>['before'],
      },
    };
    final presetRefs = <String>['preset_1'];
    final helperValue = <String, Object?>{'enabled': true};
    final ambiguities = <String>['seat_count_missing'];

    final intent = SetupIntent(
      intentId: 'intent_1',
      sourceType: SetupSurface.simple,
      hostPseudonymousId: 'host_1',
      partialSettings: partialSettings,
      presetRefs: presetRefs,
      helperSuggestions: <HelperSuggestion>[
        HelperSuggestion(key: 'helper_key', value: helperValue, reason: 'test'),
      ],
      ambiguities: ambiguities,
    );

    partialSettings['later'] = true;
    presetRefs.add('preset_2');
    helperValue['later'] = false;
    ambiguities.add('another_issue');

    expect(intent.partialSettings.containsKey('later'), isFalse);
    expect(intent.presetRefs, ['preset_1']);
    expect(
      (intent.helperSuggestions.single.value as Map).containsKey('later'),
      isFalse,
    );
    expect(intent.ambiguities, ['seat_count_missing']);
    expectUnmodifiable(
      () => (intent.partialSettings['nested'] as Map)['new'] = true,
    );
    expectUnmodifiable(() => intent.presetRefs.add('preset_3'));
  });

  test('wizard plans, drafts, and results own their collections', () {
    final warnings = <String>['warning'];
    final errors = <String>['error'];
    final validation = ValidationResult(
      isValid: false,
      warnings: warnings,
      errors: errors,
    );
    final policyProfileIds = <String, String>{'privacy': 'default'};
    final resolvedFields = <String, Object?>{
      'nested': <String, Object?>{'value': 1},
    };
    final plan = ValidatedSetupPlan(
      planId: 'plan_1',
      modeId: 'open_table',
      variantId: 'holdem_nlhe',
      policyProfileIds: policyProfileIds,
      resolvedFields: resolvedFields,
      validationResult: validation,
      buildReady: false,
    );

    warnings.add('later_warning');
    errors.add('later_error');
    policyProfileIds['capture'] = 'protected';
    resolvedFields['later'] = true;

    expect(validation.warnings, ['warning']);
    expect(validation.errors, ['error']);
    expect(plan.policyProfileIds, {'privacy': 'default'});
    expect(plan.resolvedFields.containsKey('later'), isFalse);
    expectUnmodifiable(() => validation.warnings.add('blocked'));
    expectUnmodifiable(
      () => (plan.resolvedFields['nested'] as Map)['value'] = 2,
    );

    final draftFields = <String, Object?>{'seat_count': 6};
    final appliedPresetIds = <String>['preset_1'];
    final unresolvedIssues = <String>['issue'];
    final helperApplied = <String>['helper'];
    final draft = ResolvedSetupDraft(
      intentId: 'intent_1',
      modeId: 'open_table',
      variantId: 'holdem_nlhe',
      resolvedFields: draftFields,
      appliedPresetIds: appliedPresetIds,
      unresolvedIssues: unresolvedIssues,
      helperApplied: helperApplied,
    );

    draftFields['later'] = true;
    appliedPresetIds.add('preset_2');
    unresolvedIssues.add('later_issue');
    helperApplied.add('later_helper');

    expect(draft.resolvedFields, {'seat_count': 6});
    expect(draft.appliedPresetIds, ['preset_1']);
    expect(draft.unresolvedIssues, ['issue']);
    expect(draft.helperApplied, ['helper']);
    expectUnmodifiable(() => draft.appliedPresetIds.add('blocked'));
  });

  test('preset and compile results freeze maps, lists, and nested values', () {
    final layerValues = <String, Object?>{
      'nested': <String, Object?>{
        'value': <Object?>['before'],
      },
    };
    final layer = PresetLayer(
      presetId: 'preset_1',
      priority: 1,
      values: layerValues,
    );
    layerValues['later'] = true;

    final appliedPresetIds = <String>['preset_1'];
    final conflicts = <String>['conflict'];
    final resolution = PresetResolutionResult(
      mergedValues: layer.values,
      appliedPresetIds: appliedPresetIds,
      conflicts: conflicts,
    );
    appliedPresetIds.add('preset_2');
    conflicts.add('later_conflict');

    expect(layer.values.containsKey('later'), isFalse);
    expect(resolution.appliedPresetIds, ['preset_1']);
    expect(resolution.conflicts, ['conflict']);
    expectUnmodifiable(
      () => ((layer.values['nested'] as Map)['value'] as List).add('blocked'),
    );
    expectUnmodifiable(() => resolution.conflicts.add('blocked'));

    final gameFile = <String, Object?>{
      'nested': <String, Object?>{
        'value': <Object?>['before'],
      },
    };
    final warnings = <String>['warning'];
    final compiled = GameFileCompileResult.compiled(
      gameFile: gameFile,
      warnings: warnings,
    );
    gameFile['later'] = true;
    warnings.add('later_warning');

    expect(compiled.gameFile?.containsKey('later'), isFalse);
    expect(compiled.warnings, ['warning']);
    expectUnmodifiable(
      () => ((compiled.gameFile?['nested'] as Map)['value'] as List).add(
        'blocked',
      ),
    );
    expectUnmodifiable(() => compiled.warnings.add('blocked'));
  });
}
