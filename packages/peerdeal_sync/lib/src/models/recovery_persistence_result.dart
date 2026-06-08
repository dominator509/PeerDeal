import 'package:meta/meta.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import 'sync_conflict.dart';

@immutable
class RecoveryPersistenceResult {
  const RecoveryPersistenceResult({
    required this.isSuccess,
    this.conflicts = const <SyncConflict>[],
    this.warnings = const <String>[],
  });

  const RecoveryPersistenceResult.success({this.warnings = const <String>[]})
    : isSuccess = true,
      conflicts = const <SyncConflict>[];

  final bool isSuccess;
  final List<SyncConflict> conflicts;
  final List<String> warnings;

  List<ProtocolDiagnostic> get diagnostics => conflicts
      .map((conflict) => conflict.toProtocolDiagnostic())
      .toList(growable: false);
}
