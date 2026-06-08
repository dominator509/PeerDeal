import 'package:peerdeal_wizard/peerdeal_wizard.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultGameFileCompiler', () {
    test('compiles build-ready validated plan into canonical root shape', () {
      const compiler = DefaultGameFileCompiler();
      const plan = ValidatedSetupPlan(
        planId: 'plan_demo',
        modeId: 'open_table',
        variantId: 'holdem_nlhe',
        policyProfileIds: <String, String>{
          'privacy_profile': 'privacy.default',
          'capture_profile': 'capture.protected',
          'network_profile': 'network.hybrid_default',
          'retention_profile': 'retention.standard',
        },
        resolvedFields: <String, Object?>{
          'setup_mode': 'simple',
          'seat_count': 6,
          'helper_enabled': false,
        },
        validationResult: ValidationResult(isValid: true),
        buildReady: true,
      );

      final gameFile = compiler.compile(plan);
      expect(gameFile['schema_id'], 'peerdeal.gamefile');
      expect(
        (gameFile['mode'] as Map<String, Object?>)['display_name'],
        'Open Table Mode',
      );
    });

    test('throws when plan is not build-ready', () {
      const compiler = DefaultGameFileCompiler();
      const plan = ValidatedSetupPlan(
        planId: 'plan_bad',
        modeId: 'open_table',
        variantId: 'holdem_nlhe',
        policyProfileIds: <String, String>{},
        resolvedFields: <String, Object?>{},
        validationResult: ValidationResult(
          isValid: false,
          errors: <String>['seat_count_missing'],
        ),
        buildReady: false,
      );

      expect(() => compiler.compile(plan), throwsStateError);
    });

    test('tryCompile returns compiled result for build-ready plan', () {
      const compiler = DefaultGameFileCompiler();
      const plan = ValidatedSetupPlan(
        planId: 'plan_demo',
        modeId: 'open_table',
        variantId: 'holdem_nlhe',
        policyProfileIds: <String, String>{
          'privacy_profile': 'privacy.default',
          'capture_profile': 'capture.protected',
          'network_profile': 'network.hybrid_default',
          'retention_profile': 'retention.standard',
        },
        resolvedFields: <String, Object?>{
          'setup_mode': 'simple',
          'seat_count': 6,
          'helper_enabled': false,
        },
        validationResult: ValidationResult(
          isValid: true,
          warnings: <String>['review_network_profile'],
        ),
        buildReady: true,
      );

      final result = compiler.tryCompile(plan);

      expect(result.isCompiled, isTrue);
      expect(result.gameFile?['schema_id'], 'peerdeal.gamefile');
      expect(result.warnings, ['review_network_profile']);
      expect(result.errors, isEmpty);
    });

    test('tryCompile rejects invalid plan without throwing', () {
      const compiler = DefaultGameFileCompiler();
      const plan = ValidatedSetupPlan(
        planId: 'plan_bad',
        modeId: 'open_table',
        variantId: 'holdem_nlhe',
        policyProfileIds: <String, String>{},
        resolvedFields: <String, Object?>{},
        validationResult: ValidationResult(
          isValid: false,
          warnings: <String>['review_setup'],
          errors: <String>['seat_count_missing'],
        ),
        buildReady: false,
      );

      final result = compiler.tryCompile(plan);

      expect(result.isCompiled, isFalse);
      expect(result.gameFile, isNull);
      expect(result.errors, ['seat_count_missing']);
      expect(result.warnings, ['review_setup']);
    });

    test('tryCompile rejects non-build-ready plan with default error', () {
      const compiler = DefaultGameFileCompiler();
      const plan = ValidatedSetupPlan(
        planId: 'plan_not_ready',
        modeId: 'open_table',
        variantId: 'holdem_nlhe',
        policyProfileIds: <String, String>{},
        resolvedFields: <String, Object?>{},
        validationResult: ValidationResult(isValid: true),
        buildReady: false,
      );

      final result = compiler.tryCompile(plan);

      expect(result.isCompiled, isFalse);
      expect(result.errors, ['setup_plan_not_build_ready']);
    });
  });
}
