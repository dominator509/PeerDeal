import 'package:meta/meta.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import 'sync_conflict.dart';

@immutable
class ConflictDetectionResult {
  const ConflictDetectionResult({required this.conflicts});

  final List<SyncConflict> conflicts;

  bool get hasConflicts => conflicts.isNotEmpty;
  bool get hasFatalConflicts => conflicts.any((conflict) => conflict.isFatal);
  bool get hasRecoverableConflicts =>
      conflicts.any((conflict) => !conflict.isFatal);
  List<ProtocolDiagnostic> get diagnostics => conflicts
      .map((conflict) => conflict.toProtocolDiagnostic())
      .toList(growable: false);
}
