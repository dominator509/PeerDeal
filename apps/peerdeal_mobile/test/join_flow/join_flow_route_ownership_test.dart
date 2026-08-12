import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdeal_mobile/join_flow/demo_join_flow_orchestrator_factory.dart';
import 'package:peerdeal_mobile/join_flow/fakes.dart';
import 'package:peerdeal_mobile/join_flow/join_flow_route.dart';

void main() {
  testWidgets('join route snapshots enabled mode policy', (tester) async {
    final enabledModes = <JoinFlowDemoMode>{JoinFlowDemoMode.firstJoin};
    final factory = DemoJoinFlowOrchestratorFactory(
      bootstrapCoordinator: FakeBootstrapCoordinator(),
    );
    final route = JoinFlowRoute(
      enabledModes: enabledModes,
      orchestratorFactory: factory.create,
    );

    Widget wrappedRoute() {
      return Directionality(textDirection: TextDirection.ltr, child: route);
    }

    await tester.pumpWidget(wrappedRoute());
    await tester.pumpAndSettle();

    enabledModes.add(JoinFlowDemoMode.rejoin);
    await tester.pumpWidget(wrappedRoute());

    expect(find.text('Run first join'), findsOneWidget);
    expect(find.text('Run rejoin'), findsNothing);
  });
}
