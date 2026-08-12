import 'package:peerdeal_privacy/peerdeal_privacy.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_receipts/peerdeal_receipts.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';

class SafeReceiptScanVm {
  SafeReceiptScanVm({
    required this.status,
    required this.message,
    required Map<String, Object?> shareableFields,
  }) : shareableFields = _freezeSafeObjectMap(shareableFields);

  final String status;
  final String message;
  final Map<String, Object?> shareableFields;
}

class SafeRecoveryVm {
  SafeRecoveryVm({
    required this.canResume,
    required this.requiresRecovery,
    required this.safeCloseRecommended,
    required this.recommendedAction,
    required List<ProtocolDiagnostic> diagnostics,
  }) : diagnostics = List<ProtocolDiagnostic>.unmodifiable(diagnostics);

  final bool canResume;
  final bool requiresRecovery;
  final bool safeCloseRecommended;
  final String recommendedAction;
  final List<ProtocolDiagnostic> diagnostics;

  List<Map<String, Object?>> get diagnosticsJson => diagnostics
      .map((diagnostic) => diagnostic.toJson())
      .toList(growable: false);
}

Object? _freezeSafeValue(Object? value) {
  if (value is Map) {
    final frozenEntries = <Object?, Object?>{};
    for (final entry in value.entries) {
      frozenEntries[entry.key] = _freezeSafeValue(entry.value);
    }
    return Map<Object?, Object?>.unmodifiable(frozenEntries);
  }
  if (value is List) {
    return List<Object?>.unmodifiable(value.map<Object?>(_freezeSafeValue));
  }
  if (value is Set) {
    return Set<Object?>.unmodifiable(value.map<Object?>(_freezeSafeValue));
  }
  return value;
}

Map<String, Object?> _freezeSafeObjectMap(Map<String, Object?> source) {
  return Map<String, Object?>.unmodifiable(<String, Object?>{
    for (final entry in source.entries)
      entry.key: _freezeSafeValue(entry.value),
  });
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
