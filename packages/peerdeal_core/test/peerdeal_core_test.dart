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
