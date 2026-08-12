import 'package:meta/meta.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import 'persisted_recovery_window.dart';
import 'sync_conflict.dart';

@immutable
class RecoveryPersistenceLoadResult {
  RecoveryPersistenceLoadResult({
    required this.isSuccess,
    required this.window,
    List<SyncConflict> conflicts = const <SyncConflict>[],
    List<String> warnings = const <String>[],
  }) : conflicts = List<SyncConflict>.unmodifiable(conflicts),
       warnings = List<String>.unmodifiable(warnings);

  RecoveryPersistenceLoadResult.success(
    this.window, {
    List<String> warnings = const <String>[],
  }) : isSuccess = true,
       conflicts = const <SyncConflict>[],
       warnings = List<String>.unmodifiable(warnings);

  RecoveryPersistenceLoadResult.failure({
    List<SyncConflict> conflicts = const <SyncConflict>[],
    List<String> warnings = const <String>[],
  }) : isSuccess = false,
       window = PersistedRecoveryWindow(events: <EventEnvelope>[]),
       conflicts = List<SyncConflict>.unmodifiable(conflicts),
       warnings = List<String>.unmodifiable(warnings);

  final bool isSuccess;
  final PersistedRecoveryWindow window;
  final List<SyncConflict> conflicts;
  final List<String> warnings;

  List<ProtocolDiagnostic> get diagnostics => conflicts
      .map((conflict) => conflict.toProtocolDiagnostic())
      .toList(growable: false);
}
