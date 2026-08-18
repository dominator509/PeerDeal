import 'package:peerdeal_desktop/safe_surface/safe_surface.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
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

  test(
    'receipt scan projection scrubs status and message at the safe boundary',
    () {
      const projection = SafeResultProjection();

      final result = projection.projectReceiptScan(
        ReceiptScanResult(
          status: 'ok\n',
          message: 'token=private-value',
          shareableFields: const <String, Object?>{},
        ),
      );

      expect(result.status, 'rejected');
      expect(result.message, 'Receipt detail unavailable.');
    },
  );

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

  test('receipt view model freezes nested shareable fields', () {
    final nested = <String, Object?>{'value': 'original'};
    final result = SafeReceiptScanVm(
      status: 'ok',
      message: 'Receipt resolved.',
      shareableFields: <String, Object?>{'nested': nested},
    );

    nested['value'] = 'changed';

    expect(result.shareableFields['nested'], {'value': 'original'});
    expect(
      () =>
          (result.shareableFields['nested']!
                  as Map<Object?, Object?>)['value'] =
              'changed',
      throwsUnsupportedError,
    );
  });

  test('recovery view model owns diagnostics', () {
    final diagnostics = <ProtocolDiagnostic>[
      ProtocolDiagnostic(code: 'ERR_ONE', message: 'One'),
    ];
    final result = SafeRecoveryVm(
      canResume: false,
      requiresRecovery: true,
      safeCloseRecommended: true,
      recommendedAction: 'safe_close',
      diagnostics: diagnostics,
    );

    diagnostics.clear();

    expect(result.diagnostics, hasLength(1));
    expect(
      () => result.diagnostics.add(result.diagnostics.single),
      throwsUnsupportedError,
    );
  });
}
