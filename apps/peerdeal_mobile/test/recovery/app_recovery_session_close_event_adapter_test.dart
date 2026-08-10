import 'package:peerdeal_mobile/recovery/app_recovery_retention_coordinator.dart';
import 'package:peerdeal_mobile/recovery/app_recovery_session_close_coordinator.dart';
import 'package:peerdeal_mobile/recovery/app_recovery_session_close_event_adapter.dart';
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

  test('ignores non-close events without closing the session', () {
    final store = _FakeRecoveryStore();
    final adapter = _adapter(scope: scope, store: store, seconds: 0);

    final result = adapter.handle(
      _event(eventType: 'SessionCloseRequested'),
      now: closedAt,
    );

    expect(result.isIgnored, isTrue);
    expect(result.isSuccess, isTrue);
    expect(store.wipeCalls, 0);
  });

  test('rejects unsupported or mismatched close events before storage', () {
    final store = _FakeRecoveryStore();
    final adapter = _adapter(scope: scope, store: store, seconds: 0);

    final unsupported = adapter.handle(
      _event(eventVersion: '9.0'),
      now: closedAt,
    );
    final mismatched = adapter.handle(
      _event(tableId: 'table_2'),
      now: closedAt,
    );

    expect(unsupported.isRejected, isTrue);
    expect(unsupported.warning, 'Session close event is not supported.');
    expect(mismatched.isRejected, isTrue);
    expect(
      mismatched.warning,
      'Session close event scope does not match recovery scope.',
    );
    expect(store.wipeCalls, 0);
  });

  test('rejects malformed close timestamps before retention work', () {
    final store = _FakeRecoveryStore();
    final adapter = _adapter(scope: scope, store: store, seconds: 0);

    final result = adapter.handle(
      _event(emittedAt: 'not-a-timestamp'),
      now: closedAt,
    );

    expect(result.isRejected, isTrue);
    expect(result.warning, 'Session close event timestamp is invalid.');
    expect(store.wipeCalls, 0);
  });

  test('uses event close time and caches duplicate delivery', () {
    final store = _FakeRecoveryStore();
    final adapter = _adapter(scope: scope, store: store, seconds: 60);

    final beforeDeadline = adapter.handle(
      _event(),
      now: closedAt.add(const Duration(seconds: 59)),
    );
    final duplicateAtDeadline = adapter.handle(
      _event(
        emittedAt: closedAt.add(const Duration(days: 1)).toIso8601String(),
      ),
      now: closedAt.add(const Duration(seconds: 60)),
    );

    expect(beforeDeadline.isEnforced, isTrue);
    expect(beforeDeadline.enforcementResult!.isWipeDue, isFalse);
    expect(
      duplicateAtDeadline.enforcementResult,
      same(beforeDeadline.enforcementResult),
    );
    expect(store.wipeCalls, 0);
  });

  test('caches a failed close retention outcome across duplicate events', () {
    final store = _FakeRecoveryStore(throwOnWipe: true);
    final adapter = _adapter(scope: scope, store: store, seconds: 0);

    final first = adapter.handle(_event(), now: closedAt);
    final second = adapter.handle(
      _event(
        emittedAt: closedAt.add(const Duration(seconds: 1)).toIso8601String(),
      ),
      now: closedAt.add(const Duration(days: 1)),
    );

    expect(first.isEnforced, isTrue);
    expect(first.isSuccess, isFalse);
    expect(second.enforcementResult, same(first.enforcementResult));
    expect(store.wipeCalls, 1);
  });
}

AppRecoverySessionCloseEventAdapter _adapter({
  required RecoveryPersistenceScope scope,
  required _FakeRecoveryStore store,
  required int seconds,
}) {
  return AppRecoverySessionCloseEventAdapter(
    sessionCloseCoordinator: AppRecoverySessionCloseCoordinator(
      retentionCoordinator: AppRecoveryRetentionCoordinator(store: store),
      scope: scope,
      policy: _policy(seconds: seconds),
    ),
  );
}

EventEnvelope _event({
  String eventType = 'SessionClosed',
  String eventVersion = '1.0',
  String protocolVersion = '1.0.0',
  String tableId = 'table_1',
  String sessionId = 'session_1',
  String emittedAt = '2026-08-09T12:00:00.000Z',
}) {
  return EventEnvelope(
    eventId: 'evt_1',
    eventType: eventType,
    eventVersion: eventVersion,
    protocolVersion: protocolVersion,
    eventSeq: 2,
    tableId: tableId,
    sessionId: sessionId,
    handId: null,
    emittedAt: emittedAt,
    actorRef: 'actor_1',
    payload: const <String, Object?>{},
    prevEventHash: 'prev_hash',
    eventHash: 'event_hash',
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
  PersistedRecoveryWindow loadWindow(RecoveryPersistenceScope scope) {
    return const PersistedRecoveryWindow(events: <EventEnvelope>[]);
  }
}
