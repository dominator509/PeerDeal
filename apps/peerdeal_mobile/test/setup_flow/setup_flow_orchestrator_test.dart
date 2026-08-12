import 'package:peerdeal_mobile/setup_flow/setup_flow_models.dart';
import 'package:peerdeal_mobile/setup_flow/setup_flow_orchestrator.dart';
import 'package:peerdeal_wizard/peerdeal_wizard.dart';
import 'package:test/test.dart';

void main() {
  test('compiles build-ready setup intent into a Game File', () {
    const orchestrator = SetupFlowOrchestrator();

    final result = orchestrator.compileSetup(intent: _validIntent());

    expect(result.status, SetupFlowStatus.compiled);
    expect(result.resultCode, 'OK_GAME_FILE_COMPILED');
    expect(result.gameFile, isNotNull);
    expect(result.gameFile?['game_file_version'], '1.0.0');
    expect(result.errors, isEmpty);
  });

  test('rejects invalid setup intent without throwing', () {
    const orchestrator = SetupFlowOrchestrator();

    final result = orchestrator.compileSetup(
      intent: SetupIntent(
        intentId: 'intent_invalid',
        sourceType: SetupSurface.simple,
        hostPseudonymousId: 'host_1',
      ),
    );

    expect(result.status, SetupFlowStatus.rejected);
    expect(result.resultCode, 'ERR_SETUP_NOT_BUILD_READY');
    expect(result.gameFile, isNull);
    expect(result.errors, contains('seat_count_missing'));
  });

  test('rejects malformed setup identity before wizard dependencies', () {
    const orchestrator = SetupFlowOrchestrator(
      presetResolver: _ThrowingPresetResolver(),
    );

    final result = orchestrator.compileSetup(
      intent: SetupIntent(
        intentId: '   ',
        sourceType: SetupSurface.simple,
        hostPseudonymousId: '   ',
        modePreference: 'open_table',
        variantPreference: 'holdem_nlhe',
        seatCountPreference: 6,
      ),
    );

    expect(result.status, SetupFlowStatus.rejected);
    expect(result.resultCode, 'ERR_SETUP_INTENT_INVALID');
    expect(result.gameFile, isNull);
    expect(result.errors, ['setup_intent_id_missing', 'setup_host_missing']);
  });

  test('rejects padded setup identity before wizard dependencies', () {
    const orchestrator = SetupFlowOrchestrator(
      presetResolver: _ThrowingPresetResolver(),
    );

    final result = orchestrator.compileSetup(
      intent: SetupIntent(
        intentId: ' intent_open_table',
        sourceType: SetupSurface.simple,
        hostPseudonymousId: 'host_1 ',
        modePreference: 'open_table',
        variantPreference: 'holdem_nlhe',
        seatCountPreference: 6,
      ),
    );

    expect(result.status, SetupFlowStatus.rejected);
    expect(result.resultCode, 'ERR_SETUP_INTENT_INVALID');
    expect(result.gameFile, isNull);
    expect(result.errors, [
      'setup_intent_id_malformed',
      'setup_host_malformed',
    ]);
  });

  test('fails closed when setup dependencies throw', () {
    const orchestrator = SetupFlowOrchestrator(
      presetResolver: _ThrowingPresetResolver(),
    );

    final result = orchestrator.compileSetup(intent: _validIntent());

    expect(result.status, SetupFlowStatus.rejected);
    expect(result.resultCode, 'ERR_SETUP_FLOW_FAILED');
    expect(result.errors, ['setup_flow_failed']);
  });
}

SetupIntent _validIntent() {
  return SetupIntent(
    intentId: 'intent_open_table',
    sourceType: SetupSurface.simple,
    hostPseudonymousId: 'host_1',
    modePreference: 'open_table',
    variantPreference: 'holdem_nlhe',
    seatCountPreference: 6,
  );
}

class _ThrowingPresetResolver implements PresetResolver {
  const _ThrowingPresetResolver();

  @override
  PresetResolutionResult mergeLayers(List<PresetLayer> layers) {
    throw StateError('preset unavailable');
  }

  @override
  ResolvedSetupDraft resolveIntent({
    required SetupIntent intent,
    required List<PresetLayer> presetLayers,
  }) {
    throw StateError('preset unavailable');
  }

  @override
  ValidatedSetupPlan validateDraft(ResolvedSetupDraft draft) {
    throw StateError('preset unavailable');
  }
}
