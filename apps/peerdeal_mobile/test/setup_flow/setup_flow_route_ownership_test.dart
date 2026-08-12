import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdeal_mobile/setup_flow/setup_flow_orchestrator.dart';
import 'package:peerdeal_mobile/setup_flow/setup_flow_route.dart';

void main() {
  testWidgets('setup route snapshots enabled mode policy', (tester) async {
    final enabledModes = <SetupFlowDemoMode>{SetupFlowDemoMode.buildReady};
    final route = SetupFlowRoute(
      enabledModes: enabledModes,
      orchestratorFactory: () => const SetupFlowOrchestrator(),
    );

    Widget wrappedRoute() {
      return WidgetsApp(
        color: const Color(0xFF1B5E20),
        builder: (_, _) => route,
      );
    }

    await tester.pumpWidget(wrappedRoute());
    await tester.pumpAndSettle();

    enabledModes.add(SetupFlowDemoMode.invalid);
    await tester.pumpWidget(wrappedRoute());

    expect(find.text('Compile build-ready setup'), findsOneWidget);
    expect(find.text('Compile invalid setup'), findsNothing);
  });
}
