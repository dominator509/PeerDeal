import 'package:peerdeal_wizard/peerdeal_wizard.dart';

import 'setup_flow_models.dart';

class SetupFlowOrchestrator {
  const SetupFlowOrchestrator({
    PresetResolver presetResolver = const DefaultPresetResolver(),
    GameFileCompiler gameFileCompiler = const DefaultGameFileCompiler(),
  }) : _presetResolver = presetResolver,
       _gameFileCompiler = gameFileCompiler;

  final PresetResolver _presetResolver;
  final GameFileCompiler _gameFileCompiler;

  SetupFlowOutcome compileSetup({
    required SetupIntent intent,
    List<PresetLayer> presetLayers = const <PresetLayer>[],
  }) {
    try {
      final draft = _presetResolver.resolveIntent(
        intent: intent,
        presetLayers: presetLayers,
      );
      final plan = _presetResolver.validateDraft(draft);
      final compileResult = _gameFileCompiler.tryCompile(plan);

      if (compileResult.isCompiled && compileResult.gameFile != null) {
        return SetupFlowOutcome(
          status: SetupFlowStatus.compiled,
          resultCode: 'OK_GAME_FILE_COMPILED',
          gameFile: compileResult.gameFile,
          warnings: compileResult.warnings,
        );
      }

      return SetupFlowOutcome(
        status: SetupFlowStatus.rejected,
        resultCode: 'ERR_SETUP_NOT_BUILD_READY',
        errors: compileResult.errors.isEmpty
            ? const <String>['setup_plan_not_build_ready']
            : compileResult.errors,
        warnings: compileResult.warnings,
      );
    } on Object {
      return const SetupFlowOutcome(
        status: SetupFlowStatus.rejected,
        resultCode: 'ERR_SETUP_FLOW_FAILED',
        errors: <String>['setup_flow_failed'],
      );
    }
  }
}
