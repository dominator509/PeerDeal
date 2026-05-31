import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdeal_desktop/demo_slice/controllers/demo_receipt_surface_presenter.dart';
import 'package:peerdeal_desktop/main.dart';
import 'package:peerdeal_desktop/safe_surface/safe_surface.dart';

import '../../../tools/test_helpers/demo_receipt_route_test_support.dart';

void main() {
  testWidgets('mounts demo home instead of placeholder root', (tester) async {
    await tester.pumpWidget(const PeerDealDesktopApp());

    expect(find.byType(Placeholder), findsNothing);
    expect(find.text('PeerDeal demo'), findsOneWidget);
    expect(find.text('Verification / Receipt Review'), findsOneWidget);
  });

  testWidgets('routes from demo home to receipt surface', (tester) async {
    final presenter = DemoReceiptSurfacePresenter(
      captureCoordinator: CaptureSurfaceCoordinator(
        bridge: RecordingCaptureProtectionBridge(),
      ),
    );

    await tester.pumpWidget(PeerDealDesktopApp(presenter: presenter));

    await tester.tap(find.text('Receipt'));
    await tester.pump();
    expect(find.text('Loading receipt'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Receipt content hidden'), findsOneWidget);
  });

  testWidgets('routes from demo home through table and chat surfaces', (
    tester,
  ) async {
    await tester.pumpWidget(const PeerDealDesktopApp());

    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();

    expect(find.text('Demo table'), findsOneWidget);
    expect(find.text('Scenario: open_table_live_turn'), findsOneWidget);

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();

    expect(find.text('Demo chat'), findsOneWidget);
    expect(find.text('Scenario: chat_heavy_table'), findsOneWidget);
    expect(find.text('Unread: 19'), findsOneWidget);
  });
}
