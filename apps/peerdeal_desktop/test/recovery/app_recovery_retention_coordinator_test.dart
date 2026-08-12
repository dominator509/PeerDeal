import 'package:peerdeal_desktop/recovery/app_recovery_retention_coordinator.dart';
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

  test('wipes recovery data when the retention schedule is due', () {
    final store = _FakeRecoveryStore();
    final coordinator = AppRecoveryRetentionCoordinator(store: store);

    final result = coordinator.enforceAfterSessionClose(
      scope: scope,
      policy: _policy(seconds: 60),
      sessionClosedAt: closedAt,
      now: closedAt.add(const Duration(seconds: 60)),
    );

    expect(result.isSuccess, isTrue);
    expect(result.isWipeDue, isTrue);
    expect(result.didWipe, isTrue);
    expect(store.wipedScope, scope);
  });

  test('does not touch recovery storage before the retention deadline', () {
    final store = _FakeRecoveryStore();
    final coordinator = AppRecoveryRetentionCoordinator(store: store);

    final result = coordinator.enforceAfterSessionClose(
      scope: scope,
      policy: _policy(seconds: 60),
      sessionClosedAt: closedAt,
      now: closedAt.add(const Duration(seconds: 59)),
    );

    expect(result.isSuccess, isTrue);
    expect(result.isWipeDue, isFalse);
    expect(result.didWipe, isFalse);
    expect(store.wipedScope, isNull);
  });

  test('rejects invalid retention scope before policy or storage work', () {
    final store = _FakeRecoveryStore();
    final coordinator = AppRecoveryRetentionCoordinator(store: store);
    const invalidScope = RecoveryPersistenceScope(
      tableId: ' table_1',
      sessionId: 'session_1',
      protocolVersion: '1.0.0',
    );

    final result = coordinator.enforceAfterSessionClose(
      scope: invalidScope,
      policy: _policy(seconds: 0),
      sessionClosedAt: closedAt,
      now: closedAt,
    );

    expect(result.isSuccess, isFalse);
    expect(result.didWipe, isFalse);
    expect(
      result.persistenceResult.conflicts.single.code,
      'ERR_RECOVERY_RETENTION_SCOPE_INVALID',
    );
    expect(store.wipedScope, isNull);
  });

  test('propagates a failed persistence wipe without claiming deletion', () {
    final store = _FakeRecoveryStore(
      wipeResult: RecoveryPersistenceResult(
        isSuccess: false,
        conflicts: <SyncConflict>[
          SyncConflict(
            code: 'ERR_RECOVERY_PERSISTENCE_WIPE_FAILED',
            message: 'Recovery persistence data could not be wiped.',
            severity: SyncConflictSeverity.fatal,
          ),
        ],
      ),
    );
    final coordinator = AppRecoveryRetentionCoordinator(store: store);

    final result = coordinator.enforceAfterSessionClose(
      scope: scope,
      policy: _policy(seconds: 0),
      sessionClosedAt: closedAt,
      now: closedAt,
    );

    expect(result.isSuccess, isFalse);
    expect(result.isWipeDue, isTrue);
    expect(result.didWipe, isFalse);
    expect(
      result.persistenceResult.conflicts.single.code,
      'ERR_RECOVERY_PERSISTENCE_WIPE_FAILED',
    );
  });

  test('normalizes policy and storage exceptions to fatal outcomes', () {
    final policyFailure =
        AppRecoveryRetentionCoordinator(
          store: _FakeRecoveryStore(),
          retentionPolicyEngine: const _ThrowingRetentionPolicyEngine(),
        ).enforceAfterSessionClose(
          scope: scope,
          policy: _policy(seconds: 0),
          sessionClosedAt: closedAt,
          now: closedAt,
        );
    final storageFailure =
        AppRecoveryRetentionCoordinator(
          store: _FakeRecoveryStore(throwOnWipe: true),
        ).enforceAfterSessionClose(
          scope: scope,
          policy: _policy(seconds: 0),
          sessionClosedAt: closedAt,
          now: closedAt,
        );

    expect(policyFailure.isSuccess, isFalse);
    expect(
      policyFailure.persistenceResult.conflicts.single.code,
      'ERR_RECOVERY_RETENTION_DECISION_FAILED',
    );
    expect(storageFailure.isSuccess, isFalse);
    expect(
      storageFailure.persistenceResult.conflicts.single.code,
      'ERR_RECOVERY_RETENTION_WIPE_FAILED',
    );
  });
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
  _FakeRecoveryStore({
    RecoveryPersistenceResult? wipeResult,
    this.throwOnWipe = false,
  }) : wipeResult = wipeResult ?? RecoveryPersistenceResult.success();

  final RecoveryPersistenceResult wipeResult;
  final bool throwOnWipe;
  RecoveryPersistenceScope? wipedScope;

  @override
  RecoveryPersistenceResult saveSnapshot({
    required RecoveryPersistenceScope scope,
    required SnapshotEnvelope snapshot,
  }) => RecoveryPersistenceResult.success();

  @override
  RecoveryPersistenceResult appendEvents({
    required RecoveryPersistenceScope scope,
    required List<EventEnvelope> events,
  }) => RecoveryPersistenceResult.success();

  @override
  RecoveryPersistenceResult wipe({required RecoveryPersistenceScope scope}) {
    wipedScope = scope;
    if (throwOnWipe) throw StateError('wipe failed');
    return wipeResult;
  }

  @override
  PersistedRecoveryWindow loadWindow(RecoveryPersistenceScope scope) {
    return PersistedRecoveryWindow(events: <EventEnvelope>[]);
  }
}

class _ThrowingRetentionPolicyEngine implements RetentionPolicyEngine {
  const _ThrowingRetentionPolicyEngine();

  @override
  WipeSchedule deriveWipeSchedule(RetentionPolicy policy) {
    throw StateError('policy failed');
  }

  @override
  bool canRestore(RetentionPolicy policy) {
    throw StateError('policy failed');
  }

  @override
  bool isWipeDue({
    required RetentionPolicy policy,
    required DateTime sessionClosedAt,
    required DateTime now,
  }) {
    throw StateError('policy failed');
  }
}
