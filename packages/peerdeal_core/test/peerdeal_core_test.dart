import 'dart:convert';
import 'dart:io';

import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:test/test.dart';

Map<String, Object?> loadProtocolFixture(String path) {
  return jsonDecode(
        File('../peerdeal_protocol/fixtures/$path').readAsStringSync(),
      )
      as Map<String, Object?>;
}

CommandEnvelope commandEnvelopeFromJson(Map<String, Object?> json) {
  return CommandEnvelope(
    commandId: json['command_id'] as String,
    commandType: json['command_type'] as String,
    commandVersion: json['command_version'] as String,
    protocolVersion: json['protocol_version'] as String,
    tableId: json['table_id'] as String?,
    sessionId: json['session_id'] as String?,
    handId: json['hand_id'] as String?,
    issuedAt: json['issued_at'] as String,
    actorRef: json['actor_ref'] as String,
    payload: Map<String, Object?>.from(json['payload'] as Map),
  );
}

EventEnvelope eventEnvelopeFromJson(Map<String, Object?> json) {
  return EventEnvelope(
    eventId: json['event_id'] as String,
    eventType: json['event_type'] as String,
    eventVersion: json['event_version'] as String,
    protocolVersion: json['protocol_version'] as String,
    eventSeq: json['event_seq'] as int,
    tableId: json['table_id'] as String,
    sessionId: json['session_id'] as String,
    handId: json['hand_id'] as String?,
    emittedAt: json['emitted_at'] as String,
    actorRef: json['actor_ref'] as String,
    payload: Map<String, Object?>.from(json['payload'] as Map),
    prevEventHash: json['prev_event_hash'] as String,
    eventHash: json['event_hash'] as String,
  );
}

TableState projectOrderedEvents(Iterable<EventEnvelope> events) {
  final reducer = CoreReducer();
  var state = TableState.initial();
  for (final event in events) {
    state = reducer.apply(state, event);
  }
  return state;
}

TableState projectOrderedEventsFrom({
  required TableState initial,
  required Iterable<EventEnvelope> events,
}) {
  final reducer = CoreReducer();
  var state = initial;
  for (final event in events) {
    state = reducer.apply(state, event);
  }
  return state;
}

EventEnvelope protocolEvent({
  required String eventId,
  required String eventType,
  required int eventSeq,
  String tableId = 'tbl_001',
  String sessionId = 'sess_001',
  String? handId,
  String actorRef = 'system',
  Map<String, Object?> payload = const <String, Object?>{},
  String? prevEventHash,
  String? eventHash,
}) {
  return EventEnvelope(
    eventId: eventId,
    eventType: eventType,
    eventVersion: '1.0',
    protocolVersion: currentProtocolVersion.toWire(),
    eventSeq: eventSeq,
    tableId: tableId,
    sessionId: sessionId,
    handId: handId,
    emittedAt: '2026-04-25T12:05:${eventSeq.toString().padLeft(2, '0')}Z',
    actorRef: actorRef,
    payload: payload,
    prevEventHash:
        prevEventHash ?? (eventSeq == 1 ? 'GENESIS' : 'hash_${eventSeq - 1}'),
    eventHash: eventHash ?? 'hash_$eventSeq',
  );
}

EventEnvelope copyEvent(
  EventEnvelope event, {
  String? eventId,
  int? eventSeq,
  String? tableId,
  String? sessionId,
  String? prevEventHash,
  String? eventHash,
}) {
  return EventEnvelope(
    eventId: eventId ?? event.eventId,
    eventType: event.eventType,
    eventVersion: event.eventVersion,
    protocolVersion: event.protocolVersion,
    eventSeq: eventSeq ?? event.eventSeq,
    tableId: tableId ?? event.tableId,
    sessionId: sessionId ?? event.sessionId,
    handId: event.handId,
    emittedAt: event.emittedAt,
    actorRef: event.actorRef,
    payload: event.payload,
    prevEventHash: prevEventHash ?? event.prevEventHash,
    eventHash: eventHash ?? event.eventHash,
  );
}

