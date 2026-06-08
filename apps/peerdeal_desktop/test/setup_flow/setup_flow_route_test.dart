import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdeal_desktop/setup_flow/setup_flow_orchestrator.dart';
import 'package:peerdeal_desktop/setup_flow/setup_flow_route.dart';

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
}
