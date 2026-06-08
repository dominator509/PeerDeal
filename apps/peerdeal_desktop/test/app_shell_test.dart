import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdeal_desktop/demo_slice/controllers/demo_receipt_artifact_verifier.dart';
import 'package:peerdeal_desktop/demo_slice/controllers/demo_receipt_artifact_verifier_factory.dart';
import 'package:peerdeal_desktop/demo_slice/controllers/demo_receipt_surface_presenter.dart';
import 'package:peerdeal_desktop/main.dart';
import 'package:peerdeal_desktop/safe_surface/safe_surface.dart';

import '../../../tools/test_helpers/demo_receipt_route_test_support.dart';

void main() {
  testWidgets('mounts demo home instead of placeholder root', (tester) async {
    await tester.pumpWidget(const PeerDealDesktopApp());

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

    await tester.pumpWidget(PeerDealDesktopApp(presenter: presenter));

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
      PeerDealDesktopApp(
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

  testWidgets('fails closed when receipt verifier factory throws', (
    tester,
  ) async {
    final captureBridge = RecordingCaptureProtectionBridge();
    final presenter = DemoReceiptSurfacePresenter(
      captureCoordinator: CaptureSurfaceCoordinator(bridge: captureBridge),
    );

    await tester.pumpWidget(
      PeerDealDesktopApp(
        presenter: presenter,
        receiptExportArtifact: signedDemoReceiptArtifact(),
        receiptArtifactVerifierFactory: _ThrowingVerifierFactory(),
      ),
    );

    await tester.tap(find.text('Receipt'));
    await tester.pumpAndSettle();

    expect(captureBridge.requestCount, 1);
    expect(find.text('Receipt content hidden'), findsOneWidget);
  });

  testWidgets('routes recovery scenario through mounted receipt recovery', (
    tester,
  ) async {
    final captureBridge = RecordingCaptureProtectionBridge();
    final presenter = DemoReceiptSurfacePresenter(
      captureCoordinator: CaptureSurfaceCoordinator(bridge: captureBridge),
    );

    await tester.pumpWidget(PeerDealDesktopApp(presenter: presenter));

    await tester.tap(
      find.text('Scenario: Recovery Pause - Primary-Peer Transfer'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Receipt'));
    await tester.pumpAndSettle();

    expect(captureBridge.requestCount, 2);
    expect(find.text('Receipt content hidden'), findsOneWidget);
    expect(find.textContaining('ERR_FINAL_EVENT_HASH_MISMATCH'), findsNothing);
    expect(find.textContaining('expected_hash'), findsNothing);
    expect(find.textContaining('actual_hash'), findsNothing);
  });

  testWidgets('routes from demo home through table and chat surfaces', (
    tester,
  ) async {
    await tester.pumpWidget(const PeerDealDesktopApp());

    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();

    expect(find.text('Demo table'), findsOneWidget);
    expect(find.text('Scenario: open_table_live_turn'), findsOneWidget);
    expect(find.text('Network: stable'), findsOneWidget);

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();

    expect(find.text('Demo chat'), findsOneWidget);
    expect(find.text('Scenario: open_table_live_turn'), findsOneWidget);
    expect(find.text('Unread: 3'), findsOneWidget);
  });

  testWidgets('routes from demo home to join flow', (tester) async {
    await tester.pumpWidget(const PeerDealDesktopApp());

    await tester.tap(find.text('Join'));
    await tester.pump();

    expect(find.text('Loading join'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Join flow'), findsOneWidget);
    expect(find.text('State: joined'), findsOneWidget);
    expect(find.text('Result: OK_JOINED'), findsOneWidget);
  });

  testWidgets('routes from demo home to setup flow', (tester) async {
    await tester.pumpWidget(const PeerDealDesktopApp());

    await tester.tap(find.text('Setup'));
    await tester.pump();

    expect(find.text('Loading setup'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Setup flow'), findsOneWidget);
    expect(find.text('Status: compiled'), findsOneWidget);
    expect(find.text('Result: OK_GAME_FILE_COMPILED'), findsOneWidget);
  });

  testWidgets('fails closed when app-owned setup factory throws', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
        setupFlowOrchestratorFactory: () {
          throw StateError('setup flow unavailable');
        },
      ),
    );

    await tester.tap(find.text('Setup'));
    await tester.pumpAndSettle();

    expect(find.text('Status: rejected'), findsOneWidget);
    expect(find.text('Result: ERR_SETUP_FLOW_UNAVAILABLE'), findsOneWidget);
  });

  testWidgets('fails closed for unknown app routes', (tester) async {
    await tester.pumpWidget(const PeerDealDesktopApp());

    Navigator.of(
      tester.element(find.text('PeerDeal demo')),
    ).pushNamed('/unknown-route');
    await tester.pumpAndSettle();

    expect(find.text('Route unavailable'), findsOneWidget);
    expect(find.text('State: rejected'), findsOneWidget);
    expect(find.text('Result: ERR_ROUTE_UNAVAILABLE'), findsOneWidget);
    expect(find.text('Route: /unknown-route'), findsOneWidget);
  });

  testWidgets('fails closed when app-owned join factory throws', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
        joinFlowOrchestratorFactory: (_) {
          throw StateError('join flow unavailable');
        },
      ),
    );

    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    expect(find.text('State: joinRejected'), findsOneWidget);
    expect(find.text('Result: ERR_JOIN_FLOW_UNAVAILABLE'), findsOneWidget);
  });

  testWidgets('selected scenario drives mounted demo routes', (tester) async {
    await tester.pumpWidget(const PeerDealDesktopApp());

    await tester.tap(find.text('Scenario: Chat-Heavy Table'));
    await tester.pumpAndSettle();

    expect(find.text('Active scenario: Chat-Heavy Table'), findsOneWidget);

    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();

    expect(find.text('Scenario: chat_heavy_table'), findsOneWidget);
    expect(find.text('Network: stable'), findsOneWidget);

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();

    expect(find.text('Scenario: chat_heavy_table'), findsOneWidget);
    expect(find.text('Unread: 19'), findsOneWidget);
  });

  testWidgets('mounted table classifies recovery network confidence', (
    tester,
  ) async {
    await tester.pumpWidget(const PeerDealDesktopApp());

    await tester.tap(
      find.text('Scenario: Recovery Pause - Primary-Peer Transfer'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();

    expect(find.text('Network: recoveryRequired'), findsOneWidget);
    expect(find.text('Network action: recovery_required'), findsOneWidget);
  });
}

class _ThrowingVerifierFactory extends DemoReceiptArtifactVerifierFactory {
  _ThrowingVerifierFactory()
    : super(bridge: RecordingReceiptKeyStorageBridge());

  @override
  DemoReceiptArtifactVerifier create() {
    throw StateError('verifier factory unavailable');
  }
}
