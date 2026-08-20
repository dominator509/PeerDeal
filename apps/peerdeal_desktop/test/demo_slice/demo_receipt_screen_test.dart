import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdeal_capture/peerdeal_capture.dart';
import 'package:peerdeal_desktop/demo_slice/controllers/demo_receipt_artifact_verifier.dart';
import 'package:peerdeal_desktop/demo_slice/controllers/demo_receipt_surface_presenter.dart';
import 'package:peerdeal_desktop/demo_slice/controllers/native_receipt_export_artifact_factory.dart';
import 'package:peerdeal_desktop/demo_slice/controllers/native_receipt_key_ring_loader.dart';
import 'package:peerdeal_desktop/demo_slice/controllers/native_receipt_key_ring_provisioner.dart';
import 'package:peerdeal_desktop/demo_slice/controllers/native_receipt_key_ring_writer.dart';
import 'package:peerdeal_desktop/demo_slice/models/demo_scenario_snapshot.dart';
import 'package:peerdeal_desktop/demo_slice/screens/demo_receipt_screen.dart';
import 'package:peerdeal_desktop/safe_surface/safe_surface.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_receipts/peerdeal_receipts.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';

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

  testWidgets('scrubs crafted receipt surface text before rendering', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: DemoReceiptScreen(surface: _leakySurface()),
      ),
    );

    expect(find.text('rejected'), findsOneWidget);
    expect(find.text('Receipt detail unavailable.'), findsOneWidget);
    expect(find.text('field_unavailable: unavailable'), findsOneWidget);
    expect(find.text('safe_field: <redacted>'), findsOneWidget);
    expect(find.text('unavailable'), findsOneWidget);
    expect(
      find.text(
        'ERR_RECEIPT_DIAGNOSTIC_UNAVAILABLE: Receipt detail unavailable.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('secret'), findsNothing);
    expect(find.textContaining('token'), findsNothing);
  });

  testWidgets(
    'bounds receipt fields and recovery diagnostics before rendering',
    (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: DemoReceiptScreen(surface: _verboseSurface()),
        ),
      );

      expect(find.text('field_0: value_0'), findsOneWidget);
      expect(find.text('field_3: value_3'), findsOneWidget);
      expect(find.text('field_4: value_4'), findsNothing);
      expect(
        find.text('receipt_fields_truncated: unavailable'),
        findsOneWidget,
      );
      expect(find.text('ERR_RECEIPT_0: Receipt diagnostic 0.'), findsOneWidget);
      expect(find.text('ERR_RECEIPT_3: Receipt diagnostic 3.'), findsOneWidget);
      expect(find.text('ERR_RECEIPT_4: Receipt diagnostic 4.'), findsNothing);
      expect(
        find.text(
          'ERR_RECEIPT_DIAGNOSTICS_TRUNCATED: Receipt detail unavailable.',
        ),
        findsOneWidget,
      );
    },
  );

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

  testWidgets('cancels pending native verification when route is disposed', (
    tester,
  ) async {
    final captureBridge = RecordingCaptureProtectionBridge();
    final keyBridge = _PendingCancellableSecureKeyStorageBridge();
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
    await tester.pump();

    expect(keyBridge.cancellationObserved.isCompleted, isFalse);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    expect(keyBridge.cancellationObserved.isCompleted, isTrue);
  });

  testWidgets(
    'cancels pending native export provisioning when route is disposed',
    (tester) async {
      final captureBridge = RecordingCaptureProtectionBridge();
      final keyBridge = _PendingCancellableSecureKeyStorageBridge();
      final presenter = DemoReceiptSurfacePresenter(
        captureCoordinator: CaptureSurfaceCoordinator(bridge: captureBridge),
      );
      final factory = NativeReceiptExportArtifactFactory(
        keyRingProvisioner: NativeReceiptKeyRingProvisioner(
          loader: NativeReceiptKeyRingLoader(bridge: keyBridge),
          writer: NativeReceiptKeyRingWriter(bridge: keyBridge),
        ),
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: DemoReceiptRoute(
            snapshot: _fixtureSnapshot('verification_receipt_review.json'),
            presenter: presenter,
            receipt: _receipt,
            receiptAuthorization: _authorization,
            cancellableExportArtifactFactory:
                (receipt, {cancellation, authorization}) =>
                    factory.exportSignedEncrypted(
                      receipt,
                      cancellation: cancellation,
                      authorization: authorization,
                    ),
          ),
        ),
      );
      await tester.pump();

      expect(keyBridge.cancellationObserved.isCompleted, isFalse);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      expect(keyBridge.cancellationObserved.isCompleted, isTrue);
    },
  );

  testWidgets('does not verify an unavailable export artifact', (tester) async {
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
          exportArtifact: ReceiptExportArtifact.unavailable(
            reason: 'native key storage detail',
          ),
          artifactVerifier: DemoReceiptArtifactVerifier(
            keyRingLoader: NativeReceiptKeyRingLoader(bridge: keyBridge),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(keyBridge.namespaces, isEmpty);
    expect(captureBridge.requestCount, 1);
    expect(find.text('Receipt content hidden'), findsOneWidget);
    expect(find.textContaining('native key storage detail'), findsNothing);
  });

  testWidgets('rejects conflicting receipt export sources', (tester) async {
    final captureBridge = RecordingCaptureProtectionBridge();
    final presenter = DemoReceiptSurfacePresenter(
      captureCoordinator: CaptureSurfaceCoordinator(bridge: captureBridge),
    );
    var exportFactoryCalled = false;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: DemoReceiptRoute(
          snapshot: _fixtureSnapshot('verification_receipt_review.json'),
          presenter: presenter,
          exportArtifact: _signedArtifact,
          receipt: _receipt,
          exportArtifactFactory: (_, {authorization}) async {
            exportFactoryCalled = true;
            throw StateError('conflicting export source used');
          },
        ),
      ),
    );
    expect(find.text('Loading receipt'), findsOneWidget);

    await tester.pump();

    expect(exportFactoryCalled, isFalse);
    expect(captureBridge.requestCount, 1);
    expect(find.text('Receipt content hidden'), findsOneWidget);
  });

  testWidgets('rejects receipt input without export path', (tester) async {
    final captureBridge = RecordingCaptureProtectionBridge();
    final presenter = DemoReceiptSurfacePresenter(
      captureCoordinator: CaptureSurfaceCoordinator(bridge: captureBridge),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: DemoReceiptRoute(
          snapshot: _fixtureSnapshot('verification_receipt_review.json'),
          presenter: presenter,
          receipt: _receipt,
        ),
      ),
    );
    expect(find.text('Loading receipt'), findsOneWidget);

    await tester.pump();

    expect(captureBridge.requestCount, 1);
    expect(find.text('Receipt content hidden'), findsOneWidget);
  });

  testWidgets('fails closed when receipt presentation throws', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: DemoReceiptRoute(
          snapshot: _fixtureSnapshot('verification_receipt_review.json'),
          presenter: _ThrowingReceiptPresenter(),
        ),
      ),
    );
    expect(find.text('Loading receipt'), findsOneWidget);

    await tester.pump();

    expect(find.text('Loading receipt'), findsNothing);
    expect(find.text('Receipt content hidden'), findsOneWidget);
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
    receipt: SafeReceiptScanVm(
      status: 'ok',
      message: 'Receipt resolved.',
      shareableFields: {'receipt_token': '<redacted>'},
    ),
    receiptCapturePlan: plan,
    safeSurface: SafeSurfaceRenderModel.fromCapturePlans([plan]),
  );
}