void main() {
  test('validator rejects open session command without table id', () {
    const command = CommandEnvelope(
      commandId: 'cmd_001',
      commandType: 'OpenTableSession',
      commandVersion: '1.0',
      protocolVersion: '1.0.0',
      tableId: null,
      sessionId: null,
      handId: null,
      issuedAt: '2026-04-25T12:05:00Z',
      actorRef: 'host_alpha',
      payload: {'config_id': 'cfg_open_table_001'},
    );

    final errors = CoreCommandValidator().validate(command);
    expect(errors, contains('OpenTableSession requires table_id'));
  });

  test('core accepts fixture-backed protocol open session spine', () {
    final command = commandEnvelopeFromJson(
      loadProtocolFixture('commands/open_table_session_command_v1.json'),
    );
    final event = eventEnvelopeFromJson(
      loadProtocolFixture('events/open_table_session_opened_event_v1.json'),
    );

    final errors = CoreCommandValidator().validate(command);
    final state = const CoreReducer().apply(TableState.initial(), event);

    expect(errors, isEmpty);
    expect(state.tableId, event.tableId);
    expect(state.sessionId, event.sessionId);
    expect(state.protocolVersion, event.protocolVersion);
    expect(state.phase, TablePhase.openReady);
    expect(state.eventSeq, event.eventSeq);
    expect(state.metadata['mode_type'], 'open_table');
    expect(state.metadata['last_event_hash'], event.eventHash);
  });

  test(
    'core projection is deterministic for fixture-backed protocol event',
    () {
      final event = eventEnvelopeFromJson(
        loadProtocolFixture('events/open_table_session_opened_event_v1.json'),
      );
      final reducer = const CoreReducer();

      final firstProjection = reducer.apply(TableState.initial(), event);
      final secondProjection = reducer.apply(TableState.initial(), event);

      expect(firstProjection.toJson(), secondProjection.toJson());
    },
  );

  test('core reconstructs state from ordered protocol-backed events', () {
    final opened = eventEnvelopeFromJson(
      loadProtocolFixture('events/open_table_session_opened_event_v1.json'),
    );
    final admitted = EventEnvelope(
      eventId: 'evt_fixture_participant_admitted',
      eventType: 'ParticipantAdmitted',
      eventVersion: '1.0',
      protocolVersion: opened.protocolVersion,
      eventSeq: opened.eventSeq + 1,
      tableId: opened.tableId,
      sessionId: opened.sessionId,
      handId: null,
      emittedAt: '2026-04-25T12:05:02Z',
      actorRef: 'system',
      payload: const {'participant_id': 'player_001'},
      prevEventHash: opened.eventHash,
      eventHash: 'hash_fixture_participant_admitted',
    );

    final reconstructed = projectOrderedEvents([opened, admitted]);
    final stepped = const CoreReducer().apply(
      const CoreReducer().apply(TableState.initial(), opened),
      admitted,
    );

    expect(reconstructed.toJson(), stepped.toJson());
    expect(reconstructed.tableId, opened.tableId);
    expect(reconstructed.sessionId, opened.sessionId);
    expect(reconstructed.protocolVersion, opened.protocolVersion);
    expect(reconstructed.eventSeq, admitted.eventSeq);
    expect(reconstructed.participantCount, 1);
  });

  test('core projects cataloged open-to-close protocol lifecycle events', () {
    final events = <EventEnvelope>[
      protocolEvent(
        eventId: 'evt_001',
        eventType: 'OpenTableSessionOpened',
        eventSeq: 1,
        payload: const {'mode_type': 'open_table'},
      ),
      protocolEvent(
        eventId: 'evt_002',
        eventType: 'ParticipantConnected',
        eventSeq: 2,
      ),
      protocolEvent(
        eventId: 'evt_003',
        eventType: 'ParticipantConnected',
        eventSeq: 3,
      ),
      protocolEvent(
        eventId: 'evt_004',
        eventType: 'ParticipantSeated',
        eventSeq: 4,
      ),
      protocolEvent(
        eventId: 'evt_005',
        eventType: 'ParticipantSeated',
        eventSeq: 5,
      ),
      protocolEvent(
        eventId: 'evt_006',
        eventType: 'HandStarted',
        eventSeq: 6,
        handId: 'hand_001',
        payload: const {'hand_id': 'hand_001'},
      ),
      protocolEvent(
        eventId: 'evt_007',
        eventType: 'PlayerCalled',
        eventSeq: 7,
        handId: 'hand_001',
        actorRef: 'player_001',
      ),
      protocolEvent(
        eventId: 'evt_008',
        eventType: 'ShowdownStarted',
        eventSeq: 8,
        handId: 'hand_001',
      ),
      protocolEvent(
        eventId: 'evt_009',
        eventType: 'SettlementProjected',
        eventSeq: 9,
        handId: 'hand_001',
      ),
      protocolEvent(
        eventId: 'evt_010',
        eventType: 'HandSettled',
        eventSeq: 10,
        handId: 'hand_001',
      ),
      protocolEvent(
        eventId: 'evt_011',
        eventType: 'SessionCloseRequested',
        eventSeq: 11,
      ),
      protocolEvent(
        eventId: 'evt_012',
        eventType: 'SessionClosed',
        eventSeq: 12,
      ),
    ];

    final state = projectOrderedEvents(events);

    expect(state.phase, TablePhase.closed);
    expect(state.playersConnected, 0);
    expect(state.playersSeated, 0);
    expect(state.activeHandId, isNull);
    expect(state.closeRequested, isTrue);
    expect(state.eventSeq, 12);
    expect(state.metadata['last_event_hash'], 'hash_12');
  });

  test('core projects fixture-backed Holdem showdown settlement lifecycle', () {
    final events = <EventEnvelope>[
      eventEnvelopeFromJson(
        loadProtocolFixture('events/holdem_hand_started_event_v1.json'),
      ),
      eventEnvelopeFromJson(
        loadProtocolFixture('events/holdem_showdown_started_event_v1.json'),
      ),
      eventEnvelopeFromJson(
        loadProtocolFixture('events/holdem_showdown_revealed_event_v1.json'),
      ),
      eventEnvelopeFromJson(
        loadProtocolFixture('events/holdem_settlement_projected_event_v1.json'),
      ),
      eventEnvelopeFromJson(
        loadProtocolFixture('events/holdem_hand_settled_event_v1.json'),
      ),
    ];
    final first = events.first;

    final state = projectOrderedEventsFrom(
      initial: TableState.initial(
        tableId: first.tableId,
        sessionId: first.sessionId,
        protocolVersion: first.protocolVersion,
      ),
      events: events,
    );

    expect(state.phase, TablePhase.liveActive);
    expect(state.activeHandId, isNull);
    expect(state.eventSeq, 5);
    expect(state.metadata['last_event_hash'], 'hash_holdem_005');
    expect(state.metadata['last_settlement_status'], 'settled');
    expect(state.metadata['last_settlement_event_type'], 'HandSettled');
    expect(state.metadata['last_settlement_hand_id'], 'hand_holdem_001');
    expect(
      state.metadata['last_settlement_projection_id'],
      'settlement_projection_holdem_001',
    );
    expect(state.metadata['last_settlement_id'], 'settlement_holdem_001');
    expect(state.metadata['last_settlement_variant_id'], 'holdem_nlhe');
  });

  test(
    'core accepts fixture-backed Holdem uncontested settlement projection',
    () {
      final started = eventEnvelopeFromJson(
        loadProtocolFixture('events/holdem_hand_started_event_v1.json'),
      );
      final projected = eventEnvelopeFromJson(
        loadProtocolFixture(
          'events/holdem_uncontested_settlement_projected_event_v1.json',
        ),
      );
      final adjustedProjection = EventEnvelope(
        eventId: projected.eventId,
        eventType: projected.eventType,
        eventVersion: projected.eventVersion,
        protocolVersion: projected.protocolVersion,
        eventSeq: started.eventSeq + 1,
        tableId: projected.tableId,
        sessionId: projected.sessionId,
        handId: projected.handId,
        emittedAt: projected.emittedAt,
        actorRef: projected.actorRef,
        payload: projected.payload,
        prevEventHash: started.eventHash,
        eventHash: projected.eventHash,
      );

      final state = projectOrderedEventsFrom(
        initial: TableState.initial(
          tableId: started.tableId,
          sessionId: started.sessionId,
          protocolVersion: started.protocolVersion,
        ),
        events: <EventEnvelope>[started, adjustedProjection],
      );

      expect(state.phase, TablePhase.liveActive);
      expect(state.activeHandId, started.handId);
      expect(state.eventSeq, 2);
      expect(state.metadata['last_event_hash'], adjustedProjection.eventHash);
      expect(state.metadata['last_settlement_status'], 'projected');
      expect(
        state.metadata['last_settlement_event_type'],
        'SettlementProjected',
      );
      expect(
        state.metadata['last_settlement_projection_id'],
        'settlement_projection_holdem_uncontested_001',
      );
      expect(state.metadata['last_settlement_hand_id'], started.handId);
    },
  );

  test('core accepts fixture-backed Holdem blocked settlement event', () {
    final started = eventEnvelopeFromJson(
      loadProtocolFixture('events/holdem_hand_started_event_v1.json'),
    );
    final blocked = eventEnvelopeFromJson(
      loadProtocolFixture('events/holdem_settlement_blocked_event_v1.json'),
    );
    final adjustedBlocked = EventEnvelope(
      eventId: blocked.eventId,
      eventType: blocked.eventType,
      eventVersion: blocked.eventVersion,
      protocolVersion: blocked.protocolVersion,
      eventSeq: started.eventSeq + 1,
      tableId: blocked.tableId,
      sessionId: blocked.sessionId,
      handId: blocked.handId,
      emittedAt: blocked.emittedAt,
      actorRef: blocked.actorRef,
      payload: blocked.payload,
      prevEventHash: started.eventHash,
      eventHash: blocked.eventHash,
    );

    final state = projectOrderedEventsFrom(
      initial: TableState.initial(
        tableId: started.tableId,
        sessionId: started.sessionId,
        protocolVersion: started.protocolVersion,
      ),
      events: <EventEnvelope>[started, adjustedBlocked],
    );

    expect(state.phase, TablePhase.liveActive);
    expect(state.activeHandId, started.handId);
    expect(state.eventSeq, 2);
    expect(state.metadata['last_event_hash'], adjustedBlocked.eventHash);
    expect(state.metadata['last_settlement_status'], 'blocked');
    expect(state.metadata['last_settlement_event_type'], 'SettlementBlocked');
    expect(
      state.metadata['last_settlement_projection_id'],
      'settlement_projection_holdem_blocked_001',
    );
    expect(state.metadata['last_settlement_reason_codes'], <Object?>[
      'ERR_HOLDEM_SETTLEMENT_PROJECT_UNAWARDABLE',
    ]);
    expect(state.metadata['last_settlement_warnings'], <Object?>[
      'ERR_HOLDEM_SETTLEMENT_PROJECT_UNAWARDABLE',
    ]);
    expect(state.metadata['last_settlement_hand_id'], started.handId);
  });

  test('core rejects fixture-backed Holdem lifecycle with a sequence gap', () {
    final events = <EventEnvelope>[
      eventEnvelopeFromJson(
        loadProtocolFixture('events/holdem_hand_started_event_v1.json'),
      ),
      eventEnvelopeFromJson(
        loadProtocolFixture('events/holdem_showdown_started_event_v1.json'),
      ),
      eventEnvelopeFromJson(
        loadProtocolFixture('events/holdem_settlement_projected_event_v1.json'),
      ),
    ];

    expect(
      () => projectOrderedEventsFrom(
        initial: TableState.initial(
          tableId: events.first.tableId,
          sessionId: events.first.sessionId,
          protocolVersion: events.first.protocolVersion,
        ),
        events: events,
      ),
      throwsA(
        isA<InvariantViolation>().having(
          (violation) => violation.code,
          'code',
          'ERR_EVENT_SEQUENCE_GAP',
        ),
      ),
    );
  });

  test('core rejects fixture-backed Holdem lifecycle with a broken hash', () {
    final started = eventEnvelopeFromJson(
      loadProtocolFixture('events/holdem_hand_started_event_v1.json'),
    );
    final showdownStarted = eventEnvelopeFromJson(
      loadProtocolFixture('events/holdem_showdown_started_event_v1.json'),
    );
    final showdownRevealed = eventEnvelopeFromJson(
      loadProtocolFixture('events/holdem_showdown_revealed_event_v1.json'),
    );
    final projected = eventEnvelopeFromJson(
      loadProtocolFixture('events/holdem_settlement_projected_event_v1.json'),
    );

    expect(
      () => projectOrderedEventsFrom(
        initial: TableState.initial(
          tableId: started.tableId,
          sessionId: started.sessionId,
          protocolVersion: started.protocolVersion,
        ),
        events: <EventEnvelope>[
          started,
          showdownStarted,
          showdownRevealed,
          copyEvent(projected, prevEventHash: 'hash_holdem_diverged'),
        ],
      ),
      throwsA(
        isA<InvariantViolation>().having(
          (violation) => violation.code,
          'code',
          'ERR_EVENT_HASH_CHAIN_BREAK',
        ),
      ),
    );
  });

  test('core rejects fixture-backed Holdem lifecycle that switches table', () {
    final started = eventEnvelopeFromJson(
      loadProtocolFixture('events/holdem_hand_started_event_v1.json'),
    );
    final showdownStarted = eventEnvelopeFromJson(
      loadProtocolFixture('events/holdem_showdown_started_event_v1.json'),
    );

    expect(
      () => projectOrderedEventsFrom(
        initial: TableState.initial(
          tableId: started.tableId,
          sessionId: started.sessionId,
          protocolVersion: started.protocolVersion,
        ),
        events: <EventEnvelope>[
          started,
          copyEvent(showdownStarted, tableId: 'tbl_holdem_diverged'),
        ],
      ),
      throwsA(
        isA<InvariantViolation>().having(
          (violation) => violation.code,
          'code',
          'ERR_EVENT_STREAM_IDENTITY_MISMATCH',
        ),
      ),
    );
  });

  test(
    'core rejects unsupported protocol event artifacts before projection',
    () {
      final event = protocolEvent(
        eventId: 'evt_unknown',
        eventType: 'UnknownEvent',
        eventSeq: 1,
      );

      expect(
        () => const CoreReducer().apply(TableState.initial(), event),
        throwsA(
          isA<InvariantViolation>().having(
            (violation) => violation.code,
            'code',
            ProtocolResultCodes.errEventSchemaUnsupported,
          ),
        ),
      );
    },
  );

  test('core rejects seated protocol state that exceeds connected count', () {
    final opened = protocolEvent(
      eventId: 'evt_001',
      eventType: 'OpenTableSessionOpened',
      eventSeq: 1,
    );
    final seatedWithoutConnected = protocolEvent(
      eventId: 'evt_002',
      eventType: 'ParticipantSeated',
      eventSeq: 2,
    );

    expect(
      () => projectOrderedEvents([opened, seatedWithoutConnected]),
      throwsA(
        isA<InvariantViolation>().having(
          (violation) => violation.code,
          'code',
          'ERR_SEATED_EXCEEDS_CONNECTED',
        ),
      ),
    );
  });

  test('core rejects replaying fixture-backed protocol event out of order', () {
    final event = eventEnvelopeFromJson(
      loadProtocolFixture('events/open_table_session_opened_event_v1.json'),
    );
    final reducer = const CoreReducer();
    final projected = reducer.apply(TableState.initial(), event);

    expect(
      () => reducer.apply(projected, event),
      throwsA(
        isA<InvariantViolation>().having(
          (violation) => violation.code,
          'code',
          'ERR_EVENT_SEQUENCE_NOT_MONOTONIC',
        ),
      ),
    );
  });

  test('core rejects fixture-backed protocol event windows with gaps', () {
    final opened = eventEnvelopeFromJson(
      loadProtocolFixture('events/open_table_session_opened_event_v1.json'),
    );
    final gapEvent = EventEnvelope(
      eventId: 'evt_fixture_gap_participant_admitted',
      eventType: 'ParticipantAdmitted',
      eventVersion: '1.0',
      protocolVersion: opened.protocolVersion,
      eventSeq: opened.eventSeq + 2,
      tableId: opened.tableId,
      sessionId: opened.sessionId,
      handId: null,
      emittedAt: '2026-04-25T12:05:03Z',
      actorRef: 'system',
      payload: const {'participant_id': 'player_001'},
      prevEventHash: opened.eventHash,
      eventHash: 'hash_fixture_gap_participant_admitted',
    );

    expect(
      () => projectOrderedEvents([opened, gapEvent]),
      throwsA(
        isA<InvariantViolation>().having(
          (violation) => violation.code,
          'code',
          'ERR_EVENT_SEQUENCE_GAP',
        ),
      ),
    );
  });

  test('core rejects protocol event windows with broken hash chains', () {
    final opened = eventEnvelopeFromJson(
      loadProtocolFixture('events/open_table_session_opened_event_v1.json'),
    );
    final broken = EventEnvelope(
      eventId: 'evt_fixture_broken_hash_participant_admitted',
      eventType: 'ParticipantAdmitted',
      eventVersion: '1.0',
      protocolVersion: opened.protocolVersion,
      eventSeq: opened.eventSeq + 1,
      tableId: opened.tableId,
      sessionId: opened.sessionId,
      handId: null,
      emittedAt: '2026-04-25T12:05:02Z',
      actorRef: 'system',
      payload: const {'participant_id': 'player_001'},
      prevEventHash: 'hash_unrelated',
      eventHash: 'hash_fixture_broken_hash_participant_admitted',
    );

    expect(
      () => projectOrderedEvents([opened, broken]),
      throwsA(
        isA<InvariantViolation>().having(
          (violation) => violation.code,
          'code',
          'ERR_EVENT_HASH_CHAIN_BREAK',
        ),
      ),
    );
  });

  test('core rejects protocol event windows that switch table identity', () {
    final opened = eventEnvelopeFromJson(
      loadProtocolFixture('events/open_table_session_opened_event_v1.json'),
    );
    final mismatched = EventEnvelope(
      eventId: 'evt_fixture_wrong_table_participant_admitted',
      eventType: 'ParticipantAdmitted',
      eventVersion: '1.0',
      protocolVersion: opened.protocolVersion,
      eventSeq: opened.eventSeq + 1,
      tableId: 'tbl_other',
      sessionId: opened.sessionId,
      handId: null,
      emittedAt: '2026-04-25T12:05:02Z',
      actorRef: 'system',
      payload: const {'participant_id': 'player_001'},
      prevEventHash: opened.eventHash,
      eventHash: 'hash_fixture_wrong_table_participant_admitted',
    );

    expect(
      () => projectOrderedEvents([opened, mismatched]),
      throwsA(
        isA<InvariantViolation>().having(
          (violation) => violation.code,
          'code',
          'ERR_EVENT_STREAM_IDENTITY_MISMATCH',
        ),
      ),
    );
  });

  test('core rejects protocol event windows that switch session identity', () {
    final opened = eventEnvelopeFromJson(
      loadProtocolFixture('events/open_table_session_opened_event_v1.json'),
    );
    final mismatched = EventEnvelope(
      eventId: 'evt_fixture_wrong_session_participant_admitted',
      eventType: 'ParticipantAdmitted',
      eventVersion: '1.0',
      protocolVersion: opened.protocolVersion,
      eventSeq: opened.eventSeq + 1,
      tableId: opened.tableId,
      sessionId: 'sess_other',
      handId: null,
      emittedAt: '2026-04-25T12:05:02Z',
      actorRef: 'system',
      payload: const {'participant_id': 'player_001'},
      prevEventHash: opened.eventHash,
      eventHash: 'hash_fixture_wrong_session_participant_admitted',
    );

    expect(
      () => projectOrderedEvents([opened, mismatched]),
      throwsA(
        isA<InvariantViolation>().having(
          (violation) => violation.code,
          'code',
          'ERR_EVENT_STREAM_IDENTITY_MISMATCH',
        ),
      ),
    );
  });

  test('core rejects protocol event windows that switch protocol version', () {
    final opened = eventEnvelopeFromJson(
      loadProtocolFixture('events/open_table_session_opened_event_v1.json'),
    );
    final mismatched = EventEnvelope(
      eventId: 'evt_fixture_wrong_protocol_participant_admitted',
      eventType: 'ParticipantAdmitted',
      eventVersion: '1.0',
      protocolVersion: '1.0.1',
      eventSeq: opened.eventSeq + 1,
      tableId: opened.tableId,
      sessionId: opened.sessionId,
      handId: null,
      emittedAt: '2026-04-25T12:05:02Z',
      actorRef: 'system',
      payload: const {'participant_id': 'player_001'},
      prevEventHash: opened.eventHash,
      eventHash: 'hash_fixture_wrong_protocol_participant_admitted',
    );

    expect(
      () => projectOrderedEvents([opened, mismatched]),
      throwsA(
        isA<InvariantViolation>().having(
          (violation) => violation.code,
          'code',
          ProtocolResultCodes.errEventProtocolIncompatible,
        ),
      ),
    );
  });

  test('reducer is deterministic for same ordered events', () {
    const event1 = EventEnvelope(
      eventId: 'evt_001',
      eventType: 'OpenTableSessionOpened',
      eventVersion: '1.0',
      protocolVersion: '1.0.0',
      eventSeq: 1,
      tableId: 'tbl_001',
      sessionId: 'sess_001',
      handId: null,
      emittedAt: '2026-04-25T12:05:01Z',
      actorRef: 'system',
      payload: {'config_id': 'cfg_open_table_001', 'mode_type': 'open_table'},
      prevEventHash: 'GENESIS',
      eventHash: 'hash_001',
    );

    const event2 = EventEnvelope(
      eventId: 'evt_002',
      eventType: 'ParticipantAdmitted',
      eventVersion: '1.0',
      protocolVersion: '1.0.0',
      eventSeq: 2,
      tableId: 'tbl_001',
      sessionId: 'sess_001',
      handId: null,
      emittedAt: '2026-04-25T12:05:02Z',
      actorRef: 'system',
      payload: {'participant_id': 'player_001'},
      prevEventHash: 'hash_001',
      eventHash: 'hash_002',
    );

    final reducer = CoreReducer();

    var a = TableState.initial();
    a = reducer.apply(a, event1);
    a = reducer.apply(a, event2);

    var b = TableState.initial();
    b = reducer.apply(b, event1);
    b = reducer.apply(b, event2);

    expect(a.tableId, equals(b.tableId));
    expect(a.sessionId, equals(b.sessionId));
    expect(a.participantCount, equals(b.participantCount));
    expect(a.eventSeq, equals(2));
  });
}
