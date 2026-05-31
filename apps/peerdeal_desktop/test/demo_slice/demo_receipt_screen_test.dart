import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdeal_capture/peerdeal_capture.dart';
import 'package:peerdeal_desktop/demo_slice/controllers/demo_receipt_artifact_verifier.dart';
import 'package:peerdeal_desktop/demo_slice/controllers/demo_receipt_surface_presenter.dart';
import 'package:peerdeal_desktop/demo_slice/controllers/native_receipt_key_ring_loader.dart';
import 'package:peerdeal_desktop/demo_slice/models/demo_scenario_snapshot.dart';
import 'package:peerdeal_desktop/demo_slice/screens/demo_receipt_screen.dart';
import 'package:peerdeal_desktop/safe_surface/safe_surface.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_receipts/peerdeal_receipts.dart';

import '../../../../tools/test_helpers/demo_receipt_route_test_support.dart';

void main() {
  testWidgets('renders receipt details when surface is not obscured', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: DemoReceiptScreen(surface: _surface(shouldObscure: false)),
      ),
    );

    expect(find.text('ok'), findsOneWidget);
    expect(find.text('receipt_token: <redacted>'), findsOneWidget);
    expect(find.text('Receipt content hidden'), findsNothing);
  });

  testWidgets('wraps sensitive receipt details with SafeSurface obscuring', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: DemoReceiptScreen(surface: _surface(shouldObscure: true)),
      ),
    );

    expect(find.text('receipt_token: <redacted>'), findsNothing);
    expect(find.text('Receipt content hidden'), findsOneWidget);
  });

  testWidgets('routes receipt fixture through presenter into safe screen', (
    tester,
  ) async {
    final bridge = RecordingCaptureProtectionBridge();
    final presenter = DemoReceiptSurfacePresenter(
      captureCoordinator: CaptureSurfaceCoordinator(bridge: bridge),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: DemoReceiptRoute(
          snapshot: _fixtureSnapshot('verification_receipt_review.json'),
          presenter: presenter,
        ),
      ),
    );
    expect(find.text('Loading receipt'), findsOneWidget);

    await tester.pump();

    expect(bridge.requestCount, 1);
    expect(find.text('Receipt content hidden'), findsOneWidget);
    expect(find.text('retention_mode: strict_ephemeral'), findsNothing);
  });

  testWidgets('routes recovery fixture through presenter into safe screen', (
    tester,
  ) async {
    final bridge = RecordingCaptureProtectionBridge();
    final presenter = DemoReceiptSurfacePresenter(
      captureCoordinator: CaptureSurfaceCoordinator(bridge: bridge),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: DemoReceiptRoute(
          snapshot: _fixtureSnapshot('recovery_pause_transfer.json'),
          presenter: presenter,
          recovery: demoRecoveryResult(),
        ),
      ),
    );
    expect(find.text('Loading receipt'), findsOneWidget);

    await tester.pump();

    expect(bridge.requestCount, 2);
    expect(find.text('Receipt content hidden'), findsOneWidget);
    expect(find.textContaining('ERR_FINAL_EVENT_HASH_MISMATCH'), findsNothing);
    expect(find.textContaining('expected_hash'), findsNothing);
    expect(find.textContaining('actual_hash'), findsNothing);
    expect(find.textContaining('<redacted>'), findsNothing);
  });

  testWidgets('routes signed artifact through native-backed verifier', (
    tester,
  ) async {
    final captureBridge = RecordingCaptureProtectionBridge();
    final keyBridge = RecordingSecureKeyStorageBridge();
    final presenter = DemoReceiptSurfacePresenter(
      captureCoordinator: CaptureSurfaceCoordinator(bridge: captureBridge),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: DemoReceiptRoute(
          snapshot: _fixtureSnapshot('verification_receipt_review.json'),
          presenter: presenter,
          exportArtifact: _signedArtifact,
          artifactVerifier: DemoReceiptArtifactVerifier(
            keyRingLoader: NativeReceiptKeyRingLoader(bridge: keyBridge),
          ),
        ),
      ),
    );
    expect(find.text('Loading receipt'), findsOneWidget);

    await tester.pump();

    expect(keyBridge.namespaces, <String>['peerdeal.receipts']);
    expect(captureBridge.requestCount, 1);
    expect(find.text('Receipt content hidden'), findsOneWidget);
    expect(find.text('receipt_id: r_1'), findsNothing);
  });
}

DemoReceiptSurfaceVm _surface({required bool shouldObscure}) {
  final plan = CaptureSurfacePlan(
    surface: CaptureSurface.receiptDetail,
    decision: CapturePolicyDecision(
      action: shouldObscure
          ? CapturePolicyAction.obscureOnly
          : CapturePolicyAction.allow,
      isSensitive: shouldObscure,
      reason: 'test',
    ),
    nativeNotes: 'test-native',
  );

  return DemoReceiptSurfaceVm(
    receipt: const SafeReceiptScanVm(
      status: 'ok',
      message: 'Receipt resolved.',
      shareableFields: {'receipt_token': '<redacted>'},
    ),
    receiptCapturePlan: plan,
    safeSurface: SafeSurfaceRenderModel.fromCapturePlans([plan]),
  );
}

DemoScenarioSnapshot _fixtureSnapshot(String fixtureName) {
  return DemoScenarioSnapshot.fromJson(demoFixtureJson(fixtureName));
}

const _keyRing = ReceiptKeyRingSnapshot(
  activeSigning: ReceiptSigningKey(
    keyId: 'receipt_key_1',
    secret: 'test_secret_1',
  ),
);

const _receipt = PeerDealReceipt(
  receiptId: 'r_1',
  receiptVersion: '1.0',
  protocolVersion: '1.x',
  modeType: 'tournament',
  sessionId: 'sess_77',
  tableId: 'table_7',
  pseudonymousUserId: 'user_7',
  bindingMode: ReceiptBindingMode.sessionBound,
  wipeState: ReceiptWipeState.live,
  payloadHash: 'hash_77',
  opaquePayload: 'opaque_77',
);

final _signedArtifact = OpaqueExportEncoder(
  signer: const HmacSha256ReceiptSigner(keyProvider: _keyRing),
).encode(_receipt);

class RecordingSecureKeyStorageBridge implements SecureKeyStorageBridge {
  final List<String> namespaces = <String>[];

  @override
  Future<SecureKeyStorageSnapshot> loadKeyRing({
    required String namespace,
  }) async {
    namespaces.add(namespace);
    return const SecureKeyStorageSnapshot(
      available: true,
      keys: <SecureKeyRecord>[
        SecureKeyRecord(
          keyId: 'receipt_key_1',
          purpose: 'receipt_signing',
          algorithm: 'hmac-sha256',
          secret: 'test_secret_1',
          active: true,
        ),
      ],
    );
  }
}