DemoReceiptSurfaceVm _verboseSurface() {
  final plan = CaptureSurfacePlan(
    surface: CaptureSurface.receiptDetail,
    decision: const CapturePolicyDecision(
      action: CapturePolicyAction.allow,
      isSensitive: false,
      reason: 'test',
    ),
    nativeNotes: 'test-native',
  );

  return DemoReceiptSurfaceVm(
    receipt: SafeReceiptScanVm(
      status: 'ok',
      message: 'Receipt resolved.',
      shareableFields: <String, Object?>{
        for (var index = 0; index < 8; index++) 'field_$index': 'value_$index',
      },
    ),
    receiptCapturePlan: plan,
    safeSurface: SafeSurfaceRenderModel.fromCapturePlans([plan]),
    recovery: SafeRecoveryVm(
      canResume: false,
      requiresRecovery: true,
      safeCloseRecommended: true,
      recommendedAction: 'safe_close',
      diagnostics: <ProtocolDiagnostic>[
        for (var index = 0; index < 8; index++)
          ProtocolDiagnostic(
            code: 'ERR_RECEIPT_$index',
            message: 'Receipt diagnostic $index.',
          ),
      ],
    ),
  );
}

DemoReceiptSurfaceVm _leakySurface() {
  final plan = CaptureSurfacePlan(
    surface: CaptureSurface.receiptDetail,
    decision: const CapturePolicyDecision(
      action: CapturePolicyAction.allow,
      isSensitive: false,
      reason: 'test',
    ),
    nativeNotes: 'test-native',
  );

  return DemoReceiptSurfaceVm(
    receipt: SafeReceiptScanVm(
      status: r'ok C:\secret',
      message: 'token sk-demo-secret',
      shareableFields: {
        r'bad key C:\secret': r'C:\secret\receipt.log',
        'safe_field': '<redacted>',
      },
    ),
    receiptCapturePlan: plan,
    safeSurface: SafeSurfaceRenderModel.fromCapturePlans([plan]),
    recovery: SafeRecoveryVm(
      canResume: false,
      requiresRecovery: true,
      safeCloseRecommended: true,
      recommendedAction: r'resume C:\secret',
      diagnostics: <ProtocolDiagnostic>[
        ProtocolDiagnostic(
          code: r'ERR C:\secret',
          message: 'token sk-demo-secret',
        ),
      ],
    ),
  );
}

