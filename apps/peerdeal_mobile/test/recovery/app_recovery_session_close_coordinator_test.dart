import 'package:peerdeal_mobile/recovery/app_recovery_retention_coordinator.dart';
import 'package:peerdeal_mobile/recovery/app_recovery_session_close_coordinator.dart';
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

  test('performs one due retention attempt and caches its result', () {
    final store = _FakeRecoveryStore();
    final coordinator = AppRecoverySessionCloseCoordinator(
      retentionCoordinator: AppRecoveryRetentionCoordinator(store: store),
      scope: scope,
      policy: _policy(seconds: 60),
    );

    final first = coordinator.close(
      sessionClosedAt: closedAt,
      now: closedAt.add(const Duration(seconds: 60)),
    );
    final second = coordinator.close(
      sessionClosedAt: closedAt,
      now: closedAt.add(const Duration(days: 1)),
    );

    expect(first.isSuccess, isTrue);
    expect(first.didWipe, isTrue);
    expect(second, same(first));
    expect(store.wipeCalls, 1);
    expect(store.wipedScope, scope);
    expect(coordinator.isClosed, isTrue);
  });

  test('caches a successful no-op and does not re-evaluate later', () {
    final store = _FakeRecoveryStore();
    final coordinator = AppRecoverySessionCloseCoordinator(
      retentionCoordinator: AppRecoveryRetentionCoordinator(store: store),
      scope: scope,
      policy: _policy(seconds: 60),
    );

    final first = coordinator.close(
      sessionClosedAt: closedAt,
      now: closedAt.add(const Duration(seconds: 59)),
    );
    final second = coordinator.close(
      sessionClosedAt: closedAt,
      now: closedAt.add(const Duration(seconds: 60)),
    );

    expect(first.isSuccess, isTrue);
    expect(first.isWipeDue, isFalse);
    expect(second, same(first));
    expect(store.wipeCalls, 0);
    expect(coordinator.isClosed, isTrue);
  });

  test('caches a failed retention attempt without retrying storage', () {
    final store = _FakeRecoveryStore(throwOnWipe: true);
    final coordinator = AppRecoverySessionCloseCoordinator(
      retentionCoordinator: AppRecoveryRetentionCoordinator(store: store),
      scope: scope,
      policy: _policy(seconds: 0),
    );

    final first = coordinator.close(sessionClosedAt: closedAt, now: closedAt);
    final second = coordinator.close(
      sessionClosedAt: closedAt,
      now: closedAt.add(const Duration(days: 1)),
    );

    expect(first.isSuccess, isFalse);
    expect(
      first.persistenceResult.conflicts.single.code,
      'ERR_RECOVERY_RETENTION_WIPE_FAILED',
    );
    expect(second, same(first));
    expect(store.wipeCalls, 1);
    expect(coordinator.isClosed, isTrue);
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
  _FakeRecoveryStore({this.throwOnWipe = false});

  final bool throwOnWipe;
  int wipeCalls = 0;
  RecoveryPersistenceScope? wipedScope;

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
    wipedScope = scope;
    if (throwOnWipe) throw StateError('wipe failed');
    return const RecoveryPersistenceResult.success();
  }

  @override
  PersistedRecoveryWindow loadWindow(RecoveryPersistenceScope scope) {
    return const PersistedRecoveryWindow(events: <EventEnvelope>[]);
  }
}
