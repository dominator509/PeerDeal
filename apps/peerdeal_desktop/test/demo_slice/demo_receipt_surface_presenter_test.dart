import 'package:peerdeal_desktop/demo_slice/controllers/demo_receipt_surface_presenter.dart';
import 'package:peerdeal_receipts/peerdeal_receipts.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:test/test.dart';

void main() {
  test('presents receipt scan without recovery', () {
    const presenter = DemoReceiptSurfacePresenter();

    final result = presenter.present(
      receipt: const ReceiptScanResult(
        status: 'ok',
        message: 'Receipt resolved.',
        shareableFields: {'receipt_id': 'r_1', 'receipt_token': 'secret'},
      ),
    );

    expect(result.showsRecovery, isFalse);
    expect(result.receipt.shareableFields, {
      'receipt_id': 'r_1',
      'receipt_token': '<redacted>',
    });
  });

  test('presents recovery with scrubbed diagnostics', () {
    const presenter = DemoReceiptSurfacePresenter();

    final result = presenter.present(
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
    expect(result.recovery!.diagnosticsJson.single, {
      'code': 'ERR_FINAL_EVENT_HASH_MISMATCH',
      'message': 'Final event hash does not match expected recovery baseline.',
      'expected': '<redacted>',
      'actual': '<redacted>',
    });
  });
}
