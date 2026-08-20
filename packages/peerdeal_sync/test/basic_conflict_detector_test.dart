import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:test/test.dart';

String _acceptFixtureEventHash(EventEnvelope event) => event.eventHash;

BasicConflictDetector _testDetector({
  ProtocolCatalog protocolCatalog = const ProtocolCatalog(),
  int maxEvents = RecoveryEventWindowLimits.defaultMaxEvents,
  EventEnvelopeCodec eventCodec = const EventEnvelopeCodec(
    maxBytes: RecoveryEventWindowLimits.defaultMaxEventBytes,
  ),
  CanonicalJsonLimits snapshotLimits = const CanonicalJsonLimits(
    maxEncodedBytes: RecoveryEventWindowLimits.defaultMaxSnapshotBytes,
  ),
}) => BasicConflictDetector(
  protocolCatalog: protocolCatalog,
  maxEvents: maxEvents,
  eventCodec: eventCodec,
  snapshotLimits: snapshotLimits,
  eventHashCalculator: _acceptFixtureEventHash,
);

void main() {
  final detector = _testDetector();

  test('rejects an invalid direct request scope before traversing events', () {
    final result = detector.detect(
      RecoveryRequest(
        tableId: 'table_1',
        sessionId: 'x' * RecoveryPersistenceLimits.defaultMaxStorageKeyBytes,
        protocolVersion: '1.0.0',
        mode: RecoveryMode.reconnect,
        events: const <EventEnvelope>[],
      ),
    );

    expect(result.conflicts.single.code, 'ERR_RECOVERY_SCOPE_INVALID');
  });

  test('rejects an oversized event window before traversing events', () {
    final request = RecoveryRequest(
      tableId: 'table_1',
      sessionId: 'session_1',
      protocolVersion: '2.0.0',
      mode: RecoveryMode.reconnect,
      events: <EventEnvelope>[
        EventEnvelope(
          eventId: 'evt_1',
          eventType: 'OpenTableSessionOpened',
          eventVersion: '1.0',
          protocolVersion: '1.0.0',
          eventSeq: 1,
          tableId: 'table_1',
          sessionId: 'session_1',
          handId: null,
          emittedAt: '2026-04-25T00:00:00Z',
          actorRef: 'system',
          payload: <String, Object?>{},
          prevEventHash: genesisEventHash,
          eventHash: 'hash_1',
        ),
        EventEnvelope(
          eventId: 'evt_2',
          eventType: 'RecoveryPauseEnded',
          eventVersion: '1.0',
          protocolVersion: '1.0.0',
          eventSeq: 2,
          tableId: 'other_table',
          sessionId: 'session_1',
          handId: null,
          emittedAt: '2026-04-25T00:00:01Z',
          actorRef: 'system',
          payload: <String, Object?>{},
          prevEventHash: 'hash_1',
          eventHash: 'hash_2',
        ),
      ],
    );

    final result = _testDetector(maxEvents: 1).detect(request);

    expect(result.conflicts.single.code, 'ERR_RECOVERY_EVENT_COUNT_TOO_LARGE');
    expect(result.conflicts.single.expected, '1');
    expect(result.conflicts.single.actual, '2');
  });

  test('rejects an oversized direct event before protocol inspection', () {
    final result = _testDetector(eventCodec: EventEnvelopeCodec(maxBytes: 256))
        .detect(
          RecoveryRequest(
            tableId: 'table_1',
            sessionId: 'session_1',
            protocolVersion: '2.0.0',
            mode: RecoveryMode.reconnect,
            events: <EventEnvelope>[
              _event(
                1,
                prevEventHash: genesisEventHash,
                eventHash: 'hash_1',
                payload: <String, Object?>{'oversized': 'x' * 1024},
              ),
            ],
          ),
        );

    expect(result.conflicts.single.code, 'ERR_RECOVERY_EVENT_TOO_LARGE');
    expect(result.conflicts.single.expected, '256');
  });

  test('rejects a direct event with an unencodable payload', () {
    final result = detector.detect(
      RecoveryRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        mode: RecoveryMode.reconnect,
        events: <EventEnvelope>[
          _event(
            1,
            prevEventHash: genesisEventHash,
            eventHash: 'hash_1',
            payload: <String, Object?>{'unsupported': Object()},
          ),
        ],
      ),
    );

    expect(result.conflicts.single.code, 'ERR_RECOVERY_EVENT_INVALID');
  });

  test('rejects an oversized direct snapshot before protocol inspection', () {
    final result =
        _testDetector(
          snapshotLimits: CanonicalJsonLimits(maxEncodedBytes: 256),
        ).detect(
          RecoveryRequest(
            tableId: 'table_1',
            sessionId: 'session_1',
            protocolVersion: '2.0.0',
            mode: RecoveryMode.reconnect,
            snapshot: SnapshotEnvelope(
              snapshotId: 'snap_1',
              protocolVersion: '1.0.0',
              tableId: 'table_1',
              sessionId: 'session_1',
              snapshotBaseEventSeq: 1,
              snapshotHash: computeCanonicalHash(const <String, Object?>{}),
              payload: <String, Object?>{'oversized': 'x' * 4096},
            ),
            events: const <EventEnvelope>[],
          ),
        );

    expect(result.conflicts.single.code, 'ERR_RECOVERY_SNAPSHOT_TOO_LARGE');
    expect(result.conflicts.single.expected, '256');
  });

  test('rejects a tampered snapshot payload hash before recovery planning', () {
    final result = detector.detect(
      RecoveryRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        mode: RecoveryMode.reconnect,
        snapshot: SnapshotEnvelope(
          snapshotId: 'snap_1',
          protocolVersion: '1.0.0',
          tableId: 'table_1',
          sessionId: 'session_1',
          snapshotBaseEventSeq: 0,
          snapshotHash: 'tampered_hash',
          payload: const <String, Object?>{'phase': 'LIVE_ACTIVE'},
        ),
        events: const <EventEnvelope>[],
      ),
    );

    expect(result.conflicts.single.code, 'ERR_SNAPSHOT_PAYLOAD_HASH_MISMATCH');
    expect(result.conflicts.single.isFatal, isTrue);
  });

  test(
    'flags fatal mismatch when final event hash differs from expected baseline',
    () {
      final result = detector.detect(
        RecoveryRequest(
          tableId: 'table_1',
          sessionId: 'session_1',
          protocolVersion: '1.0.0',
          mode: RecoveryMode.primaryPeerTransfer,
          expectedFinalEventHash: 'expected_hash',
          events: <EventEnvelope>[
            EventEnvelope(
              eventId: 'evt_1',
              eventType: 'OpenTableSessionOpened',
              eventVersion: '1.0',
              protocolVersion: '1.0.0',
              eventSeq: 1,
              tableId: 'table_1',
              sessionId: 'session_1',
              handId: null,
              emittedAt: '2026-04-25T00:00:00Z',
              actorRef: 'host_1',
              payload: <String, Object?>{},
              prevEventHash: genesisEventHash,
              eventHash: 'actual_hash',
            ),
          ],
        ),
      );

      expect(result.hasFatalConflicts, isTrue);
      expect(result.conflicts.first.code, 'ERR_FINAL_EVENT_HASH_MISMATCH');
    },
  );

  test('flags fatal unsupported recovery protocol', () {
    final result = detector.detect(
      RecoveryRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '2.0.0',
        mode: RecoveryMode.reconnect,
        events: <EventEnvelope>[],
      ),
    );

    expect(result.hasFatalConflicts, isTrue);
    expect(result.conflicts.single.code, 'ERR_RECOVERY_PROTOCOL_INCOMPATIBLE');
    expect(result.conflicts.single.toProtocolDiagnostic().toJson(), {
      'code': 'ERR_RECOVERY_PROTOCOL_INCOMPATIBLE',
      'message': 'Recovery request protocol version is not supported.',
      'expected': '1.0.0',
      'actual': '2.0.0',
    });
    expect(result.diagnostics.single.toJson(), {
      'code': 'ERR_RECOVERY_PROTOCOL_INCOMPATIBLE',
      'message': 'Recovery request protocol version is not supported.',
      'expected': '1.0.0',
      'actual': '2.0.0',
    });
  });

  test('flags fatal event protocol mismatch', () {
    final result = detector.detect(
      RecoveryRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        mode: RecoveryMode.reconnect,
        events: <EventEnvelope>[
          EventEnvelope(
            eventId: 'evt_1',
            eventType: 'OpenTableSessionOpened',
            eventVersion: '1.0',
            protocolVersion: '2.0.0',
            eventSeq: 1,
            tableId: 'table_1',
            sessionId: 'session_1',
            handId: null,
            emittedAt: '2026-04-25T00:00:00Z',
            actorRef: 'host_1',
            payload: <String, Object?>{},
            prevEventHash: genesisEventHash,
            eventHash: 'hash_1',
          ),
        ],
      ),
    );

    expect(result.hasFatalConflicts, isTrue);
    expect(result.conflicts.single.code, 'ERR_EVENT_PROTOCOL_INCOMPATIBLE');
  });

  test('flags fatal unsupported event artifact', () {
    final result = detector.detect(
      RecoveryRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        mode: RecoveryMode.reconnect,
        events: <EventEnvelope>[
          EventEnvelope(
            eventId: 'evt_1',
            eventType: 'UnknownEvent',
            eventVersion: '1.0',
            protocolVersion: '1.0.0',
            eventSeq: 1,
            tableId: 'table_1',
            sessionId: 'session_1',
            handId: null,
            emittedAt: '2026-04-25T00:00:00Z',
            actorRef: 'host_1',
            payload: <String, Object?>{},
            prevEventHash: genesisEventHash,
            eventHash: 'hash_1',
          ),
        ],
      ),
    );

    expect(result.hasFatalConflicts, isTrue);
    expect(result.conflicts.single.code, 'ERR_EVENT_SCHEMA_UNSUPPORTED');
  });

  test('flags fatal unsupported snapshot artifact', () {
    final result = detector.detect(
      RecoveryRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        mode: RecoveryMode.reconnect,
        snapshot: SnapshotEnvelope(
          snapshotId: 'snap_1',
          snapshotType: 'UnknownSnapshot',
          snapshotVersion: '1.0',
          protocolVersion: '1.0.0',
          tableId: 'table_1',
          sessionId: 'session_1',
          snapshotBaseEventSeq: 1,
          snapshotHash: 'snap_hash',
          payload: <String, Object?>{},
        ),
        events: <EventEnvelope>[],
      ),
    );

    expect(result.hasFatalConflicts, isTrue);
    expect(result.conflicts.single.code, 'ERR_SNAPSHOT_SCHEMA_UNSUPPORTED');
  });

  test('flags fatal snapshot suffix gap', () {
    final result = detector.detect(
      RecoveryRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        mode: RecoveryMode.reconnect,
        snapshot: SnapshotEnvelope(
          snapshotId: 'snap_1',
          protocolVersion: '1.0.0',
          tableId: 'table_1',
          sessionId: 'session_1',
          snapshotBaseEventSeq: 2,
          snapshotHash: computeCanonicalHash(const <String, Object?>{}),
          payload: <String, Object?>{},
        ),
        events: <EventEnvelope>[
          EventEnvelope(
            eventId: 'evt_4',
            eventType: 'RecoveryPauseEnded',
            eventVersion: '1.0',
            protocolVersion: '1.0.0',
            eventSeq: 4,
            tableId: 'table_1',
            sessionId: 'session_1',
            handId: null,
            emittedAt: '2026-04-25T00:00:05Z',
            actorRef: 'system',
            payload: <String, Object?>{},
            prevEventHash: 'hash_3',
            eventHash: 'hash_4',
          ),
        ],
      ),
    );

    expect(result.hasFatalConflicts, isTrue);
    expect(result.conflicts.single.code, 'ERR_SNAPSHOT_SUFFIX_GAP');
    expect(result.conflicts.single.expected, '3');
    expect(result.conflicts.single.actual, '4');
  });

  test('flags fatal event hash chain break', () {
    final result = detector.detect(
      RecoveryRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        mode: RecoveryMode.reconnect,
        events: <EventEnvelope>[
          EventEnvelope(
            eventId: 'evt_1',
            eventType: 'OpenTableSessionOpened',
            eventVersion: '1.0',
            protocolVersion: '1.0.0',
            eventSeq: 1,
            tableId: 'table_1',
            sessionId: 'session_1',
            handId: null,
            emittedAt: '2026-04-25T00:00:00Z',
            actorRef: 'host_1',
            payload: <String, Object?>{},
            prevEventHash: genesisEventHash,
            eventHash: 'hash_1',
          ),
          EventEnvelope(
            eventId: 'evt_2',
            eventType: 'HandStarted',
            eventVersion: '1.0',
            protocolVersion: '1.0.0',
            eventSeq: 2,
            tableId: 'table_1',
            sessionId: 'session_1',
            handId: 'hand_1',
            emittedAt: '2026-04-25T00:00:05Z',
            actorRef: 'system',
            payload: <String, Object?>{},
            prevEventHash: 'hash_unrelated',
            eventHash: 'hash_2',
          ),
        ],
      ),
    );

    expect(result.hasFatalConflicts, isTrue);
    expect(result.conflicts.single.code, 'ERR_EVENT_HASH_CHAIN_BREAK');
    expect(result.conflicts.single.expected, 'hash_1');
    expect(result.conflicts.single.actual, 'hash_unrelated');
  });

  test('flags fatal event sequence gap', () {
    final result = detector.detect(
      RecoveryRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        mode: RecoveryMode.reconnect,
        events: <EventEnvelope>[
          EventEnvelope(
            eventId: 'evt_1',
            eventType: 'OpenTableSessionOpened',
            eventVersion: '1.0',
            protocolVersion: '1.0.0',
            eventSeq: 1,
            tableId: 'table_1',
            sessionId: 'session_1',
            handId: null,
            emittedAt: '2026-04-25T00:00:00Z',
            actorRef: 'host_1',
            payload: <String, Object?>{},
            prevEventHash: genesisEventHash,
            eventHash: 'hash_1',
          ),
          EventEnvelope(
            eventId: 'evt_3',
            eventType: 'HandStarted',
            eventVersion: '1.0',
            protocolVersion: '1.0.0',
            eventSeq: 3,
            tableId: 'table_1',
            sessionId: 'session_1',
            handId: 'hand_1',
            emittedAt: '2026-04-25T00:00:05Z',
            actorRef: 'system',
            payload: <String, Object?>{},
            prevEventHash: 'hash_1',
            eventHash: 'hash_3',
          ),
        ],
      ),
    );

    expect(result.hasFatalConflicts, isTrue);
    expect(result.conflicts.single.code, 'ERR_EVENT_SEQUENCE_GAP');
    expect(result.conflicts.single.expected, '2');
    expect(result.conflicts.single.actual, '3');
  });

  test('flags fatal event scope mismatch', () {
    final result = detector.detect(
      RecoveryRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        mode: RecoveryMode.reconnect,
        events: <EventEnvelope>[
          EventEnvelope(
            eventId: 'evt_1',
            eventType: 'OpenTableSessionOpened',
            eventVersion: '1.0',
            protocolVersion: '1.0.0',
            eventSeq: 1,
            tableId: 'other_table',
            sessionId: 'session_1',
            handId: null,
            emittedAt: '2026-04-25T00:00:00Z',
            actorRef: 'host_1',
            payload: <String, Object?>{},
            prevEventHash: genesisEventHash,
            eventHash: 'hash_1',
          ),
        ],
      ),
    );

    expect(result.hasFatalConflicts, isTrue);
    expect(result.conflicts.single.code, 'ERR_EVENT_SCOPE_MISMATCH');
    expect(result.conflicts.single.expected, 'table_1/session_1');
    expect(result.conflicts.single.actual, 'other_table/session_1');
  });

  test('flags fatal empty recovery window', () {
    final result = detector.detect(
      RecoveryRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        mode: RecoveryMode.reconnect,
        events: <EventEnvelope>[],
      ),
    );

    expect(result.hasFatalConflicts, isTrue);
    expect(result.conflicts.single.code, 'ERR_EMPTY_RECOVERY_WINDOW');
  });

  test('flags fatal suffix window without snapshot prefix', () {
    final result = detector.detect(
      RecoveryRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        mode: RecoveryMode.reconnect,
        events: <EventEnvelope>[
          _event(3, prevEventHash: 'hash_2', eventHash: 'hash_3'),
        ],
      ),
    );

    expect(result.hasFatalConflicts, isTrue);
    expect(
      result.conflicts.map((conflict) => conflict.code),
      contains('ERR_EVENT_WINDOW_MISSING_PREFIX'),
    );
  });

  test('flags fatal full recovery window with non-genesis first hash', () {
    final result = detector.detect(
      RecoveryRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        mode: RecoveryMode.reconnect,
        events: <EventEnvelope>[
          _event(1, prevEventHash: 'root', eventHash: 'hash_1'),
        ],
      ),
    );

    expect(result.hasFatalConflicts, isTrue);
    expect(
      result.conflicts.single.code,
      'ERR_EVENT_WINDOW_GENESIS_HASH_MISMATCH',
    );
    expect(result.conflicts.single.expected, genesisEventHash);
    expect(result.conflicts.single.actual, 'root');
  });

  test('rejects a tampered event content hash by default', () {
    final unsigned = _event(1, prevEventHash: genesisEventHash, eventHash: '');
    final valid = _event(
      1,
      prevEventHash: genesisEventHash,
      eventHash: computeCanonicalEventHash(unsigned),
    );
    final tampered = EventEnvelope(
      eventId: valid.eventId,
      eventType: valid.eventType,
      eventVersion: valid.eventVersion,
      protocolVersion: valid.protocolVersion,
      eventSeq: valid.eventSeq,
      tableId: valid.tableId,
      sessionId: valid.sessionId,
      handId: valid.handId,
      emittedAt: valid.emittedAt,
      actorRef: valid.actorRef,
      payload: const <String, Object?>{'tampered': true},
      prevEventHash: valid.prevEventHash,
      eventHash: valid.eventHash,
    );
    final result = BasicConflictDetector().detect(
      RecoveryRequest(
        tableId: tampered.tableId,
        sessionId: tampered.sessionId,
        protocolVersion: tampered.protocolVersion,
        mode: RecoveryMode.reconnect,
        events: <EventEnvelope>[tampered],
      ),
    );

    expect(result.conflicts.single.code, 'ERR_RECOVERY_EVENT_HASH_INVALID');
  });
}

EventEnvelope _event(
  int eventSeq, {
  required String prevEventHash,
  required String eventHash,
  Map<String, Object?> payload = const <String, Object?>{},
}) {
  return EventEnvelope(
    eventId: 'evt_$eventSeq',
    eventType: eventSeq == 1 ? 'OpenTableSessionOpened' : 'RecoveryPauseEnded',
    eventVersion: '1.0',
    protocolVersion: '1.0.0',
    eventSeq: eventSeq,
    tableId: 'table_1',
    sessionId: 'session_1',
    handId: null,
    emittedAt: '2026-04-25T00:00:00Z',
    actorRef: 'system',
    payload: payload,
    prevEventHash: prevEventHash,
    eventHash: eventHash,
  );
}
