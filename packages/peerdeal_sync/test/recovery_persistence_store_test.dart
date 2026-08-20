import 'dart:convert';
import 'dart:io';

import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:test/test.dart';

String _acceptFixtureEventHash(EventEnvelope event) => event.eventHash;

InMemoryRecoveryPersistenceStore _testStore({
  int maxEvents = InMemoryRecoveryPersistenceStore.defaultMaxEvents,
  int maxEventBytes = InMemoryRecoveryPersistenceStore.defaultMaxEventBytes,
}) => InMemoryRecoveryPersistenceStore(
  maxEvents: maxEvents,
  maxEventBytes: maxEventBytes,
  eventHashCalculator: _acceptFixtureEventHash,
);

JsonFileRecoveryPersistenceStore _testFileStore({
  required Directory rootDirectory,
  int maxFileBytes = JsonFileRecoveryPersistenceStore.defaultMaxFileBytes,
  int maxEvents = InMemoryRecoveryPersistenceStore.defaultMaxEvents,
  int maxEventBytes = InMemoryRecoveryPersistenceStore.defaultMaxEventBytes,
}) => JsonFileRecoveryPersistenceStore(
  rootDirectory: rootDirectory,
  maxFileBytes: maxFileBytes,
  maxEvents: maxEvents,
  maxEventBytes: maxEventBytes,
  eventHashCalculator: _acceptFixtureEventHash,
);

