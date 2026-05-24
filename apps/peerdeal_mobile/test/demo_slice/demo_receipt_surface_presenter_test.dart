import 'package:peerdeal_capture/peerdeal_capture.dart';
import 'package:peerdeal_mobile/demo_slice/controllers/demo_receipt_surface_presenter.dart';
import 'package:peerdeal_mobile/safe_surface/safe_surface.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_receipts/peerdeal_receipts.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:test/test.dart';

void main() {
  test('presents receipt scan with a sensitive capture plan', () async {
    final bridge = _RecordingCaptureProtectionBridge();
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
      final bridge = _RecordingCaptureProtectionBridge();
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
}

class _RecordingCaptureProtectionBridge implements CaptureProtectionBridge {
  int requestCount = 0;

  @override
  Future<CaptureProtectionCapability> getCapability() async {
    requestCount += 1;
    return const CaptureProtectionCapability(
      blockingSupported: true,
      obscuringSupported: true,
      notes: 'screen-protection-supported',
      warning: 'best-effort',
    );
  }
}
