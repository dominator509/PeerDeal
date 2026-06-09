import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdeal_mobile/setup_flow/setup_flow_models.dart';
import 'package:peerdeal_mobile/setup_flow/setup_flow_orchestrator.dart';
import 'package:peerdeal_mobile/setup_flow/setup_flow_route.dart';
import 'package:peerdeal_wizard/peerdeal_wizard.dart';

void main() {
  testWidgets('renders compiled setup outcome', (tester) async {
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF1B5E20),
        builder: (_, _) => SetupFlowRoute(
          orchestratorFactory: () => const SetupFlowOrchestrator(),
        ),
      ),
    );

    expect(find.text('Loading setup'), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Setup flow'), findsOneWidget);
    expect(find.text('Status: compiled'), findsOneWidget);
    expect(find.text('Result: OK_GAME_FILE_COMPILED'), findsOneWidget);
    expect(find.text('Game File: 1.0.0'), findsOneWidget);
  });

  testWidgets('can reject invalid setup without throwing', (tester) async {
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF1B5E20),
        builder: (_, _) => SetupFlowRoute(
          orchestratorFactory: () => const SetupFlowOrchestrator(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Compile invalid setup'));
    await tester.pumpAndSettle();

    expect(find.text('Status: rejected'), findsOneWidget);
    expect(find.text('Result: ERR_SETUP_NOT_BUILD_READY'), findsOneWidget);
    expect(find.text('Error: seat_count_missing'), findsOneWidget);
  });

  testWidgets('hides disabled modes and rejects disabled initial mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF1B5E20),
        builder: (_, _) => SetupFlowRoute(
          initialMode: SetupFlowDemoMode.invalid,
          enabledModes: const <SetupFlowDemoMode>{SetupFlowDemoMode.buildReady},
          orchestratorFactory: () => const SetupFlowOrchestrator(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Compile build-ready setup'), findsOneWidget);
    expect(find.text('Compile invalid setup'), findsNothing);
    expect(find.text('Status: rejected'), findsOneWidget);
    expect(find.text('Result: ERR_SETUP_FLOW_MODE_DISABLED'), findsOneWidget);
    expect(find.text('Error: setup_flow_mode_disabled'), findsOneWidget);
  });

  testWidgets('uses injected setup intent factory', (tester) async {
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF1B5E20),
        builder: (_, _) => SetupFlowRoute(
          orchestratorFactory: () => const SetupFlowOrchestrator(),
          setupIntentFactory: (_) => const SetupIntent(
            intentId: 'intent_injected_invalid',
            sourceType: SetupSurface.simple,
            hostPseudonymousId: 'host_injected',
            modePreference: 'open_table',
            variantPreference: 'holdem_nlhe',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Status: rejected'), findsOneWidget);
    expect(find.text('Result: ERR_SETUP_NOT_BUILD_READY'), findsOneWidget);
    expect(find.text('Error: seat_count_missing'), findsOneWidget);
  });

  testWidgets('rejects injected setup intent with blank identity', (
    tester,
  ) async {
    var orchestratorCreated = false;

    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF1B5E20),
        builder: (_, _) => SetupFlowRoute(
          orchestratorFactory: () {
            orchestratorCreated = true;
            return const SetupFlowOrchestrator();
          },
          setupIntentFactory: (_) => const SetupIntent(
            intentId: '   ',
            sourceType: SetupSurface.simple,
            hostPseudonymousId: '   ',
            modePreference: 'open_table',
            variantPreference: 'holdem_nlhe',
            seatCountPreference: 6,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Status: rejected'), findsOneWidget);
    expect(find.text('Result: ERR_SETUP_INTENT_INVALID'), findsOneWidget);
    expect(find.text('Error: setup_intent_id_missing'), findsOneWidget);
    expect(find.text('Error: setup_host_missing'), findsOneWidget);
    expect(orchestratorCreated, isFalse);
  });

  testWidgets('rejects injected setup intent with padded identity', (
    tester,
  ) async {
    var orchestratorCreated = false;

    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF1B5E20),
        builder: (_, _) => SetupFlowRoute(
          orchestratorFactory: () {
            orchestratorCreated = true;
            throw StateError('setup dependency should not run');
          },
          setupIntentFactory: (_) => const SetupIntent(
            intentId: ' intent_open_table ',
            sourceType: SetupSurface.simple,
            hostPseudonymousId: ' host_demo ',
            modePreference: 'open_table',
            variantPreference: 'holdem_nlhe',
            seatCountPreference: 6,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Status: rejected'), findsOneWidget);
    expect(find.text('Result: ERR_SETUP_INTENT_INVALID'), findsOneWidget);
    expect(find.text('Error: setup_intent_id_malformed'), findsOneWidget);
    expect(find.text('Error: setup_host_malformed'), findsOneWidget);
    expect(orchestratorCreated, isFalse);
  });

  testWidgets('fails closed when setup intent factory throws', (tester) async {
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF1B5E20),
        builder: (_, _) => SetupFlowRoute(
          orchestratorFactory: () => const SetupFlowOrchestrator(),
          setupIntentFactory: (_) {
            throw StateError('setup intent unavailable');
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Status: rejected'), findsOneWidget);
    expect(find.text('Result: ERR_SETUP_FLOW_UNAVAILABLE'), findsOneWidget);
    expect(find.text('Error: setup_flow_unavailable'), findsOneWidget);
  });

  testWidgets('fails closed when setup factory throws', (tester) async {
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF1B5E20),
        builder: (_, _) => SetupFlowRoute(
          orchestratorFactory: () {
            throw StateError('setup unavailable');
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Status: rejected'), findsOneWidget);
    expect(find.text('Result: ERR_SETUP_FLOW_UNAVAILABLE'), findsOneWidget);
    expect(find.text('Error: setup_flow_unavailable'), findsOneWidget);
  });

  testWidgets('scrubs injected setup outcome before rendering', (tester) async {
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF1B5E20),
        builder: (_, _) => SetupFlowRoute(
          orchestratorFactory: () => const _LeakySetupFlowOrchestrator(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Status: compiled'), findsOneWidget);
    expect(find.text('Result: OK_GAME_FILE_COMPILED'), findsOneWidget);
    expect(find.text('Game File: unavailable'), findsOneWidget);
    expect(find.text('Error: setup_error_unavailable'), findsOneWidget);
    expect(find.text('Warning: setup_warning_unavailable'), findsOneWidget);
    expect(find.textContaining('secret'), findsNothing);
    expect(find.textContaining('token'), findsNothing);
  });

  testWidgets('rejects unsafe injected setup result codes', (tester) async {
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF1B5E20),
        builder: (_, _) => SetupFlowRoute(
          orchestratorFactory: () => const _UnsafeResultSetupFlowOrchestrator(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Status: rejected'), findsOneWidget);
    expect(find.text('Result: ERR_SETUP_OUTCOME_INVALID'), findsOneWidget);
    expect(find.text('Error: setup_outcome_invalid'), findsOneWidget);
    expect(find.textContaining('secret'), findsNothing);
  });
}

class _LeakySetupFlowOrchestrator extends SetupFlowOrchestrator {
  const _LeakySetupFlowOrchestrator();

  @override
  SetupFlowOutcome compileSetup({
    required SetupIntent intent,
    List<PresetLayer> presetLayers = const <PresetLayer>[],
  }) {
    return const SetupFlowOutcome(
      status: SetupFlowStatus.compiled,
      resultCode: 'OK_GAME_FILE_COMPILED',
      gameFile: <String, Object?>{'game_file_version': r'C:\secret\gamefile'},
      errors: <String>[r'C:\secret\setup.log'],
      warnings: <String>['token sk-demo-secret'],
    );
  }
}

class _UnsafeResultSetupFlowOrchestrator extends SetupFlowOrchestrator {
  const _UnsafeResultSetupFlowOrchestrator();

  @override
  SetupFlowOutcome compileSetup({
    required SetupIntent intent,
    List<PresetLayer> presetLayers = const <PresetLayer>[],
  }) {
    return const SetupFlowOutcome(
      status: SetupFlowStatus.compiled,
      resultCode: r'OK C:\secret',
      errors: <String>[r'C:\secret\setup.log'],
    );
  }
}
