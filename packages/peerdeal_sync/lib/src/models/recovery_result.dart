import 'package:meta/meta.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import 'reconciliation_result.dart';
import 'sync_conflict.dart';

@immutable
class RecoveryResult<TState> {
  RecoveryResult({
    required this.isSuccess,
    required this.reconciliation,
    required List<SyncConflict> conflicts,
    required this.safeCloseRecommended,
    this.state,
    this.finalAppliedEventSeq,
    List<String> warnings = const <String>[],
  }) : conflicts = List<SyncConflict>.unmodifiable(conflicts),
       warnings = List<String>.unmodifiable(warnings);

  final bool isSuccess;
  final TState? state;
  final ReconciliationResult reconciliation;
  final List<SyncConflict> conflicts;
  final bool safeCloseRecommended;
  final int? finalAppliedEventSeq;
  final List<String> warnings;

  List<ProtocolDiagnostic> get diagnostics => conflicts
      .map((conflict) => conflict.toProtocolDiagnostic())
      .toList(growable: false);
}
