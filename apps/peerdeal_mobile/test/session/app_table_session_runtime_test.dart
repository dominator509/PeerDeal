import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_mobile/recovery/app_recovery_retention_coordinator.dart';
import 'package:peerdeal_mobile/recovery/app_recovery_session_close_coordinator.dart';
import 'package:peerdeal_mobile/recovery/app_recovery_session_close_event_adapter.dart';
import 'package:peerdeal_mobile/session/app_table_session_runtime.dart';
import 'package:peerdeal_privacy/peerdeal_privacy.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:test/test.dart';

void main() {
  const scope = RecoveryPersistenceScope(
    tableId: 'table_1',
    sessionId: 'session_1',
    protocolVersion: '1.0.0',
  );
  final closedAt = DateTime.utc(2026, 8, 9, 12);

  test('projects ordered events through core and enforces close retention', () {
    final store = _FakeRecoveryStore();
    final runtime = _runtime(scope: scope, store: store);

    expect(
      runtime.applyEvent(_event(type: 'OpenTableSessionOpened')).isApplied,
      isTrue,
    );
    expect(
      runtime
          .applyEvent(
            _event(type: 'SessionCloseRequested', seq: 2, prevHash: 'hash_1'),
          )
          .isApplied,
      isTrue,
    );
    final result = runtime.applyEvent(
      _event(type: 'SessionClosed', seq: 3, prevHash: 'hash_2'),
      now: closedAt,
    );

    expect(result.isApplied, isTrue);
    expect(result.recoveryResult!.isSuccess, isTrue);
    expect(runtime.state.phase, TablePhase.closed);
    expect(runtime.acceptedEventCount, 3);
    expect(runtime.lastAcceptedEvent!.eventId, 'evt_3');
    expect(store.wipeCalls, 1);
  });

  test('rejects scope and reducer violations without mutating state', () {
    final runtime = _runtime(scope: scope, store: _FakeRecoveryStore());

    final scopeResult = runtime.applyEvent(_event(tableId: 'table_2'));
    expect(scopeResult.isRejected, isTrue);
    expect(scopeResult.reasonCode, 'ERR_APP_SESSION_SCOPE_MISMATCH');
    expect(runtime.state.eventSequence, 0);

    final gapResult = runtime.applyEvent(_event(seq: 2));
    expect(gapResult.isRejected, isTrue);
    expect(gapResult.reasonCode, 'ERR_EVENT_SEQUENCE_GAP');
    expect(runtime.state.eventSequence, 0);
    expect(runtime.acceptedEventCount, 0);
  });

  test('does not accept a close when retention fails', () {
    final store = _FakeRecoveryStore(throwOnWipe: true);
    final runtime = _runtime(scope: scope, store: store);

    expect(
      runtime.applyEvent(_event(type: 'OpenTableSessionOpened')).isApplied,
      isTrue,
    );
    expect(
      runtime
          .applyEvent(
            _event(type: 'SessionCloseRequested', seq: 2, prevHash: 'hash_1'),
          )
          .isApplied,
      isTrue,
    );
    final result = runtime.applyEvent(
      _event(type: 'SessionClosed', seq: 3, prevHash: 'hash_2'),
      now: closedAt,
    );

    expect(result.isRejected, isTrue);
    expect(result.reasonCode, 'ERR_SESSION_CLOSE_RETENTION_FAILED');
    expect(runtime.state.phase, TablePhase.closing);
    expect(runtime.state.eventSequence, 2);
    expect(runtime.acceptedEventCount, 2);
    expect(store.wipeCalls, 1);
  });

  test('rejects malformed close before retention and state commit', () {
    final store = _FakeRecoveryStore();
    final runtime = _runtime(scope: scope, store: store);

    expect(
      runtime.applyEvent(_event(type: 'OpenTableSessionOpened')).isApplied,
      isTrue,
    );
    expect(
      runtime
          .applyEvent(
            _event(type: 'SessionCloseRequested', seq: 2, prevHash: 'hash_1'),
          )
          .isApplied,
      isTrue,
    );
    final result = runtime.applyEvent(
      _event(
        type: 'SessionClosed',
        seq: 3,
        prevHash: 'hash_2',
        emittedAt: 'not-a-timestamp',
      ),
      now: closedAt,
    );

    expect(result.isRejected, isTrue);
    expect(result.reasonCode, 'ERR_SESSION_CLOSE_RETENTION_REJECTED');
    expect(runtime.state.phase, TablePhase.closing);
    expect(store.wipeCalls, 0);
  });
}

