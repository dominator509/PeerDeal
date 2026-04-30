import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:test/test.dart';

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
