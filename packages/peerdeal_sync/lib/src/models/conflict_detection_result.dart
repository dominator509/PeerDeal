import 'package:meta/meta.dart';

import 'sync_conflict.dart';

@immutable
class ConflictDetectionResult {
  const ConflictDetectionResult({required this.conflicts});

  final List<SyncConflict> conflicts;

  bool get hasConflicts => conflicts.isNotEmpty;
  bool get hasFatalConflicts => conflicts.any((conflict) => conflict.isFatal);
  bool get hasRecoverableConflicts => conflicts.any((conflict) => !conflict.isFatal);
}
