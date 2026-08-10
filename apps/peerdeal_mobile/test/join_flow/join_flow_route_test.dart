import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdeal_mobile/join_flow/demo_join_flow_orchestrator_factory.dart';
import 'package:peerdeal_mobile/join_flow/fakes.dart';
import 'package:peerdeal_mobile/join_flow/join_flow_models.dart';
import 'package:peerdeal_mobile/join_flow/join_flow_orchestrator.dart';
import 'package:peerdeal_mobile/join_flow/join_flow_route.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';

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

  testWidgets('forwards a successful resolved invite to product handoff', (
    tester,
  ) async {
    ResolvedInvite? handedOffInvite;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: JoinFlowRoute(
          orchestratorFactory: demoFactory.create,
          onJoinReady: (_, invite) => handedOffInvite = invite,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(handedOffInvite?.inviteId, 'inv_001');
    expect(handedOffInvite?.tableId, 'tbl_001');
  });

  testWidgets('does not hand off rejected join outcomes', (tester) async {
    ResolvedInvite? handedOffInvite;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: JoinFlowRoute(
          initialMode: JoinFlowDemoMode.roleDenied,
          orchestratorFactory: demoFactory.create,
          onJoinReady: (_, invite) => handedOffInvite = invite,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('State: joinRejected'), findsOneWidget);
    expect(handedOffInvite, isNull);
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

  testWidgets('reloads when injected invite context factory changes', (
    tester,
  ) async {
    Widget routeWith(JoinFlowInviteContextFactory inviteContextFactory) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: JoinFlowRoute(
          initialMode: JoinFlowDemoMode.rejoin,
          orchestratorFactory: demoFactory.create,
          inviteContextFactory: inviteContextFactory,
        ),
      );
    }

    await tester.pumpWidget(
      routeWith(
        (_) => const InviteContext(
          inviteCode: 'ABC123',
          requestedRole: RequestedRole.player,
          rejoinToken: 'rj_001',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('State: rejoined'), findsOneWidget);
    expect(find.text('Result: OK_REJOINED'), findsOneWidget);

    await tester.pumpWidget(
      routeWith(
        (_) => const InviteContext(
          inviteCode: 'ABC123',
          requestedRole: RequestedRole.player,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('State: joinRejected'), findsOneWidget);
    expect(find.text('Result: ERR_REJOIN_TOKEN_REQUIRED'), findsOneWidget);
  });

  testWidgets(
    'hides disabled modes and fails closed for disabled initial mode',
    (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: JoinFlowRoute(
            initialMode: JoinFlowDemoMode.rejoin,
            enabledModes: const <JoinFlowDemoMode>{JoinFlowDemoMode.firstJoin},
            orchestratorFactory: demoFactory.create,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Run first join'), findsOneWidget);
      expect(find.text('Run rejoin'), findsNothing);
      expect(find.text('State: joinRejected'), findsOneWidget);
      expect(find.text('Result: ERR_JOIN_FLOW_MODE_DISABLED'), findsOneWidget);
    },
  );

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

  testWidgets('fails closed before orchestration for invalid invite context', (
    tester,
  ) async {
    var orchestratorCreated = false;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: JoinFlowRoute(
          initialMode: JoinFlowDemoMode.rejoin,
          orchestratorFactory: (mode) {
            orchestratorCreated = true;
            return demoFactory.create(mode);
          },
          inviteContextFactory: (_) => const InviteContext(
            inviteCode: '   ',
            requestedRole: RequestedRole.player,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('State: joinRejected'), findsOneWidget);
    expect(find.text('Result: ERR_INVITE_CONTEXT_INVALID'), findsOneWidget);
    expect(
      find.text('ERR_INVITE_CONTEXT_INVALID: Invite context is invalid.'),
      findsOneWidget,
    );
    expect(orchestratorCreated, isFalse);
  });

  testWidgets('fails closed before orchestration for padded invite context', (
    tester,
  ) async {
    var orchestratorCreated = false;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: JoinFlowRoute(
          orchestratorFactory: (_) {
            orchestratorCreated = true;
            throw StateError('join dependency should not run');
          },
          inviteContextFactory: (_) => const InviteContext(
            inviteCode: ' ABC123 ',
            requestedRole: RequestedRole.player,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('State: joinRejected'), findsOneWidget);
    expect(find.text('Result: ERR_INVITE_CONTEXT_INVALID'), findsOneWidget);
    expect(orchestratorCreated, isFalse);
  });

  testWidgets('fails closed before rejoin for whitespace rejoin token', (
    tester,
  ) async {
    var orchestratorCreated = false;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: JoinFlowRoute(
          initialMode: JoinFlowDemoMode.rejoin,
          orchestratorFactory: (mode) {
            orchestratorCreated = true;
            return demoFactory.create(mode);
          },
          inviteContextFactory: (_) => const InviteContext(
            inviteCode: 'ABC123',
            requestedRole: RequestedRole.player,
            rejoinToken: '   ',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('State: joinRejected'), findsOneWidget);
    expect(find.text('Result: ERR_REJOIN_TOKEN_REQUIRED'), findsOneWidget);
    expect(orchestratorCreated, isFalse);
  });

  testWidgets('fails closed before rejoin for padded rejoin token', (
    tester,
  ) async {
    var orchestratorCreated = false;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: JoinFlowRoute(
          initialMode: JoinFlowDemoMode.rejoin,
          orchestratorFactory: (_) {
            orchestratorCreated = true;
            throw StateError('join dependency should not run');
          },
          inviteContextFactory: (_) => const InviteContext(
            inviteCode: 'ABC123',
            requestedRole: RequestedRole.player,
            rejoinToken: ' rj_001 ',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('State: joinRejected'), findsOneWidget);
    expect(find.text('Result: ERR_REJOIN_TOKEN_REQUIRED'), findsOneWidget);
    expect(orchestratorCreated, isFalse);
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

  testWidgets('scrubs injected join diagnostics before rendering', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: JoinFlowRoute(
          orchestratorFactory: (_) => const _LeakyJoinFlowOrchestrator(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('State: joinRejected'), findsOneWidget);
    expect(find.text('Result: ERR_ROLE_DENIED'), findsOneWidget);
    expect(
      find.text(
        'ERR_JOIN_DIAGNOSTIC_UNAVAILABLE: Join diagnostic unavailable.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('secret'), findsNothing);
    expect(find.textContaining('token'), findsNothing);
  });

  testWidgets('rejects unsafe injected join result codes', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: JoinFlowRoute(
          orchestratorFactory: (_) => const _UnsafeResultJoinFlowOrchestrator(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('State: joinRejected'), findsOneWidget);
    expect(find.text('Result: ERR_JOIN_OUTCOME_INVALID'), findsOneWidget);
    expect(
      find.text('ERR_JOIN_OUTCOME_INVALID: Join outcome is invalid.'),
      findsOneWidget,
    );
    expect(find.textContaining('secret'), findsNothing);
  });

  testWidgets('bounds injected join diagnostics before rendering', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: JoinFlowRoute(
          orchestratorFactory: (_) => const _VerboseJoinFlowOrchestrator(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('OK_JOIN_0: Join diagnostic 0.'), findsOneWidget);
    expect(find.text('OK_JOIN_3: Join diagnostic 3.'), findsOneWidget);
    expect(find.text('OK_JOIN_4: Join diagnostic 4.'), findsNothing);
    expect(
      find.text(
        'ERR_JOIN_DIAGNOSTICS_TRUNCATED: Join diagnostics were truncated.',
      ),
      findsOneWidget,
    );
  });
}

class _LeakyJoinFlowOrchestrator implements JoinFlowOrchestrator {
  const _LeakyJoinFlowOrchestrator();

  @override
  Future<JoinFlowOutcome> runFirstJoin(InviteContext context) async {
    return const JoinFlowOutcome(
      state: JoinFlowState.joinRejected,
      status: JoinDecisionStatus.roleDenied,
      resultCode: 'ERR_ROLE_DENIED',
      diagnostics: <ProtocolDiagnostic>[
        ProtocolDiagnostic(
          code: r'ERR C:\secret\join.log',
          message: 'token sk-demo-secret',
        ),
      ],
    );
  }

  @override
  Future<JoinFlowOutcome> runRejoin(InviteContext context) =>
      runFirstJoin(context);
}

class _UnsafeResultJoinFlowOrchestrator implements JoinFlowOrchestrator {
  const _UnsafeResultJoinFlowOrchestrator();

  @override
  Future<JoinFlowOutcome> runFirstJoin(InviteContext context) async {
    return const JoinFlowOutcome(
      state: JoinFlowState.joinReady,
      status: JoinDecisionStatus.okJoinReady,
      resultCode: r'OK C:\secret',
      diagnostics: <ProtocolDiagnostic>[
        ProtocolDiagnostic(
          code: 'OK_JOIN_READY',
          message: r'C:\secret\join.log',
        ),
      ],
    );
  }

  @override
  Future<JoinFlowOutcome> runRejoin(InviteContext context) =>
      runFirstJoin(context);
}

class _VerboseJoinFlowOrchestrator implements JoinFlowOrchestrator {
  const _VerboseJoinFlowOrchestrator();

  @override
  Future<JoinFlowOutcome> runFirstJoin(InviteContext context) async {
    return JoinFlowOutcome(
      state: JoinFlowState.joinRejected,
      status: JoinDecisionStatus.rejected,
      resultCode: 'ERR_JOIN_VERBOSE',
      diagnostics: List<ProtocolDiagnostic>.generate(
        8,
        (index) => ProtocolDiagnostic(
          code: 'OK_JOIN_$index',
          message: 'Join diagnostic $index.',
        ),
      ),
    );
  }

  @override
  Future<JoinFlowOutcome> runRejoin(InviteContext context) =>
      runFirstJoin(context);
}