DemoScenarioSnapshot _fixtureSnapshot(String fixtureName) {
  return DemoScenarioSnapshot.fromJson(demoFixtureJson(fixtureName));
}

final _keyRing = ReceiptKeyRingSnapshot(
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

const _authorization = ReceiptAuthorizationRequest(
  requestedByUserId: 'user_7',
  requestedSessionId: 'sess_77',
  accessMode: ReceiptAccessMode.view,
);

final _signedArtifact = OpaqueExportEncoder(
  signer: HmacSha256ReceiptSigner(keyProvider: _keyRing),
).encode(_receipt);

class RecordingSecureKeyStorageBridge implements SecureKeyStorageBridge {
  final List<String> namespaces = <String>[];

  @override
  Future<SecureKeyStorageSnapshot> loadKeyRing({
    required String namespace,
  }) async {
    namespaces.add(namespace);
    return SecureKeyStorageSnapshot(
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

class _PendingCancellableSecureKeyStorageBridge
    implements
        SecureKeyStorageMutationBridge,
        CancellableSecureKeyStorageMutationBridge {
  final Completer<void> cancellationObserved = Completer<void>();
  final Completer<SecureKeyStorageSnapshot> response =
      Completer<SecureKeyStorageSnapshot>();

  @override
  Future<SecureKeyStorageSnapshot> loadKeyRing({
    required String namespace,
    Future<void>? cancellation,
  }) {
    cancellation?.then((_) {
      if (!cancellationObserved.isCompleted) {
        cancellationObserved.complete();
      }
      if (!response.isCompleted) {
        response.complete(
          const SecureKeyStorageSnapshot.unavailable(warning: 'cancelled'),
        );
      }
    });
    return response.future;
  }

  @override
  Future<SecureKeyStorageMutationResult> saveKey({
    required String namespace,
    required SecureKeyRecord key,
    Future<void>? cancellation,
  }) async {
    return const SecureKeyStorageMutationResult.failure(
      warning: 'save not reached',
    );
  }

  @override
  Future<SecureKeyStorageMutationResult> deleteKey({
    required String namespace,
    required String keyId,
    Future<void>? cancellation,
  }) async {
    return const SecureKeyStorageMutationResult.failure(
      warning: 'delete not reached',
    );
  }
}

class _ThrowingReceiptPresenter extends DemoReceiptSurfacePresenter {
  _ThrowingReceiptPresenter()
    : super(
        captureCoordinator: CaptureSurfaceCoordinator(
          bridge: RecordingCaptureProtectionBridge(),
        ),
      );

  @override
  Future<DemoReceiptSurfaceVm> present({
    required ReceiptScanResult receipt,
    RecoveryResult<Object?>? recovery,
    Future<void>? cancellation,
  }) async {
    throw StateError('receipt presentation unavailable');
  }
}
