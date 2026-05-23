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
    expect(state.eventSeq, event.eventSeq);
    expect(state.metadata['mode_type'], 'open_table');
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
