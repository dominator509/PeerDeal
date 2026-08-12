import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:test/test.dart';

void main() {
  const event = EventEnvelope(
    eventId: 'event_1',
    eventType: 'SessionOpened',
    eventVersion: '1.0',
    protocolVersion: '1.0',
    eventSeq: 1,
    tableId: 'table_1',
    sessionId: 'session_1',
    handId: null,
    emittedAt: '2026-08-12T00:00:00Z',
    actorRef: 'peer_a',
    payload: <String, Object?>{},
    prevEventHash: 'GENESIS',
    eventHash: 'hash_1',
  );
  const conflict = SyncConflict(
    code: 'ERR_TEST_CONFLICT',
    message: 'Test conflict.',
    severity: SyncConflictSeverity.recoverable,
  );

  test('recovery requests and windows own and freeze event collections', () {
    final events = <EventEnvelope>[event];
    final recoveryRequest = RecoveryRequest(
      tableId: 'table_1',
      sessionId: 'session_1',
      protocolVersion: '1.0',
      mode: RecoveryMode.reconnect,
      events: events,
    );
    final snapshotRequest = SnapshotApplyRequest(
      tableId: 'table_1',
      sessionId: 'session_1',
      protocolVersion: '1.0',
      events: events,
    );
    final window = PersistedRecoveryWindow(events: events);

    events.clear();

    expect(recoveryRequest.events, <EventEnvelope>[event]);
    expect(snapshotRequest.events, <EventEnvelope>[event]);
    expect(window.events, <EventEnvelope>[event]);
    expect(() => recoveryRequest.events.clear(), throwsUnsupportedError);
    expect(() => snapshotRequest.events.clear(), throwsUnsupportedError);
    expect(() => window.events.clear(), throwsUnsupportedError);
  });

  test(
    'conflict, recovery, snapshot, and persistence results own collections',
    () {
      final conflicts = <SyncConflict>[conflict];
      final warnings = <String>['warning_1'];
      final notes = <String>['note_1'];
      final reconciliation = ReconciliationResult(
        canResume: false,
        requiresRecovery: true,
        recommendedAction: 'recover',
        notes: notes,
      );
      final detected = ConflictDetectionResult(conflicts: conflicts);
      final recovery = RecoveryResult<bool>(
        isSuccess: false,
        reconciliation: reconciliation,
        conflicts: conflicts,
        safeCloseRecommended: true,
        warnings: warnings,
      );
      final applied = SnapshotApplyResult<bool>(
        state: false,
        appliedEventCount: 0,
        finalAppliedEventSeq: null,
        isSuccess: false,
        conflicts: conflicts,
        warnings: warnings,
      );
      final persisted = RecoveryPersistenceResult(
        isSuccess: false,
        conflicts: conflicts,
        warnings: warnings,
      );
      final successfulPersistence = RecoveryPersistenceResult.success(
        warnings: warnings,
      );

      conflicts.clear();
      warnings.clear();
      notes.clear();

      expect(detected.conflicts, <SyncConflict>[conflict]);
      expect(recovery.conflicts, <SyncConflict>[conflict]);
      expect(applied.conflicts, <SyncConflict>[conflict]);
      expect(persisted.conflicts, <SyncConflict>[conflict]);
      expect(reconciliation.notes, <String>['note_1']);
      expect(recovery.warnings, <String>['warning_1']);
      expect(applied.warnings, <String>['warning_1']);
      expect(persisted.warnings, <String>['warning_1']);
      expect(successfulPersistence.warnings, <String>['warning_1']);
      expect(() => detected.conflicts.clear(), throwsUnsupportedError);
      expect(() => recovery.conflicts.clear(), throwsUnsupportedError);
      expect(() => applied.conflicts.clear(), throwsUnsupportedError);
      expect(() => persisted.conflicts.clear(), throwsUnsupportedError);
      expect(() => reconciliation.notes.clear(), throwsUnsupportedError);
      expect(() => recovery.warnings.clear(), throwsUnsupportedError);
      expect(() => applied.warnings.clear(), throwsUnsupportedError);
      expect(() => persisted.warnings.clear(), throwsUnsupportedError);
      expect(
        () => successfulPersistence.warnings.clear(),
        throwsUnsupportedError,
      );
    },
  );
}
