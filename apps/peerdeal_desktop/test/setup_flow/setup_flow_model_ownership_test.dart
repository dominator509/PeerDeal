import 'package:peerdeal_desktop/setup_flow/setup_flow_models.dart';
import 'package:test/test.dart';

void main() {
  test('setup outcomes own nested Game File and diagnostic collections', () {
    final nested = <String, Object?>{'enabled': true};
    final gameFile = <String, Object?>{'settings': nested};
    final errors = <String>['error'];
    final warnings = <String>['warning'];
    final outcome = SetupFlowOutcome(
      status: SetupFlowStatus.compiled,
      resultCode: 'OK_GAME_FILE_COMPILED',
      gameFile: gameFile,
      errors: errors,
      warnings: warnings,
    );

    nested['enabled'] = false;
    gameFile['new_field'] = 'changed';
    errors.add('changed');
    warnings.add('changed');

    expect(outcome.gameFile, {
      'settings': {'enabled': true},
    });
    expect(outcome.errors, ['error']);
    expect(outcome.warnings, ['warning']);
    expect(
      () =>
          (outcome.gameFile!['settings']! as Map<Object?, Object?>)['enabled'] =
              false,
      throwsUnsupportedError,
    );
    expect(() => outcome.gameFile!.clear(), throwsUnsupportedError);
    expect(() => outcome.errors.add('changed'), throwsUnsupportedError);
    expect(() => outcome.warnings.add('changed'), throwsUnsupportedError);
  });
}
