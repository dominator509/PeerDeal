import 'package:meta/meta.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import 'sync_conflict.dart';

@immutable
class SnapshotApplyResult<TState> {
  const SnapshotApplyResult({
    required this.state,
    required this.appliedEventCount,
    required this.finalAppliedEventSeq,
    this.isSuccess = true,
    this.conflicts = const <SyncConflict>[],
    this.warnings = const <String>[],
  });

  final TState state;
  final bool isSuccess;
  final int appliedEventCount;
  final int? finalAppliedEventSeq;
  final List<SyncConflict> conflicts;
  final List<String> warnings;

  List<ProtocolDiagnostic> get diagnostics => conflicts
      .map((conflict) => conflict.toProtocolDiagnostic())
      .toList(growable: false);
}
