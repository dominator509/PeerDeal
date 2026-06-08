import 'dart:io';

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
        _event(seq: 1, prevHash: genesisEventHash, hash: 'hash_1'),
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
        _event(seq: 1, prevHash: genesisEventHash, hash: 'hash_1'),
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
        _event(seq: 1, prevHash: genesisEventHash, hash: 'hash_1'),
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

  test('rejects first event append that does not chain from genesis', () {
    final store = InMemoryRecoveryPersistenceStore();

    final result = store.appendEvents(
      scope: scope,
      events: <EventEnvelope>[_event(seq: 1, prevHash: 'root', hash: 'hash_1')],
    );

    expect(result.isSuccess, isFalse);
    expect(
      result.conflicts.single.code,
      'ERR_RECOVERY_PERSISTENCE_GENESIS_HASH_MISMATCH',
    );
    expect(result.conflicts.single.expected, genesisEventHash);
    expect(result.conflicts.single.actual, 'root');
    expect(store.loadWindow(scope).events, isEmpty);
  });

  test('rejects mismatched event scope without mutating stored stream', () {
    final store = InMemoryRecoveryPersistenceStore();

    final result = store.appendEvents(
      scope: scope,
      events: <EventEnvelope>[
        _event(
          seq: 1,
          prevHash: genesisEventHash,
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
        _event(seq: 1, prevHash: genesisEventHash, hash: 'hash_1'),
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
        _event(seq: 1, prevHash: genesisEventHash, hash: 'hash_1'),
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

  test('rejects snapshot regression without replacing checkpoint', () {
    final store = InMemoryRecoveryPersistenceStore();
    store.appendEvents(
      scope: scope,
      events: <EventEnvelope>[
        _event(seq: 1, prevHash: genesisEventHash, hash: 'hash_1'),
        _event(seq: 2, prevHash: 'hash_1', hash: 'hash_2'),
      ],
    );
    store.saveSnapshot(
      scope: scope,
      snapshot: _snapshot(seq: 2, hash: 'snapshot_hash_2'),
    );

    final result = store.saveSnapshot(
      scope: scope,
      snapshot: _snapshot(seq: 1, hash: 'snapshot_hash_1'),
    );

    expect(result.isSuccess, isFalse);
    expect(
      result.conflicts.single.code,
      'ERR_RECOVERY_PERSISTENCE_SNAPSHOT_REGRESSION',
    );
    expect(store.loadWindow(scope).snapshot?.snapshotBaseEventSeq, 2);
  });

  test('rejects snapshot hash replacement for existing checkpoint', () {
    final store = InMemoryRecoveryPersistenceStore();
    store.appendEvents(
      scope: scope,
      events: <EventEnvelope>[
        _event(seq: 1, prevHash: genesisEventHash, hash: 'hash_1'),
      ],
    );
    store.saveSnapshot(
      scope: scope,
      snapshot: _snapshot(seq: 1, hash: 'snapshot_hash_1'),
    );

    final result = store.saveSnapshot(
      scope: scope,
      snapshot: _snapshot(seq: 1, hash: 'snapshot_hash_tampered'),
    );

    expect(result.isSuccess, isFalse);
    expect(
      result.conflicts.single.code,
      'ERR_RECOVERY_PERSISTENCE_SNAPSHOT_HASH_MISMATCH',
    );
    expect(result.conflicts.single.expected, 'snapshot_hash_1');
    expect(result.conflicts.single.actual, 'snapshot_hash_tampered');
    expect(store.loadWindow(scope).snapshot?.snapshotHash, 'snapshot_hash_1');
  });

  test('file store persists recovery windows across store instances', () {
    final directory = Directory.systemTemp.createTempSync(
      'peerdeal_recovery_store_',
    );
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });

    final writer = JsonFileRecoveryPersistenceStore(rootDirectory: directory);
    final append = writer.appendEvents(
      scope: scope,
      events: <EventEnvelope>[
        _event(seq: 1, prevHash: genesisEventHash, hash: 'hash_1'),
        _event(seq: 2, prevHash: 'hash_1', hash: 'hash_2'),
      ],
    );
    final snapshot = writer.saveSnapshot(
      scope: scope,
      snapshot: _snapshot(seq: 2, hash: 'snapshot_hash_2'),
    );

    final reader = JsonFileRecoveryPersistenceStore(rootDirectory: directory);
    final window = reader.loadWindow(scope);

    expect(append.isSuccess, isTrue);
    expect(snapshot.isSuccess, isTrue);
    expect(window.events.map((event) => event.eventSeq), <int>[1, 2]);
    expect(window.snapshot?.snapshotHash, 'snapshot_hash_2');
  });

  test('file store writes canonical recovery window JSON', () {
    final directory = Directory.systemTemp.createTempSync(
      'peerdeal_recovery_store_',
    );
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });

    final writer = JsonFileRecoveryPersistenceStore(rootDirectory: directory);
    final result = writer.appendEvents(
      scope: scope,
      events: <EventEnvelope>[
        _event(seq: 1, prevHash: genesisEventHash, hash: 'hash_1'),
      ],
    );

    final persisted = directory.listSync().whereType<File>().single;
    final rawJson = persisted.readAsStringSync();

    expect(result.isSuccess, isTrue);
    expect(rawJson, startsWith('{"events":['));
    expect(
      rawJson,
      canonicalJsonEncode(<String, Object?>{
        'snapshot': null,
        'events': <Object?>[
          _event(seq: 1, prevHash: genesisEventHash, hash: 'hash_1').toJson(),
        ],
      }),
    );
  });

  test('file store fails closed on corrupt persisted data', () {
    final directory = Directory.systemTemp.createTempSync(
      'peerdeal_recovery_store_',
    );
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });

    final writer = JsonFileRecoveryPersistenceStore(rootDirectory: directory);
    expect(
      writer
          .appendEvents(
            scope: scope,
            events: <EventEnvelope>[
              _event(seq: 1, prevHash: genesisEventHash, hash: 'hash_1'),
            ],
          )
          .isSuccess,
      isTrue,
    );

    directory.listSync().whereType<File>().single.writeAsStringSync('{bad');

    final result = writer.appendEvents(
      scope: scope,
      events: <EventEnvelope>[
        _event(seq: 2, prevHash: 'hash_1', hash: 'hash_2'),
      ],
    );

    expect(result.isSuccess, isFalse);
    expect(
      result.conflicts.single.code,
      'ERR_RECOVERY_PERSISTENCE_FILE_CORRUPT',
    );
    expect(writer.loadWindow(scope).events, isEmpty);
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

SnapshotEnvelope _snapshot({required int seq, required String hash}) {
  return SnapshotEnvelope(
    snapshotId: 'snapshot_$seq',
    protocolVersion: '1.0.0',
    tableId: 'table_1',
    sessionId: 'session_1',
    snapshotBaseEventSeq: seq,
    snapshotHash: hash,
    payload: const <String, Object?>{},
  );
}
