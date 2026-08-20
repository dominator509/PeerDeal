import 'package:peerdeal_wizard/peerdeal_wizard.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultGameFileCompiler', () {
    test('compiles build-ready validated plan into canonical root shape', () {
      const compiler = DefaultGameFileCompiler();
      final plan = ValidatedSetupPlan(
        planId: 'plan_demo',
        modeId: 'open_table',
        variantId: 'holdem_nlhe',
        createdBy: 'host_demo',
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
      expect(gameFile['protocol_version'], currentProtocolVersion.toWire());
      expect(GameFileSchema().validate(gameFile), isEmpty);
      expect(
        const ProtocolCatalog().checkGameFileJson(gameFile).isSupported,
        isTrue,
      );
      expect(gameFile.keys, containsAll(GameFileSchema.requiredTopLevelKeys));
      expect(
        (gameFile['mode'] as Map<String, Object?>)['display_name'],
        'Open Table Mode',
      );
    });

    test('throws when plan is not build-ready', () {
      const compiler = DefaultGameFileCompiler();
      final plan = ValidatedSetupPlan(
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

    test('compile rejects build-ready plans with blank plan identity', () {
      const compiler = DefaultGameFileCompiler();
      final plan = ValidatedSetupPlan(
        planId: '   ',
        modeId: 'open_table',
        variantId: 'holdem_nlhe',
        createdBy: 'host_demo',
        policyProfileIds: <String, String>{
          'privacy_profile': 'privacy.default',
          'capture_profile': 'capture.protected',
          'network_profile': 'network.hybrid_default',
          'retention_profile': 'retention.standard',
        },
        resolvedFields: <String, Object?>{'seat_count': 6},
        validationResult: ValidationResult(isValid: true),
        buildReady: true,
      );

      expect(() => compiler.compile(plan), throwsStateError);
    });

    test('tryCompile returns compiled result for build-ready plan', () {
      const compiler = DefaultGameFileCompiler();
      final plan = ValidatedSetupPlan(
        planId: 'plan_demo',
        modeId: 'open_table',
        variantId: 'holdem_nlhe',
        createdBy: 'host_demo',
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

    test('resolver metadata is preserved in the compiled Game File', () {
      const resolver = DefaultPresetResolver();
      final plan = resolver.validateDraft(
        resolver.resolveIntent(
          intent: SetupIntent(
            intentId: 'intent_game_file',
            sourceType: SetupSurface.simple,
            hostPseudonymousId: 'host_game_file',
            modePreference: 'open_table',
            variantPreference: 'holdem_nlhe',
            seatCountPreference: 6,
          ),
          presetLayers: <PresetLayer>[
            PresetLayer(
              presetId: 'builtin_open_table',
              priority: 1,
              values: const <String, Object?>{},
            ),
          ],
        ),
      );

      final result = DefaultGameFileCompiler(
        createdAtFactory: () => DateTime.utc(2026, 8, 20, 12),
      ).tryCompile(plan);

      expect(result.isCompiled, isTrue);
      expect(result.gameFile?['created_by'], 'host_game_file');
      expect(result.gameFile?['created_at'], '2026-08-20T12:00:00.000Z');
      expect((result.gameFile?['presets'] as Map)['applied_preset_ids'], [
        'builtin_open_table',
      ]);
    });

    test('tryCompile rejects invalid plan without throwing', () {
      const compiler = DefaultGameFileCompiler();
      final plan = ValidatedSetupPlan(
        planId: 'plan_bad',
        modeId: 'open_table',
        variantId: 'holdem_nlhe',
        createdBy: 'host_demo',
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
      final plan = ValidatedSetupPlan(
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

    test('tryCompile rejects build-ready plans with blank plan identity', () {
      const compiler = DefaultGameFileCompiler();
      final plan = ValidatedSetupPlan(
        planId: '   ',
        modeId: 'open_table',
        variantId: 'holdem_nlhe',
        createdBy: 'host_demo',
        policyProfileIds: <String, String>{
          'privacy_profile': 'privacy.default',
          'capture_profile': 'capture.protected',
          'network_profile': 'network.hybrid_default',
          'retention_profile': 'retention.standard',
        },
        resolvedFields: <String, Object?>{'seat_count': 6},
        validationResult: ValidationResult(isValid: true),
        buildReady: true,
      );

      final result = compiler.tryCompile(plan);

      expect(result.isCompiled, isFalse);
      expect(result.gameFile, isNull);
      expect(result.errors, ['setup_plan_id_missing']);
    });

    test('tryCompile rejects unsafe plan and policy metadata', () {
      const compiler = DefaultGameFileCompiler();
      final plan = ValidatedSetupPlan(
        planId: 'plan_\u0000demo',
        modeId: 'open_table',
        variantId: 'holdem_nlhe',
        createdBy: 'host_demo',
        policyProfileIds: const <String, String>{
          'privacy_profile': 'privacy.default',
          'capture_profile': ' capture.protected',
        },
        resolvedFields: <String, Object?>{'seat_count': 6},
        validationResult: ValidationResult(isValid: true),
        buildReady: true,
      );

      final result = compiler.tryCompile(plan);

      expect(result.isCompiled, isFalse);
      expect(result.errors, contains(WizardResultCodes.planIdInvalid));
      expect(result.errors, contains(WizardResultCodes.policyProfilesInvalid));
    });

    test('tryCompile rejects unsafe validation diagnostics', () {
      const compiler = DefaultGameFileCompiler();
      final plan = ValidatedSetupPlan(
        planId: 'plan_unsafe_diagnostics',
        modeId: 'open_table',
        variantId: 'holdem_nlhe',
        createdBy: 'host_demo',
        policyProfileIds: const <String, String>{
          'privacy_profile': 'privacy.default',
          'capture_profile': 'capture.protected',
          'network_profile': 'network.hybrid_default',
          'retention_profile': 'retention.standard',
        },
        resolvedFields: <String, Object?>{'seat_count': 6},
        validationResult: ValidationResult(
          isValid: true,
          warnings: <String>['\u0000sensitive diagnostic'],
        ),
        buildReady: true,
      );

      final result = compiler.tryCompile(plan);

      expect(result.isCompiled, isFalse);
      expect(result.errors, [WizardResultCodes.validationMessagesInvalid]);
      expect(result.warnings, isEmpty);
      expect(result.errors, isNot(contains(contains('sensitive'))));
    });

    test('tryCompile scrubs unsafe diagnostics on rejected plans', () {
      const compiler = DefaultGameFileCompiler();
      final plan = ValidatedSetupPlan(
        planId: 'plan_rejected_diagnostics',
        modeId: 'open_table',
        variantId: 'holdem_nlhe',
        createdBy: 'host_demo',
        policyProfileIds: const <String, String>{},
        resolvedFields: <String, Object?>{'seat_count': 6},
        validationResult: ValidationResult(
          isValid: false,
          errors: <String>['\u0000sensitive error'],
          warnings: <String>[' padded warning '],
        ),
        buildReady: false,
      );

      final result = compiler.tryCompile(plan);

      expect(result.isCompiled, isFalse);
      expect(result.errors, [WizardResultCodes.validationMessagesInvalid]);
      expect(result.warnings, isEmpty);
    });

    test('tryCompile rejects build-ready unsupported variant plan', () {
      const compiler = DefaultGameFileCompiler();
      final plan = ValidatedSetupPlan(
        planId: 'plan_unsupported_variant',
        modeId: 'open_table',
        variantId: 'omaha_plo',
        createdBy: 'host_demo',
        policyProfileIds: <String, String>{
          'privacy_profile': 'privacy.default',
          'capture_profile': 'capture.protected',
          'network_profile': 'network.hybrid_default',
          'retention_profile': 'retention.standard',
        },
        resolvedFields: <String, Object?>{'seat_count': 6},
        validationResult: ValidationResult(isValid: true),
        buildReady: true,
      );

      final result = compiler.tryCompile(plan);

      expect(result.isCompiled, isFalse);
      expect(result.gameFile, isNull);
      expect(result.errors, ['unsupported_variant_id']);
    });

    test('tryCompile rejects build-ready unsupported mode plan', () {
      const compiler = DefaultGameFileCompiler();
      final plan = ValidatedSetupPlan(
        planId: 'plan_unsupported_mode',
        modeId: 'cash_private',
        variantId: 'holdem_nlhe',
        createdBy: 'host_demo',
        policyProfileIds: <String, String>{
          'privacy_profile': 'privacy.default',
          'capture_profile': 'capture.protected',
          'network_profile': 'network.hybrid_default',
          'retention_profile': 'retention.standard',
        },
        resolvedFields: <String, Object?>{'seat_count': 6},
        validationResult: ValidationResult(isValid: true),
        buildReady: true,
      );

      final result = compiler.tryCompile(plan);

      expect(result.isCompiled, isFalse);
      expect(result.gameFile, isNull);
      expect(result.errors, ['unsupported_mode_id']);
    });

    test('tryCompile rejects oversized direct resolved fields', () {
      const compiler = DefaultGameFileCompiler();
      final plan = ValidatedSetupPlan(
        planId: 'plan_fields_overflow',
        modeId: 'open_table',
        variantId: 'holdem_nlhe',
        createdBy: 'host_demo',
        policyProfileIds: const <String, String>{},
        resolvedFields: <String, Object?>{
          for (
            var index = 0;
            index < WizardInputLimits.defaultMaxResolvedFields + 1;
            index++
          )
            'field-$index': index,
        },
        validationResult: ValidationResult(isValid: true),
        buildReady: true,
      );

      final result = compiler.tryCompile(plan);

      expect(result.isCompiled, isFalse);
      expect(result.errors, [WizardResultCodes.resolvedFieldCountTooLarge]);
      expect(result.warnings, isEmpty);
    });

    test('tryCompile rejects direct plans with unsupported nested values', () {
      const compiler = DefaultGameFileCompiler();
      final plan = ValidatedSetupPlan(
        planId: 'plan_invalid_fields',
        modeId: 'open_table',
        variantId: 'holdem_nlhe',
        createdBy: 'host_demo',
        policyProfileIds: <String, String>{},
        resolvedFields: <String, Object?>{'unsupported': Object()},
        validationResult: ValidationResult(isValid: true),
        buildReady: true,
      );

      final result = compiler.tryCompile(plan);

      expect(result.isCompiled, isFalse);
      expect(result.errors, [WizardResultCodes.resolvedFieldsInvalid]);
    });
  });
}