AppTableSessionRuntime _runtime({
  required RecoveryPersistenceScope scope,
  required _FakeRecoveryStore store,
}) {
  return AppTableSessionRuntime(
    initialState: TableState.initial(
      tableId: scope.tableId,
      sessionId: scope.sessionId,
      protocolVersion: scope.protocolVersion,
    ),
    closeEventAdapter: AppRecoverySessionCloseEventAdapter(
      sessionCloseCoordinator: AppRecoverySessionCloseCoordinator(
        retentionCoordinator: AppRecoveryRetentionCoordinator(store: store),
        scope: scope,
        policy: _policy(seconds: 0),
      ),
    ),
  );
}

EventEnvelope _event({
  String type = 'OpenTableSessionOpened',
  int seq = 1,
  String tableId = 'table_1',
  String sessionId = 'session_1',
  String prevHash = 'GENESIS',
  String emittedAt = '2026-08-09T12:00:00.000Z',
}) {
  return EventEnvelope(
    eventId: 'evt_$seq',
    eventType: type,
    eventVersion: '1.0',
    protocolVersion: '1.0.0',
    eventSeq: seq,
    tableId: tableId,
    sessionId: sessionId,
    handId: null,
    emittedAt: emittedAt,
    actorRef: 'actor_1',
    payload: type == 'OpenTableSessionOpened'
        ? const <String, Object?>{'mode_type': 'cash'}
        : const <String, Object?>{},
    prevEventHash: prevHash,
    eventHash: 'hash_$seq',
  );
}

RetentionPolicy _policy({required int seconds}) {
  return RetentionPolicy(
    mode: RetentionMode.timedSandbox,
    wipeSchedule: WipeSchedule(
      mode: 'timed_sandbox',
      timedWipeSeconds: seconds,
      durableExportAllowed: true,
      ephemeralExportOnly: false,
    ),
    manualWipeConfirmation: const ManualWipeConfirmation(
      requiresSecondConfirmation: true,
      confirmationPhrase: 'WIPE RECEIPT',
    ),
    allowSessionRestore: true,
    allowUserRestore: false,
    disappearingPolicy: const DisappearingPolicy(
      disappearingChatEnabled: false,
      disappearingSessionMode: false,
      messageRetentionPolicy: MessageRetentionPolicy.standard,
    ),
    metadataProfile: const MetadataMinimizationProfile(
      minimizeMetadata: true,
      exportMinimalIdentity: true,
      allowPseudonymousAliases: true,
      allowDeviceIdentifiers: false,
      allowIpAddressCapture: false,
    ),
  );
}

class _FakeRecoveryStore implements RecoveryPersistenceStore {
  _FakeRecoveryStore({this.throwOnWipe = false});

  final bool throwOnWipe;
  int wipeCalls = 0;

  @override
  RecoveryPersistenceResult saveSnapshot({
    required RecoveryPersistenceScope scope,
    required SnapshotEnvelope snapshot,
  }) => const RecoveryPersistenceResult.success();

  @override
  RecoveryPersistenceResult appendEvents({
    required RecoveryPersistenceScope scope,
    required List<EventEnvelope> events,
  }) => const RecoveryPersistenceResult.success();

  @override
  RecoveryPersistenceResult wipe({required RecoveryPersistenceScope scope}) {
    wipeCalls++;
    if (throwOnWipe) throw StateError('wipe failed');
    return const RecoveryPersistenceResult.success();
  }

  @override
  PersistedRecoveryWindow loadWindow(RecoveryPersistenceScope scope) =>
      const PersistedRecoveryWindow(events: <EventEnvelope>[]);
}
