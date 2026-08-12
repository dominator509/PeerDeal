import 'package:meta/meta.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import 'sync_conflict.dart';

@immutable
class SnapshotApplyResult<TState> {
  SnapshotApplyResult({
    required this.state,
    required this.appliedEventCount,
    required this.finalAppliedEventSeq,
    this.isSuccess = true,
    List<SyncConflict> conflicts = const <SyncConflict>[],
    List<String> warnings = const <String>[],
  }) : conflicts = List<SyncConflict>.unmodifiable(conflicts),
       warnings = List<String>.unmodifiable(warnings);

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
