import 'package:meta/meta.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import 'sync_conflict_severity.dart';

@immutable
class SyncConflict {
  const SyncConflict({
    required this.code,
    required this.message,
    required this.severity,
    this.expected,
    this.actual,
  });

  final String code;
  final String message;
  final SyncConflictSeverity severity;
  final String? expected;
  final String? actual;

  bool get isFatal => severity == SyncConflictSeverity.fatal;

  ProtocolDiagnostic toProtocolDiagnostic() {
    return ProtocolDiagnostic(
      code: code,
      message: message,
      expected: expected,
      actual: actual,
    );
  }
}
