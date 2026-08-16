import 'package:peerdeal_mobile/setup_flow/setup_flow_models.dart';
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

  test('bounds and scrubs direct setup diagnostics', () {
    final errors = <String>[
      'error_1',
      ' bad ',
      'error_2',
      'error_3',
      'error_4',
    ];
    final warnings = <String>[
      'warning_1',
      ' bad ',
      'warning_2',
      'warning_3',
      'warning_4',
    ];
    final outcome = SetupFlowOutcome(
      status: SetupFlowStatus.rejected,
      resultCode: 'ERR_SETUP_NOT_BUILD_READY',
      errors: errors,
      warnings: warnings,
    );

    errors[0] = 'mutated';
    warnings[0] = 'mutated';
    expect(outcome.errors, [
      'error_1',
      'setup_error_unavailable',
      'error_2',
      'error_3',
      'setup_errors_truncated',
    ]);
    expect(outcome.warnings, [
      'warning_1',
      'setup_warning_unavailable',
      'warning_2',
      'warning_3',
      'setup_warnings_truncated',
    ]);
    expect(() => outcome.errors.add('error_5'), throwsUnsupportedError);
    expect(() => outcome.warnings.add('warning_5'), throwsUnsupportedError);
  });
}
