import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:test/test.dart';

void main() {
  const scope = RecoveryPersistenceScope(
    tableId: 'table_1',
    sessionId: 'session_1',
    protocolVersion: '1.0.0',
  );

  test('appends contiguous events and returns immutable recovery window', () {
    final store = InMemoryRecoveryPersistenceStore();

    final result = store.appendEvents(
      scope: scope,
      events: <EventEnvelope>[
        _event(seq: 1, prevHash: 'genesis', hash: 'hash_1'),
        _event(seq: 2, prevHash: 'hash_1', hash: 'hash_2'),
      ],
    );

    expect(result.isSuccess, isTrue);
    final window = store.loadWindow(scope);
    expect(window.events.map((event) => event.eventSeq), <int>[1, 2]);
    expect(
      () =>
          window.events.add(_event(seq: 3, prevHash: 'hash_2', hash: 'hash_3')),
      throwsUnsupportedError,
    );
  });

  test('rejects event append that would create a sequence gap', () {
    final store = InMemoryRecoveryPersistenceStore();
    store.appendEvents(
      scope: scope,
      events: <EventEnvelope>[
        _event(seq: 1, prevHash: 'genesis', hash: 'hash_1'),
      ],
    );

    final result = store.appendEvents(
      scope: scope,
      events: <EventEnvelope>[
        _event(seq: 3, prevHash: 'hash_2', hash: 'hash_3'),
      ],
    );

    expect(result.isSuccess, isFalse);
    expect(
      result.conflicts.map((conflict) => conflict.code),
      contains('ERR_RECOVERY_PERSISTENCE_EVENT_SEQUENCE_GAP'),
    );
    expect(store.loadWindow(scope).events.map((event) => event.eventSeq), [1]);
  });

  test('rejects event append that would break hash continuity', () {
    final store = InMemoryRecoveryPersistenceStore();
    store.appendEvents(
      scope: scope,
      events: <EventEnvelope>[
        _event(seq: 1, prevHash: 'genesis', hash: 'hash_1'),
      ],
    );

    final result = store.appendEvents(
      scope: scope,
      events: <EventEnvelope>[
        _event(seq: 2, prevHash: 'hash_diverged', hash: 'hash_2'),
      ],
    );

    expect(result.isSuccess, isFalse);
    expect(
      result.conflicts.single.code,
      'ERR_RECOVERY_PERSISTENCE_EVENT_HASH_CHAIN_BREAK',
    );
    expect(result.conflicts.single.expected, 'hash_1');
    expect(result.conflicts.single.actual, 'hash_diverged');
  });

  test('rejects mismatched event scope without mutating stored stream', () {
    final store = InMemoryRecoveryPersistenceStore();

    final result = store.appendEvents(
      scope: scope,
      events: <EventEnvelope>[
        _event(
          seq: 1,
          prevHash: 'genesis',
          hash: 'hash_1',
          tableId: 'other_table',
        ),
      ],
    );

    expect(result.isSuccess, isFalse);
    expect(
      result.conflicts.map((conflict) => conflict.code),
      contains('ERR_RECOVERY_PERSISTENCE_EVENT_SCOPE_MISMATCH'),
    );
    expect(store.loadWindow(scope).events, isEmpty);
  });

  test('stores snapshot only when scope matches persisted recovery stream', () {
    final store = InMemoryRecoveryPersistenceStore();
    store.appendEvents(
      scope: scope,
      events: <EventEnvelope>[
        _event(seq: 1, prevHash: 'genesis', hash: 'hash_1'),
        _event(seq: 2, prevHash: 'hash_1', hash: 'hash_2'),
      ],
    );

    final result = store.saveSnapshot(
      scope: scope,
      snapshot: const SnapshotEnvelope(
        snapshotId: 'snapshot_1',
        protocolVersion: '1.0.0',
        tableId: 'table_1',
        sessionId: 'session_1',
        snapshotBaseEventSeq: 2,
        snapshotHash: 'snapshot_hash',
        payload: <String, Object?>{},
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(store.loadWindow(scope).snapshot?.snapshotId, 'snapshot_1');
  });

  test('rejects snapshot ahead of persisted events', () {
    final store = InMemoryRecoveryPersistenceStore();
    store.appendEvents(
      scope: scope,
      events: <EventEnvelope>[
        _event(seq: 1, prevHash: 'genesis', hash: 'hash_1'),
      ],
    );

    final result = store.saveSnapshot(
      scope: scope,
      snapshot: const SnapshotEnvelope(
        snapshotId: 'snapshot_1',
        protocolVersion: '1.0.0',
        tableId: 'table_1',
        sessionId: 'session_1',
        snapshotBaseEventSeq: 2,
        snapshotHash: 'snapshot_hash',
        payload: <String, Object?>{},
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(
      result.conflicts.single.code,
      'ERR_RECOVERY_PERSISTENCE_SNAPSHOT_AHEAD_OF_EVENTS',
    );
    expect(store.loadWindow(scope).snapshot, isNull);
  });
}

EventEnvelope _event({
  required int seq,
  required String prevHash,
  required String hash,
  String tableId = 'table_1',
  String sessionId = 'session_1',
  String protocolVersion = '1.0.0',
}) {
  return EventEnvelope(
    eventId: 'evt_$seq',
    eventType: 'RecoveryEventPersisted',
    eventVersion: '1.0',
    protocolVersion: protocolVersion,
    eventSeq: seq,
    tableId: tableId,
    sessionId: sessionId,
    handId: null,
    emittedAt: '2026-06-08T00:00:00Z',
    actorRef: 'system',
    payload: const <String, Object?>{},
    prevEventHash: prevHash,
    eventHash: hash,
  );
}
