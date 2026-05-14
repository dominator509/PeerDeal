import 'package:peerdeal_privacy/peerdeal_privacy.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_receipts/peerdeal_receipts.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';

class SafeReceiptScanVm {
  const SafeReceiptScanVm({
    required this.status,
    required this.message,
    required this.shareableFields,
  });

  final String status;
  final String message;
  final Map<String, Object?> shareableFields;
}

class SafeRecoveryVm {
  const SafeRecoveryVm({
    required this.canResume,
    required this.requiresRecovery,
    required this.safeCloseRecommended,
    required this.recommendedAction,
    required this.diagnostics,
  });

  final bool canResume;
  final bool requiresRecovery;
  final bool safeCloseRecommended;
  final String recommendedAction;
  final List<ProtocolDiagnostic> diagnostics;

  List<Map<String, Object?>> get diagnosticsJson => diagnostics
      .map((diagnostic) => diagnostic.toJson())
      .toList(growable: false);
}

class SafeResultProjection {
  const SafeResultProjection({
    DiagnosticsScrubber diagnosticsScrubber =
        const DefaultDiagnosticsScrubber(),
  }) : _diagnosticsScrubber = diagnosticsScrubber;

  final DiagnosticsScrubber _diagnosticsScrubber;

  SafeReceiptScanVm projectReceiptScan(ReceiptScanResult result) {
    final scrubbed = _diagnosticsScrubber.scrub(result.shareableFields);
    return SafeReceiptScanVm(
      status: result.status,
      message: result.message,
      shareableFields: Map<String, Object?>.unmodifiable(scrubbed.payload),
    );
  }

  SafeRecoveryVm projectRecovery(RecoveryResult<Object?> result) {
    return SafeRecoveryVm(
      canResume: result.reconciliation.canResume,
      requiresRecovery: result.reconciliation.requiresRecovery,
      safeCloseRecommended: result.safeCloseRecommended,
      recommendedAction: result.reconciliation.recommendedAction,
      diagnostics: List<ProtocolDiagnostic>.unmodifiable(
        _diagnosticsScrubber.scrubProtocolDiagnostics(result.diagnostics),
      ),
    );
  }
}