void main() {
  const scope = RecoveryPersistenceScope(
    tableId: 'table_1',
    sessionId: 'session_1',
    protocolVersion: '1.0.0',
  );

  test('appends contiguous events and returns immutable recovery window', () {
    final store = _testStore();

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

  test(
    'rejects an event window above the configured count without mutation',
    () {
      final store = _testStore(maxEvents: 1);
      expect(
        store
            .appendEvents(
              scope: scope,
              events: <EventEnvelope>[
                _event(seq: 1, prevHash: genesisEventHash, hash: 'hash_1'),
              ],
            )
            .isSuccess,
        isTrue,
      );

      final result = store.appendEvents(
        scope: scope,
        events: <EventEnvelope>[
          _event(seq: 2, prevHash: 'hash_1', hash: 'hash_2'),
        ],
      );

      expect(result.isSuccess, isFalse);
      expect(
        result.conflicts.single.code,
        'ERR_RECOVERY_PERSISTENCE_EVENT_COUNT_TOO_LARGE',
      );
      expect(result.conflicts.single.expected, '1');
      expect(result.conflicts.single.actual, '2');
      expect(store.loadWindow(scope).events.map((event) => event.eventSeq), [
        1,
      ]);
    },
  );

  test('rejects an event above the configured byte limit without mutation', () {
    final store = _testStore(maxEventBytes: 1024);
    final result = store.appendEvents(
      scope: scope,
      events: <EventEnvelope>[
        _event(
          seq: 1,
          prevHash: genesisEventHash,
          hash: 'hash_1',
          payload: <String, Object?>{
            'blob': String.fromCharCodes(List<int>.filled(2048, 120)),
          },
        ),
      ],
    );

    expect(result.isSuccess, isFalse);
    expect(
      result.conflicts.single.code,
      'ERR_RECOVERY_PERSISTENCE_EVENT_TOO_LARGE',
    );
    expect(result.conflicts.single.expected, '1024');
    expect(store.loadWindow(scope).events, isEmpty);
  });

  test('rejects an event with a non-JSON payload without mutation', () {
    final store = _testStore();
    final result = store.appendEvents(
      scope: scope,
      events: <EventEnvelope>[
        _event(
          seq: 1,
          prevHash: genesisEventHash,
          hash: 'hash_1',
          payload: <String, Object?>{'invalid': Object()},
        ),
      ],
    );

    expect(result.isSuccess, isFalse);
    expect(
      result.conflicts.single.code,
      'ERR_RECOVERY_PERSISTENCE_EVENT_INVALID',
    );
    expect(store.loadWindow(scope).events, isEmpty);
  });

  test('rejects an unencodable snapshot without mutation', () {
    final store = _testStore();
    final result = store.saveSnapshot(
      scope: scope,
      snapshot: SnapshotEnvelope(
        snapshotId: 'snapshot_0',
        protocolVersion: scope.protocolVersion,
        tableId: scope.tableId,
        sessionId: scope.sessionId,
        snapshotBaseEventSeq: 0,
        snapshotHash: 'unused',
        payload: <String, Object?>{'invalid': Object()},
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(
      result.conflicts.single.code,
      'ERR_RECOVERY_PERSISTENCE_SNAPSHOT_INVALID',
    );
    expect(store.loadWindow(scope).snapshot, isNull);
  });

  test('rejects a tampered snapshot payload hash without mutation', () {
    final store = _testStore();
    final result = store.saveSnapshot(
      scope: scope,
      snapshot: _snapshot(seq: 0, hash: 'tampered_hash'),
    );

    expect(result.isSuccess, isFalse);
    expect(
      result.conflicts.single.code,
      'ERR_RECOVERY_PERSISTENCE_SNAPSHOT_PAYLOAD_HASH_MISMATCH',
    );
    expect(store.loadWindow(scope).snapshot, isNull);
  });

  test('wipes an in-memory recovery window idempotently', () {
    final store = _testStore();
    store.appendEvents(
      scope: scope,
      events: <EventEnvelope>[
        _event(seq: 1, prevHash: genesisEventHash, hash: 'hash_1'),
      ],
    );
    store.saveSnapshot(scope: scope, snapshot: _snapshot(seq: 1));

    final firstWipe = store.wipe(scope: scope);
    final secondWipe = store.wipe(scope: scope);

    expect(firstWipe.isSuccess, isTrue);
    expect(secondWipe.isSuccess, isTrue);
    expect(store.loadWindow(scope).events, isEmpty);
    expect(store.loadWindow(scope).snapshot, isNull);
  });

  test('rejects event append that would create a sequence gap', () {
    final store = _testStore();
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
    final store = _testStore();
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
    final store = _testStore();

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
    final store = _testStore();

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

  test('rejects invalid recovery persistence scope before mutating store', () {
    final store = _testStore();
    const invalidScope = RecoveryPersistenceScope(
      tableId: ' table_1',
      sessionId: 'session_1',
      protocolVersion: '1.0.0',
    );

    final append = store.appendEvents(
      scope: invalidScope,
      events: <EventEnvelope>[
        _event(seq: 1, prevHash: genesisEventHash, hash: 'hash_1'),
      ],
    );
    final snapshot = store.saveSnapshot(
      scope: const RecoveryPersistenceScope(
        tableId: 'table::1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
      ),
      snapshot: _snapshot(seq: 0),
    );
    final wipe = store.wipe(scope: invalidScope);

    expect(append.isSuccess, isFalse);
    expect(
      append.conflicts.single.code,
      'ERR_RECOVERY_PERSISTENCE_SCOPE_INVALID',
    );
    expect(snapshot.isSuccess, isFalse);
    expect(
      snapshot.conflicts.single.code,
      'ERR_RECOVERY_PERSISTENCE_SCOPE_INVALID',
    );
    expect(wipe.isSuccess, isFalse);
    expect(
      wipe.conflicts.single.code,
      'ERR_RECOVERY_PERSISTENCE_SCOPE_INVALID',
    );
    final load = store.loadWindowResult(invalidScope);

    expect(load.isSuccess, isFalse);
    expect(
      load.conflicts.single.code,
      'ERR_RECOVERY_PERSISTENCE_SCOPE_INVALID',
    );
    expect(store.loadWindow(invalidScope).events, isEmpty);
  });

  test('rejects an oversized recovery scope before mutating store', () {
    final store = _testStore();
    final oversizedScope = RecoveryPersistenceScope(
      tableId: 'table_1',
      sessionId: 'x' * RecoveryPersistenceLimits.defaultMaxStorageKeyBytes,
      protocolVersion: '1.0.0',
    );

    expect(oversizedScope.hasValidStorageIdentity, isFalse);
    final append = store.appendEvents(
      scope: oversizedScope,
      events: <EventEnvelope>[
        _event(seq: 1, prevHash: genesisEventHash, hash: 'hash_1'),
      ],
    );

    expect(append.isSuccess, isFalse);
    expect(
      append.conflicts.single.code,
      'ERR_RECOVERY_PERSISTENCE_SCOPE_INVALID',
    );
    expect(store.loadWindow(oversizedScope).events, isEmpty);
  });

  test('stores snapshot only when scope matches persisted recovery stream', () {
    final store = _testStore();
    store.appendEvents(
      scope: scope,
      events: <EventEnvelope>[
        _event(seq: 1, prevHash: genesisEventHash, hash: 'hash_1'),
        _event(seq: 2, prevHash: 'hash_1', hash: 'hash_2'),
      ],
    );

    final result = store.saveSnapshot(
      scope: scope,
      snapshot: SnapshotEnvelope(
        snapshotId: 'snapshot_1',
        protocolVersion: '1.0.0',
        tableId: 'table_1',
        sessionId: 'session_1',
        snapshotBaseEventSeq: 2,
        snapshotHash: computeCanonicalHash(const <String, Object?>{}),
        payload: <String, Object?>{},
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(store.loadWindow(scope).snapshot?.snapshotId, 'snapshot_1');
  });

  test('rejects snapshot ahead of persisted events', () {
    final store = _testStore();
    store.appendEvents(
      scope: scope,
      events: <EventEnvelope>[
        _event(seq: 1, prevHash: genesisEventHash, hash: 'hash_1'),
      ],
    );

    final result = store.saveSnapshot(
      scope: scope,
      snapshot: SnapshotEnvelope(
        snapshotId: 'snapshot_1',
        protocolVersion: '1.0.0',
        tableId: 'table_1',
        sessionId: 'session_1',
        snapshotBaseEventSeq: 2,
        snapshotHash: computeCanonicalHash(const <String, Object?>{}),
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
    final store = _testStore();
    store.appendEvents(
      scope: scope,
      events: <EventEnvelope>[
        _event(seq: 1, prevHash: genesisEventHash, hash: 'hash_1'),
        _event(seq: 2, prevHash: 'hash_1', hash: 'hash_2'),
      ],
    );
    store.saveSnapshot(scope: scope, snapshot: _snapshot(seq: 2));

    final result = store.saveSnapshot(
      scope: scope,
      snapshot: _snapshot(seq: 1),
    );

    expect(result.isSuccess, isFalse);
    expect(
      result.conflicts.single.code,
      'ERR_RECOVERY_PERSISTENCE_SNAPSHOT_REGRESSION',
    );
    expect(store.loadWindow(scope).snapshot?.snapshotBaseEventSeq, 2);
  });

  test('rejects snapshot hash replacement for existing checkpoint', () {
    final store = _testStore();
    store.appendEvents(
      scope: scope,
      events: <EventEnvelope>[
        _event(seq: 1, prevHash: genesisEventHash, hash: 'hash_1'),
      ],
    );
    store.saveSnapshot(
      scope: scope,
      snapshot: _snapshot(seq: 1, payload: <String, Object?>{'version': 1}),
    );

    final result = store.saveSnapshot(
      scope: scope,
      snapshot: _snapshot(seq: 1, payload: <String, Object?>{'version': 2}),
    );

    expect(result.isSuccess, isFalse);
    expect(
      result.conflicts.single.code,
      'ERR_RECOVERY_PERSISTENCE_SNAPSHOT_HASH_MISMATCH',
    );
    expect(
      result.conflicts.single.expected,
      computeCanonicalHash(const <String, Object?>{'version': 1}),
    );
    expect(
      result.conflicts.single.actual,
      computeCanonicalHash(const <String, Object?>{'version': 2}),
    );
    expect(
      store.loadWindow(scope).snapshot?.snapshotHash,
      computeCanonicalHash(const <String, Object?>{'version': 1}),
    );
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

    final writer = _testFileStore(rootDirectory: directory);
    final append = writer.appendEvents(
      scope: scope,
      events: <EventEnvelope>[
        _event(seq: 1, prevHash: genesisEventHash, hash: 'hash_1'),
        _event(seq: 2, prevHash: 'hash_1', hash: 'hash_2'),
      ],
    );
    final snapshot = writer.saveSnapshot(
      scope: scope,
      snapshot: _snapshot(seq: 2),
    );

    final reader = _testFileStore(rootDirectory: directory);
    final window = reader.loadWindow(scope);

    expect(append.isSuccess, isTrue);
    expect(snapshot.isSuccess, isTrue);
    expect(window.events.map((event) => event.eventSeq), <int>[1, 2]);
    expect(
      window.snapshot?.snapshotHash,
      computeCanonicalHash(const <String, Object?>{}),
    );
  });

  test('file store converts root filesystem failures into write results', () {
    final directory = Directory.systemTemp.createTempSync(
      'peerdeal_recovery_store_',
    );
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });

    final rootFile = File('${directory.path}${Platform.pathSeparator}root');
    rootFile.writeAsStringSync('not a directory');
    final writer = _testFileStore(rootDirectory: Directory(rootFile.path));

    final append = writer.appendEvents(
      scope: scope,
      events: <EventEnvelope>[
        _event(seq: 1, prevHash: genesisEventHash, hash: 'hash_1'),
      ],
    );
    final snapshot = writer.saveSnapshot(
      scope: scope,
      snapshot: _snapshot(seq: 0),
    );

    expect(append.isSuccess, isFalse);
    expect(snapshot.isSuccess, isFalse);
    expect(
      append.conflicts.single.code,
      'ERR_RECOVERY_PERSISTENCE_WRITE_FAILED',
    );
    expect(
      snapshot.conflicts.single.code,
      'ERR_RECOVERY_PERSISTENCE_WRITE_FAILED',
    );
  });

  test('file store rejects non-positive file limits', () {
    final directory = Directory.systemTemp.createTempSync(
      'peerdeal_recovery_store_',
    );
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });

    expect(
      () => _testFileStore(rootDirectory: directory, maxFileBytes: 0),
      throwsArgumentError,
    );
    expect(
      () => _testFileStore(rootDirectory: directory, maxEvents: 0),
      throwsArgumentError,
    );
    expect(
      () => _testFileStore(rootDirectory: directory, maxEventBytes: 0),
      throwsArgumentError,
    );
  });

  test(
    'file store rejects an oversized persisted event window before hydration',
    () {
      final directory = Directory.systemTemp.createTempSync(
        'peerdeal_recovery_store_',
      );
      addTearDown(() {
        if (directory.existsSync()) {
          directory.deleteSync(recursive: true);
        }
      });

      final writer = _testFileStore(rootDirectory: directory);
      expect(
        writer
            .appendEvents(
              scope: scope,
              events: <EventEnvelope>[
                _event(seq: 1, prevHash: genesisEventHash, hash: 'hash_1'),
                _event(seq: 2, prevHash: 'hash_1', hash: 'hash_2'),
              ],
            )
            .isSuccess,
        isTrue,
      );

      final limited = _testFileStore(rootDirectory: directory, maxEvents: 1);
      final result = limited.appendEvents(
        scope: scope,
        events: <EventEnvelope>[
          _event(seq: 3, prevHash: 'hash_2', hash: 'hash_3'),
        ],
      );

      expect(result.isSuccess, isFalse);
      expect(
        result.conflicts.single.code,
        'ERR_RECOVERY_PERSISTENCE_EVENT_COUNT_TOO_LARGE',
      );
      expect(result.conflicts.single.expected, '1');
      expect(limited.loadWindow(scope).events, isEmpty);
    },
  );

  test('file store rejects an oversized event before durable replacement', () {
    final directory = Directory.systemTemp.createTempSync(
      'peerdeal_recovery_store_',
    );
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });

    final limited = _testFileStore(
      rootDirectory: directory,
      maxEventBytes: 1024,
    );
    final result = limited.appendEvents(
      scope: scope,
      events: <EventEnvelope>[
        _event(
          seq: 1,
          prevHash: genesisEventHash,
          hash: 'hash_1',
          payload: <String, Object?>{
            'blob': String.fromCharCodes(List<int>.filled(2048, 120)),
          },
        ),
      ],
    );

    expect(result.isSuccess, isFalse);
    expect(
      result.conflicts.single.code,
      'ERR_RECOVERY_PERSISTENCE_EVENT_TOO_LARGE',
    );
    expect(
      directory.listSync().whereType<File>().where(
        (candidate) => candidate.path.endsWith('.json'),
      ),
      isEmpty,
    );
  });

  test('file store rejects oversized persisted windows before decoding', () {
    final directory = Directory.systemTemp.createTempSync(
      'peerdeal_recovery_store_',
    );
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });

    final writer = _testFileStore(rootDirectory: directory);
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
    final file = directory.listSync().whereType<File>().singleWhere(
      (candidate) => candidate.path.endsWith('.json'),
    );
    file.writeAsBytesSync(List<int>.filled(32, 0x20));

    final limited = _testFileStore(rootDirectory: directory, maxFileBytes: 8);
    final result = limited.appendEvents(
      scope: scope,
      events: <EventEnvelope>[
        _event(seq: 2, prevHash: 'hash_1', hash: 'hash_2'),
      ],
    );

    expect(result.isSuccess, isFalse);
    expect(
      result.conflicts.single.code,
      'ERR_RECOVERY_PERSISTENCE_FILE_TOO_LARGE',
    );
    expect(limited.loadWindow(scope).events, isEmpty);
  });

  test('file store refuses to write a window above its configured limit', () {
    final directory = Directory.systemTemp.createTempSync(
      'peerdeal_recovery_store_',
    );
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });

    final limited = _testFileStore(rootDirectory: directory, maxFileBytes: 8);
    final result = limited.appendEvents(
      scope: scope,
      events: <EventEnvelope>[
        _event(seq: 1, prevHash: genesisEventHash, hash: 'hash_1'),
      ],
    );

    expect(result.isSuccess, isFalse);
    expect(
      result.conflicts.single.code,
      'ERR_RECOVERY_PERSISTENCE_FILE_TOO_LARGE',
    );
    expect(
      directory.listSync().whereType<File>().where(
        (candidate) => candidate.path.endsWith('.json'),
      ),
      isEmpty,
    );
  });

  test('file store fails closed when the scope lock cannot be opened', () {
    final directory = Directory.systemTemp.createTempSync(
      'peerdeal_recovery_store_',
    );
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });

    final writer = _testFileStore(rootDirectory: directory);
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

    final lockFile = directory.listSync().whereType<File>().singleWhere(
      (candidate) => candidate.path.endsWith('.lock'),
    );
    lockFile.deleteSync();
    Directory(lockFile.path).createSync();

    final result = writer.appendEvents(
      scope: scope,
      events: <EventEnvelope>[
        _event(seq: 2, prevHash: 'hash_1', hash: 'hash_2'),
      ],
    );

    expect(result.isSuccess, isFalse);
    expect(
      result.conflicts.single.code,
      'ERR_RECOVERY_PERSISTENCE_LOCK_FAILED',
    );

    final load = writer.loadWindowResult(scope);

    expect(load.isSuccess, isFalse);
    expect(load.conflicts.single.code, 'ERR_RECOVERY_PERSISTENCE_LOCK_FAILED');

    Directory(lockFile.path).deleteSync(recursive: true);
    expect(writer.loadWindow(scope).events.map((event) => event.eventSeq), [1]);
  });

  test(
    'file store wipes one scope and interrupted writes without crossing scopes',
    () {
      final directory = Directory.systemTemp.createTempSync(
        'peerdeal_recovery_store_',
      );
      addTearDown(() {
        if (directory.existsSync()) {
          directory.deleteSync(recursive: true);
        }
      });

      final writer = _testFileStore(rootDirectory: directory);
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
      final targetFile = directory.listSync().whereType<File>().singleWhere(
        (candidate) => candidate.path.endsWith('.json'),
      );
      final interruptedWrite = File('${targetFile.path}.tmp.orphan');
      interruptedWrite.writeAsStringSync('stale recovery data');

      const otherScope = RecoveryPersistenceScope(
        tableId: 'table_2',
        sessionId: 'session_2',
        protocolVersion: '1.0.0',
      );
      final otherWriter = _testFileStore(rootDirectory: directory);
      expect(
        otherWriter
            .appendEvents(
              scope: otherScope,
              events: <EventEnvelope>[
                _event(
                  seq: 1,
                  prevHash: genesisEventHash,
                  hash: 'other_hash_1',
                  tableId: 'table_2',
                  sessionId: 'session_2',
                ),
              ],
            )
            .isSuccess,
        isTrue,
      );

      final wipe = writer.wipe(scope: scope);
      final repeatedWipe = writer.wipe(scope: scope);

      expect(wipe.isSuccess, isTrue);
      expect(repeatedWipe.isSuccess, isTrue);
      expect(writer.loadWindow(scope).events, isEmpty);
      expect(writer.loadWindow(scope).snapshot, isNull);
      expect(otherWriter.loadWindow(otherScope).events, hasLength(1));
      expect(
        directory.listSync().whereType<File>().where(
          (candidate) => candidate.path.endsWith('.json'),
        ),
        hasLength(1),
      );
      expect(
        directory.listSync().whereType<File>().where(
          (candidate) => candidate.path.endsWith('.lock'),
        ),
        hasLength(2),
      );
    },
  );

  test('file store writes canonical recovery window JSON', () {
    final directory = Directory.systemTemp.createTempSync(
      'peerdeal_recovery_store_',
    );
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });

    final writer = _testFileStore(rootDirectory: directory);
    final result = writer.appendEvents(
      scope: scope,
      events: <EventEnvelope>[
        _event(seq: 1, prevHash: genesisEventHash, hash: 'hash_1'),
      ],
    );

    final persisted = directory.listSync().whereType<File>().singleWhere(
      (candidate) => candidate.path.endsWith('.json'),
    );
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

  test(
    'file store removes stale temporary files before the next operation',
    () {
      final directory = Directory.systemTemp.createTempSync(
        'peerdeal_recovery_store_',
      );
      addTearDown(() {
        if (directory.existsSync()) {
          directory.deleteSync(recursive: true);
        }
      });

      final writer = _testFileStore(rootDirectory: directory);
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
      final targetFile = directory.listSync().whereType<File>().singleWhere(
        (candidate) => candidate.path.endsWith('.json'),
      );
      final staleTemporaryFile = File('${targetFile.path}.tmp.orphan');
      staleTemporaryFile.writeAsStringSync('sensitive interrupted payload');

      final load = writer.loadWindowResult(scope);

      expect(load.isSuccess, isTrue);
      expect(staleTemporaryFile.existsSync(), isFalse);
      expect(load.window.events.map((event) => event.eventSeq), <int>[1]);
    },
  );

  test('file store rejects structurally oversized persisted snapshots', () {
    final directory = Directory.systemTemp.createTempSync(
      'peerdeal_recovery_store_',
    );
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });

    final writer = _testFileStore(rootDirectory: directory);
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
    final persisted = directory.listSync().whereType<File>().singleWhere(
      (candidate) => candidate.path.endsWith('.json'),
    );
    final oversizedSnapshot = _snapshot(seq: 0, hash: 'snapshot_hash').toJson()
      ..['payload'] = <String, Object?>{
        for (var index = 0; index < 257; index += 1) 'key_$index': index,
      };
    persisted.writeAsStringSync(
      jsonEncode(<String, Object?>{
        'snapshot': oversizedSnapshot,
        'events': const <Object?>[],
      }),
    );

    final result = writer.appendEvents(
      scope: scope,
      events: const <EventEnvelope>[],
    );

    expect(result.isSuccess, isFalse);
    expect(
      result.conflicts.single.code,
      'ERR_RECOVERY_PERSISTENCE_FILE_CORRUPT',
    );
    final load = writer.loadWindowResult(scope);

    expect(load.isSuccess, isFalse);
    expect(load.conflicts.single.code, 'ERR_RECOVERY_PERSISTENCE_FILE_CORRUPT');
    expect(load.window.events, isEmpty);
    expect(writer.loadWindow(scope).events, isEmpty);
  });

  test('file store fails closed on a persisted snapshot hash mismatch', () {
    final directory = Directory.systemTemp.createTempSync(
      'peerdeal_recovery_store_',
    );
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });

    final writer = _testFileStore(rootDirectory: directory);
    expect(
      writer.saveSnapshot(scope: scope, snapshot: _snapshot(seq: 0)).isSuccess,
      isTrue,
    );
    final persisted = directory.listSync().whereType<File>().singleWhere(
      (candidate) => candidate.path.endsWith('.json'),
    );
    final decoded = Map<String, Object?>.from(
      jsonDecode(persisted.readAsStringSync()) as Map,
    );
    final snapshot = Map<String, Object?>.from(decoded['snapshot'] as Map)
      ..['snapshot_hash'] = 'tampered_hash';
    persisted.writeAsStringSync(
      jsonEncode(<String, Object?>{...decoded, 'snapshot': snapshot}),
    );

    final result = writer.loadWindowResult(scope);

    expect(result.isSuccess, isFalse);
    expect(
      result.conflicts.single.code,
      'ERR_RECOVERY_PERSISTENCE_SNAPSHOT_PAYLOAD_HASH_MISMATCH',
    );
    expect(result.window.snapshot, isNull);
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

    final writer = _testFileStore(rootDirectory: directory);
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

    directory
        .listSync()
        .whereType<File>()
        .singleWhere((candidate) => candidate.path.endsWith('.json'))
        .writeAsStringSync('{bad');

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

  test('file store rejects invalid scope before writing recovery files', () {
    final directory = Directory.systemTemp.createTempSync(
      'peerdeal_recovery_store_',
    );
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });

    final writer = _testFileStore(rootDirectory: directory);
    final result = writer.appendEvents(
      scope: const RecoveryPersistenceScope(
        tableId: 'table_1',
        sessionId: 'session_1\nsecret',
        protocolVersion: '1.0.0',
      ),
      events: <EventEnvelope>[
        _event(seq: 1, prevHash: genesisEventHash, hash: 'hash_1'),
      ],
    );

    expect(result.isSuccess, isFalse);
    expect(
      result.conflicts.single.code,
      'ERR_RECOVERY_PERSISTENCE_SCOPE_INVALID',
    );
    expect(directory.listSync(), isEmpty);
  });

  test(
    'file store rejects an oversized scope before writing recovery files',
    () {
      final directory = Directory.systemTemp.createTempSync(
        'peerdeal-recovery-oversized-scope-test-',
      );
      addTearDown(() {
        if (directory.existsSync()) {
          directory.deleteSync(recursive: true);
        }
      });

      final writer = _testFileStore(rootDirectory: directory);
      final result = writer.appendEvents(
        scope: RecoveryPersistenceScope(
          tableId: 'table_1',
          sessionId: 'x' * RecoveryPersistenceLimits.defaultMaxStorageKeyBytes,
          protocolVersion: '1.0.0',
        ),
        events: <EventEnvelope>[
          _event(seq: 1, prevHash: genesisEventHash, hash: 'hash_1'),
        ],
      );

      expect(result.isSuccess, isFalse);
      expect(
        result.conflicts.single.code,
        'ERR_RECOVERY_PERSISTENCE_SCOPE_INVALID',
      );
      expect(directory.listSync(), isEmpty);
    },
  );
}

EventEnvelope _event({
  required int seq,
  required String prevHash,
  required String hash,
  String tableId = 'table_1',
  String sessionId = 'session_1',
  String protocolVersion = '1.0.0',
  Map<String, Object?> payload = const <String, Object?>{},
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
    payload: payload,
    prevEventHash: prevHash,
    eventHash: hash,
  );
}

SnapshotEnvelope _snapshot({
  required int seq,
  String? hash,
  Map<String, Object?> payload = const <String, Object?>{},
}) {
  return SnapshotEnvelope(
    snapshotId: 'snapshot_$seq',
    protocolVersion: '1.0.0',
    tableId: 'table_1',
    sessionId: 'session_1',
    snapshotBaseEventSeq: seq,
    snapshotHash: hash ?? computeCanonicalHash(payload),
    payload: payload,
  );
}
