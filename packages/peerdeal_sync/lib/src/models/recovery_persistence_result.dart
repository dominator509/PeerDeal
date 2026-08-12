import 'package:meta/meta.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import 'sync_conflict.dart';

@immutable
class RecoveryPersistenceResult {
  RecoveryPersistenceResult({
    required this.isSuccess,
    List<SyncConflict> conflicts = const <SyncConflict>[],
    List<String> warnings = const <String>[],
  }) : conflicts = List<SyncConflict>.unmodifiable(conflicts),
       warnings = List<String>.unmodifiable(warnings);

  RecoveryPersistenceResult.success({List<String> warnings = const <String>[]})
    : isSuccess = true,
      conflicts = const <SyncConflict>[],
      warnings = List<String>.unmodifiable(warnings);

  final bool isSuccess;
  final List<SyncConflict> conflicts;
  final List<String> warnings;

  List<ProtocolDiagnostic> get diagnostics => conflicts
      .map((conflict) => conflict.toProtocolDiagnostic())
      .toList(growable: false);
}
