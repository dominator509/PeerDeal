import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdeal_mobile/demo_slice/controllers/demo_receipt_artifact_verifier_factory.dart';
import 'package:peerdeal_mobile/demo_slice/controllers/demo_receipt_surface_presenter.dart';
import 'package:peerdeal_mobile/main.dart';
import 'package:peerdeal_mobile/safe_surface/safe_surface.dart';

import '../../../tools/test_helpers/demo_receipt_route_test_support.dart';

void main() {
  testWidgets('mounts demo home instead of placeholder root', (tester) async {
    await tester.pumpWidget(const PeerDealMobileApp());

    expect(find.byType(Placeholder), findsNothing);
    expect(find.text('PeerDeal demo'), findsOneWidget);
    expect(
      find.textContaining('Verification / Receipt Review'),
      findsOneWidget,
    );
  });

  testWidgets('routes from demo home to receipt surface', (tester) async {
    final presenter = DemoReceiptSurfacePresenter(
      captureCoordinator: CaptureSurfaceCoordinator(
        bridge: RecordingCaptureProtectionBridge(),
      ),
    );

    await tester.pumpWidget(PeerDealMobileApp(presenter: presenter));

    await tester.tap(find.text('Receipt'));
    await tester.pump();
    expect(find.text('Loading receipt'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Receipt content hidden'), findsOneWidget);
  });

  testWidgets('routes receipt artifacts through app-owned verifier factory', (
    tester,
  ) async {
    final captureBridge = RecordingCaptureProtectionBridge();
    final keyBridge = RecordingReceiptKeyStorageBridge();
    final presenter = DemoReceiptSurfacePresenter(
      captureCoordinator: CaptureSurfaceCoordinator(bridge: captureBridge),
    );

    await tester.pumpWidget(
      PeerDealMobileApp(
        presenter: presenter,
        receiptExportArtifact: signedDemoReceiptArtifact(),
        receiptArtifactVerifierFactory: DemoReceiptArtifactVerifierFactory(
          bridge: keyBridge,
        ),
      ),
    );

    await tester.tap(find.text('Receipt'));
    await tester.pumpAndSettle();

    expect(keyBridge.namespaces, <String>['peerdeal.receipts']);
    expect(captureBridge.requestCount, 1);
    expect(find.text('Receipt content hidden'), findsOneWidget);
  });

  testWidgets('routes from demo home through table and chat surfaces', (
    tester,
  ) async {
    await tester.pumpWidget(const PeerDealMobileApp());

    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();

    expect(find.text('Demo table'), findsOneWidget);
    expect(find.text('Scenario: open_table_live_turn'), findsOneWidget);

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();

    expect(find.text('Demo chat'), findsOneWidget);
    expect(find.text('Scenario: open_table_live_turn'), findsOneWidget);
    expect(find.text('Unread: 3'), findsOneWidget);
  });

  testWidgets('routes from demo home to join flow', (tester) async {
    await tester.pumpWidget(const PeerDealMobileApp());

    await tester.tap(find.text('Join'));
    await tester.pump();

    expect(find.text('Loading join'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Join flow'), findsOneWidget);
    expect(find.text('State: joined'), findsOneWidget);
    expect(find.text('Result: OK_JOINED'), findsOneWidget);
  });

  testWidgets('selected scenario drives mounted demo routes', (tester) async {
    await tester.pumpWidget(const PeerDealMobileApp());

    await tester.tap(find.text('Scenario: Chat-Heavy Table'));
    await tester.pumpAndSettle();

    expect(find.text('Active scenario: Chat-Heavy Table'), findsOneWidget);

    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();

    expect(find.text('Scenario: chat_heavy_table'), findsOneWidget);

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();

    expect(find.text('Scenario: chat_heavy_table'), findsOneWidget);
    expect(find.text('Unread: 19'), findsOneWidget);
  });
}
