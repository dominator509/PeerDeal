import 'package:peerdeal_desktop/safe_surface/safe_surface.dart';
import 'package:peerdeal_receipts/peerdeal_receipts.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:test/test.dart';

void main() {
  test('receipt scan projection scrubs nested shareable fields', () {
    const projection = SafeResultProjection();

    final result = projection.projectReceiptScan(
      ReceiptScanResult(
        status: 'ok',
        message: 'Receipt resolved for supported client view.',
        shareableFields: {
          'receipt_id': 'r_1',
          'receipt_token': 'opaque-token',
          'peer': {'device_identifier': 'device-1'},
        },
      ),
    );

    expect(result.status, 'ok');
    expect(result.shareableFields, {
      'receipt_id': 'r_1',
      'receipt_token': '<redacted>',
      'peer': {'device_identifier': '<redacted>'},
    });
    expect(
      () => result.shareableFields['receipt_token'] = 'changed',
      throwsUnsupportedError,
    );
  });

  test('recovery projection emits scrubbed protocol diagnostics', () {
    const projection = SafeResultProjection();

    final result = projection.projectRecovery(
      RecoveryResult<Object?>(
        isSuccess: false,
        reconciliation: ReconciliationResult(
          canResume: false,
          requiresRecovery: true,
          recommendedAction: 'safe_close',
        ),
        conflicts: [
          SyncConflict(
            code: 'ERR_RECOVERY_PROTOCOL_INCOMPATIBLE',
            message: 'Recovery request protocol version is not supported.',
            severity: SyncConflictSeverity.fatal,
            expected: '1.0.0',
            actual: '2.0.0',
          ),
        ],
        safeCloseRecommended: true,
      ),
    );

    expect(result.canResume, isFalse);
    expect(result.safeCloseRecommended, isTrue);
    expect(result.diagnosticsJson.single, {
      'code': 'ERR_RECOVERY_PROTOCOL_INCOMPATIBLE',
      'message': 'Recovery request protocol version is not supported.',
      'expected': '<redacted>',
      'actual': '<redacted>',
    });
    expect(
      () => result.diagnostics.add(result.diagnostics.single),
      throwsUnsupportedError,
    );
  });
}
