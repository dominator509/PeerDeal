import 'package:peerdeal_capture/peerdeal_capture.dart';
import 'package:peerdeal_desktop/demo_slice/controllers/demo_receipt_surface_presenter.dart';
import 'package:peerdeal_desktop/demo_slice/controllers/native_receipt_key_ring_loader.dart';
import 'package:peerdeal_desktop/safe_surface/safe_surface.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_receipts/peerdeal_receipts.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:test/test.dart';

import '../../../../tools/test_helpers/demo_receipt_route_test_support.dart';

void main() {
  test('presents receipt scan with a sensitive capture plan', () async {
    final bridge = RecordingCaptureProtectionBridge();
    final presenter = DemoReceiptSurfacePresenter(
      captureCoordinator: CaptureSurfaceCoordinator(bridge: bridge),
    );

    final result = await presenter.present(
      receipt: const ReceiptScanResult(
        status: 'ok',
        message: 'Receipt resolved.',
        shareableFields: {'receipt_id': 'r_1', 'receipt_token': 'secret'},
      ),
    );

    expect(result.showsRecovery, isFalse);
    expect(result.shouldObscure, isTrue);
    expect(result.receiptCapturePlan.surface, CaptureSurface.receiptDetail);
    expect(result.receiptCapturePlan.shouldRequestNativeBlocking, isTrue);
    expect(result.recoveryCapturePlan, isNull);
    expect(bridge.requestCount, 1);
    expect(result.receipt.shareableFields, {
      'receipt_id': 'r_1',
      'receipt_token': '<redacted>',
    });
  });

  test(
    'presents recovery with scrubbed diagnostics and restore plan',
    () async {
      final bridge = RecordingCaptureProtectionBridge();
      final presenter = DemoReceiptSurfacePresenter(
        captureCoordinator: CaptureSurfaceCoordinator(bridge: bridge),
      );

      final result = await presenter.present(
        receipt: const ReceiptScanResult(
          status: 'ok',
          message: 'Receipt resolved.',
        ),
        recovery: const RecoveryResult<Object?>(
          isSuccess: false,
          reconciliation: ReconciliationResult(
            canResume: false,
            requiresRecovery: true,
            recommendedAction: 'safe_close',
          ),
          conflicts: [
            SyncConflict(
              code: 'ERR_FINAL_EVENT_HASH_MISMATCH',
              message:
                  'Final event hash does not match expected recovery baseline.',
              severity: SyncConflictSeverity.fatal,
              expected: 'expected_hash',
              actual: 'actual_hash',
            ),
          ],
          safeCloseRecommended: true,
        ),
      );

      expect(result.showsRecovery, isTrue);
      expect(result.shouldObscure, isTrue);
      expect(result.receiptCapturePlan.surface, CaptureSurface.receiptDetail);
      expect(result.recoveryCapturePlan!.surface, CaptureSurface.restore);
      expect(result.recoveryCapturePlan!.shouldRequestNativeBlocking, isTrue);
      expect(bridge.requestCount, 2);
      expect(result.recovery!.diagnosticsJson.single, {
        'code': 'ERR_FINAL_EVENT_HASH_MISMATCH',
        'message':
            'Final event hash does not match expected recovery baseline.',
        'expected': '<redacted>',
        'actual': '<redacted>',
      });
    },
  );

  test('verifies signed receipt export artifacts before presenting', () async {
    final bridge = RecordingCaptureProtectionBridge();
    final presenter = DemoReceiptSurfacePresenter(
      captureCoordinator: CaptureSurfaceCoordinator(bridge: bridge),
    );
    final keyRing = await NativeReceiptKeyRingLoader(
      bridge: _FakeSecureKeyStorageBridge(
        snapshot: const SecureKeyStorageSnapshot(
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
        ),
      ),
    ).load();
    final signer = HmacSha256ReceiptSigner(keyProvider: keyRing.keyRing);
    final decoder = OpaqueExportDecoder(signer: signer);

    final result = await presenter.presentExportArtifact(
      artifact: OpaqueExportEncoder(signer: signer).encode(_receipt),
      decoder: decoder,
    );

    expect(result.receipt.status, 'ok');
    expect(result.receipt.message, 'Receipt artifact verified.');
    expect(result.receipt.shareableFields, {
      'receipt_id': 'r_1',
      'receipt_version': '1.0',
      'protocol_version': '1.x',
      'mode_type': 'tournament',
    });
    expect(result.shouldObscure, isTrue);
    expect(bridge.requestCount, 1);
  });

  test('rejects unsigned receipt export artifacts before presenting', () async {
    final bridge = RecordingCaptureProtectionBridge();
    final presenter = DemoReceiptSurfacePresenter(
      captureCoordinator: CaptureSurfaceCoordinator(bridge: bridge),
    );

    final result = await presenter.presentExportArtifact(
      artifact: const OpaqueExportEncoder().encode(_receipt),
      decoder: const OpaqueExportDecoder(),
    );

    expect(result.receipt.status, 'rejected');
    expect(result.receipt.message, 'Receipt artifact is unsigned.');
    expect(result.receipt.shareableFields, isEmpty);
    expect(result.shouldObscure, isTrue);
    expect(bridge.requestCount, 1);
  });
}

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

class _FakeSecureKeyStorageBridge implements SecureKeyStorageBridge {
  const _FakeSecureKeyStorageBridge({required this.snapshot});

  final SecureKeyStorageSnapshot snapshot;

  @override
  Future<SecureKeyStorageSnapshot> loadKeyRing({
    required String namespace,
  }) async {
    return snapshot;
  }
}
