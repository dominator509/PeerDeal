import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdeal_desktop/join_flow/demo_join_flow_orchestrator_factory.dart';
import 'package:peerdeal_desktop/join_flow/fakes.dart';
import 'package:peerdeal_desktop/join_flow/join_flow_models.dart';
import 'package:peerdeal_desktop/join_flow/join_flow_route.dart';

void main() {
  final demoFactory = DemoJoinFlowOrchestratorFactory(
    bootstrapCoordinator: FakeBootstrapCoordinator(),
  );

  testWidgets('runs first join flow on mount', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: JoinFlowRoute(orchestratorFactory: demoFactory.create),
      ),
    );

    expect(find.text('Loading join'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('State: joined'), findsOneWidget);
    expect(find.text('Result: OK_JOINED'), findsOneWidget);
  });

  testWidgets('can switch to ack-required and rejoin outcomes', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: JoinFlowRoute(orchestratorFactory: demoFactory.create),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Run ack required'));
    await tester.pumpAndSettle();

    expect(find.text('State: ackRequired'), findsOneWidget);
    expect(find.text('Result: ACK_REQUIRED'), findsOneWidget);

    await tester.tap(find.text('Run rejoin'));
    await tester.pumpAndSettle();

    expect(find.text('State: rejoined'), findsOneWidget);
    expect(find.text('Result: OK_REJOINED'), findsOneWidget);
  });

  testWidgets('uses injected invite context factory', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: JoinFlowRoute(
          orchestratorFactory: demoFactory.create,
          inviteContextFactory: (_) => const InviteContext(
            inviteCode: 'ABC123',
            requestedRole: RequestedRole.player,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Run rejoin'));
    await tester.pumpAndSettle();

    expect(find.text('State: joinRejected'), findsOneWidget);
    expect(find.text('Result: ERR_REJOIN_TOKEN_REQUIRED'), findsOneWidget);
  });

  testWidgets('fails closed when invite context factory throws', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: JoinFlowRoute(
          orchestratorFactory: demoFactory.create,
          inviteContextFactory: (_) {
            throw StateError('invite context unavailable');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('State: joinRejected'), findsOneWidget);
    expect(find.text('Result: ERR_JOIN_FLOW_UNAVAILABLE'), findsOneWidget);
  });

  testWidgets('can switch to mounted rejection outcomes', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: JoinFlowRoute(orchestratorFactory: demoFactory.create),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Run unsupported protocol'));
    await tester.pumpAndSettle();

    expect(find.text('State: joinRejected'), findsOneWidget);
    expect(find.text('Result: ERR_PROTOCOL_INCOMPATIBLE'), findsOneWidget);
    expect(
      find.text(
        'ERR_PROTOCOL_INCOMPATIBLE: Invite protocol version is not supported.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Run role denied'));
    await tester.pumpAndSettle();

    expect(find.text('State: joinRejected'), findsOneWidget);
    expect(find.text('Result: ERR_ROLE_DENIED'), findsOneWidget);
  });

  testWidgets('fails closed when route orchestrator setup throws', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: JoinFlowRoute(
          orchestratorFactory: (_) {
            throw StateError('join flow unavailable');
          },
        ),
      ),
    );

    expect(find.text('Loading join'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('State: joinRejected'), findsOneWidget);
    expect(find.text('Result: ERR_JOIN_FLOW_UNAVAILABLE'), findsOneWidget);
    expect(
      find.text('ERR_JOIN_FLOW_UNAVAILABLE: Join flow is unavailable.'),
      findsOneWidget,
    );
  });
}
