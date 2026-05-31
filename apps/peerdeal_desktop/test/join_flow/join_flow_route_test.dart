import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdeal_desktop/join_flow/join_flow_route.dart';

void main() {
  testWidgets('runs first join flow on mount', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: JoinFlowRoute(),
      ),
    );

    expect(find.text('Loading join'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('State: joined'), findsOneWidget);
    expect(find.text('Result: OK_JOINED'), findsOneWidget);
  });

  testWidgets('can switch to ack-required and rejoin outcomes', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: JoinFlowRoute(),
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

  testWidgets('can switch to mounted rejection outcomes', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: JoinFlowRoute(),
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
}
