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
  String? eventType,
  String? eventVersion,
  String? protocolVersion,
  int? eventSeq,
  String? tableId,
  String? sessionId,
  String? emittedAt,
  String? actorRef,
  String? prevEventHash,
  String? eventHash,
}) {
  return EventEnvelope(
    eventId: eventId ?? event.eventId,
    eventType: eventType ?? event.eventType,
    eventVersion: eventVersion ?? event.eventVersion,
    protocolVersion: protocolVersion ?? event.protocolVersion,
    eventSeq: eventSeq ?? event.eventSeq,
    tableId: tableId ?? event.tableId,
    sessionId: sessionId ?? event.sessionId,
    handId: event.handId,
    emittedAt: emittedAt ?? event.emittedAt,
    actorRef: actorRef ?? event.actorRef,
    payload: event.payload,
    prevEventHash: prevEventHash ?? event.prevEventHash,
    eventHash: eventHash ?? event.eventHash,
  );
}

List<String> acceptedProtocolEventFixturePaths() {
  return Directory('../peerdeal_protocol/fixtures/events')
      .listSync()
      .whereType<File>()
      .map((file) => file.path.replaceAll(r'\', '/').split('/events/').last)
      .where((path) => !path.startsWith('unsupported_'))
      .toList()
    ..sort();
}

TableState projectAcceptedProtocolEventFixture(String fixturePath) {
  final event = eventEnvelopeFromJson(
    loadProtocolFixture('events/$fixturePath'),
  );
  final started = eventEnvelopeFromJson(
    loadProtocolFixture('events/holdem_hand_started_event_v1.json'),
  );
  final showdownStarted = eventEnvelopeFromJson(
    loadProtocolFixture('events/holdem_showdown_started_event_v1.json'),
  );
  final showdownRevealed = eventEnvelopeFromJson(
    loadProtocolFixture('events/holdem_showdown_revealed_event_v1.json'),
  );
  final settlementProjected = eventEnvelopeFromJson(
    loadProtocolFixture('events/holdem_settlement_projected_event_v1.json'),
  );

  final initial = event.eventType == 'OpenTableSessionOpened'
      ? TableState.initial()
      : TableState.initial(
          tableId: event.tableId,
          sessionId: event.sessionId,
          protocolVersion: event.protocolVersion,
        );

  switch (fixturePath) {
    case 'open_table_session_opened_event_v1.json':
      return projectOrderedEventsFrom(
        initial: initial,
        events: <EventEnvelope>[event],
      );
    case 'holdem_hand_started_event_v1.json':
      return projectOrderedEventsFrom(
        initial: initial,
        events: <EventEnvelope>[event],
      );
    case 'holdem_showdown_started_event_v1.json':
      return projectOrderedEventsFrom(
        initial: initial,
        events: <EventEnvelope>[started, event],
      );
    case 'holdem_showdown_revealed_event_v1.json':
      return projectOrderedEventsFrom(
        initial: initial,
        events: <EventEnvelope>[started, showdownStarted, event],
      );
    case 'holdem_settlement_projected_event_v1.json':
    case 'holdem_uncontested_settlement_projected_event_v1.json':
    case 'holdem_settlement_blocked_event_v1.json':
    case 'holdem_settlement_blocked_empty_pot_event_v1.json':
    case 'holdem_settlement_blocked_invalid_showdown_event_v1.json':
      return projectOrderedEventsFrom(
        initial: initial,
        events: <EventEnvelope>[
          started,
          showdownStarted,
          showdownRevealed,
          event,
        ],
      );
    case 'holdem_hand_settled_event_v1.json':
      return projectOrderedEventsFrom(
        initial: initial,
        events: <EventEnvelope>[
          started,
          showdownStarted,
          showdownRevealed,
          settlementProjected,
          event,
        ],
      );
    default:
      throw ArgumentError.value(
        fixturePath,
        'fixturePath',
        'Accepted protocol event fixture is not covered by core projection.',
      );
  }
}

void main() {
  test('validator rejects open session command without table id', () {
    final command = CommandEnvelope(
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

  test('validator rejects blank command envelope identity fields', () {
    final command = CommandEnvelope(
      commandId: ' ',
      commandType: 'OpenTableSession',
      commandVersion: ' ',
      protocolVersion: ' ',
      tableId: ' ',
      sessionId: null,
      handId: null,
      issuedAt: ' ',
      actorRef: ' ',
      payload: <String, Object?>{},
    );

    final errors = CoreCommandValidator().validate(command);

    expect(errors, <String>[
      'command_id is required',
      'command_version is required',
      'protocol_version is required',
      'issued_at is required',
      'actor_ref is required',
      'OpenTableSession requires table_id',
    ]);
  });

  test('validator rejects unsupported protocol command artifacts', () {
    final command = CommandEnvelope(
      commandId: 'cmd_unsupported',
      commandType: 'UnknownCommand',
      commandVersion: '1.0',
      protocolVersion: '1.0.0',
      tableId: 'table_001',
      sessionId: null,
      handId: null,
      issuedAt: '2026-04-25T12:05:00Z',
      actorRef: 'host_alpha',
      payload: <String, Object?>{},
    );

    expect(
      CoreCommandValidator().validate(command),
      contains('command artifact is unsupported'),
    );
  });

  test('validator rejects unsupported protocol versions', () {
    final command = CommandEnvelope(
      commandId: 'cmd_unsupported_protocol',
      commandType: 'OpenTableSession',
      commandVersion: '1.0',
      protocolVersion: '2.0.0',
      tableId: 'table_001',
      sessionId: null,
      handId: null,
      issuedAt: '2026-04-25T12:05:00Z',
      actorRef: 'host_alpha',
      payload: <String, Object?>{},
    );

    expect(
      CoreCommandValidator().validate(command),
      contains('protocol_version is unsupported'),
    );
  });

  test('validator rejects padded and control-character identities', () {
    final command = CommandEnvelope(
      commandId: ' cmd_padded',
      commandType: 'OpenTableSession\n',
      commandVersion: '1.0',
      protocolVersion: '1.0.0',
      tableId: 'table_001',
      sessionId: null,
      handId: null,
      issuedAt: '2026-04-25T12:05:00Z',
      actorRef: 'host_alpha',
      payload: <String, Object?>{},
    );

    final errors = CoreCommandValidator().validate(command);

    expect(errors, contains('command_id contains unsafe characters'));
    expect(errors, contains('command_type contains unsafe characters'));
    expect(errors, isNot(contains('command artifact is unsupported')));
  });

  test('validator rejects C1 control-bearing command and scope identities', () {
    final command = CommandEnvelope(
      commandId: 'cmd_001\u0085',
      commandType: 'OpenTableSession',
      commandVersion: '1.0',
      protocolVersion: '1.0.0',
      tableId: 'table_001\u009f',
      sessionId: null,
      handId: null,
      issuedAt: '2026-04-25T12:05:00Z',
      actorRef: 'host_alpha',
      payload: <String, Object?>{},
    );

    final errors = CoreCommandValidator().validate(command);

    expect(errors, contains('command_id contains unsafe characters'));
    expect(errors, contains('table_id contains unsafe characters'));
    expect(errors, isNot(contains('command artifact is unsupported')));
  });

  test('validator rejects non-round-tripping UTF-8 identities', () {
    final command = CommandEnvelope(
      commandId: String.fromCharCode(0xd800),
      commandType: 'OpenTableSession',
      commandVersion: '1.0',
      protocolVersion: '1.0.0',
      tableId: 'table_001',
      sessionId: null,
      handId: null,
      issuedAt: '2026-04-25T12:05:00Z',
      actorRef: 'system',
      payload: <String, Object?>{},
    );

    expect(
      CoreCommandValidator().validate(command),
      contains('command_id contains unsafe characters'),
    );
  });

  test(
    'validator rejects oversized command identities before compatibility',
    () {
      final oversizedId = String.fromCharCodes(
        List<int>.filled(const CanonicalJsonLimits().maxTextBytes + 1, 0x78),
      );
      final command = CommandEnvelope(
        commandId: oversizedId,
        commandType: 'OpenTableSession',
        commandVersion: '1.0',
        protocolVersion: '1.0.0',
        tableId: 'table_001',
        sessionId: null,
        handId: null,
        issuedAt: '2026-04-25T12:05:00Z',
        actorRef: 'host_alpha',
        payload: <String, Object?>{},
      );

      final errors = CoreCommandValidator().validate(command);

      expect(errors, contains('command_id contains unsafe characters'));
      expect(errors, isNot(contains('command artifact is unsupported')));
    },
  );

  test('validator rejects oversized command payloads', () {
    final command = CommandEnvelope(
      commandId: 'cmd_oversized_payload',
      commandType: 'OpenTableSession',
      commandVersion: '1.0',
      protocolVersion: '1.0.0',
      tableId: 'table_001',
      sessionId: null,
      handId: null,
      issuedAt: '2026-04-25T12:05:00Z',
      actorRef: 'host_alpha',
      payload: <String, Object?>{
        'details': List<String>.filled(4097, 'x').join(),
      },
    );

    expect(
      CoreCommandValidator().validate(command),
      contains('command payload exceeds canonical protocol limits'),
    );
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

  test('core accepts fixture-backed Holdem blocked settlement events', () {
    const fixtureCases = <String, List<String>>{
      'events/holdem_settlement_blocked_event_v1.json': <String>[
        'ERR_HOLDEM_SETTLEMENT_PROJECT_UNAWARDABLE',
      ],
      'events/holdem_settlement_blocked_empty_pot_event_v1.json': <String>[
        'ERR_HOLDEM_SETTLEMENT_PROJECT_EMPTY_POT',
      ],
      'events/holdem_settlement_blocked_invalid_showdown_event_v1.json':
          <String>['ERR_HOLDEM_SETTLEMENT_PROJECT_INVALID_SHOWDOWN'],
    };

    final started = eventEnvelopeFromJson(
      loadProtocolFixture('events/holdem_hand_started_event_v1.json'),
    );

    for (final entry in fixtureCases.entries) {
      final blocked = eventEnvelopeFromJson(loadProtocolFixture(entry.key));
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

      expect(state.phase, TablePhase.liveActive, reason: entry.key);
      expect(state.activeHandId, started.handId, reason: entry.key);
      expect(state.eventSeq, 2, reason: entry.key);
      expect(
        state.metadata['last_event_hash'],
        adjustedBlocked.eventHash,
        reason: entry.key,
      );
      expect(
        state.metadata['last_settlement_status'],
        'blocked',
        reason: entry.key,
      );
      expect(
        state.metadata['last_settlement_event_type'],
        'SettlementBlocked',
        reason: entry.key,
      );
      expect(
        state.metadata['last_settlement_reason_codes'],
        entry.value,
        reason: entry.key,
      );
      expect(
        state.metadata['last_settlement_warnings'],
        containsAll(entry.value),
        reason: entry.key,
      );
      expect(
        state.metadata['last_settlement_hand_id'],
        started.handId,
        reason: entry.key,
      );
    }
  });

  test('core projection covers every accepted protocol event fixture', () {
    const coveredFixturePaths = <String>{
      'holdem_hand_settled_event_v1.json',
      'holdem_hand_started_event_v1.json',
      'holdem_settlement_blocked_empty_pot_event_v1.json',
      'holdem_settlement_blocked_event_v1.json',
      'holdem_settlement_blocked_invalid_showdown_event_v1.json',
      'holdem_settlement_projected_event_v1.json',
      'holdem_showdown_revealed_event_v1.json',
      'holdem_showdown_started_event_v1.json',
      'holdem_uncontested_settlement_projected_event_v1.json',
      'open_table_session_opened_event_v1.json',
    };
    final acceptedFixturePaths = acceptedProtocolEventFixturePaths();

    expect(coveredFixturePaths, acceptedFixturePaths.toSet());

    for (final fixturePath in acceptedFixturePaths) {
      final state = projectAcceptedProtocolEventFixture(fixturePath);

      expect(state.eventSeq, greaterThan(0), reason: fixturePath);
      expect(state.metadata['last_event_hash'], isNotNull, reason: fixturePath);
    }
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

  test('core rejects protocol events with empty envelope identity fields', () {
    final valid = protocolEvent(
      eventId: 'evt_001',
      eventType: 'OpenTableSessionOpened',
      eventSeq: 1,
    );
    final malformedEvents = <EventEnvelope>[
      copyEvent(valid, eventId: ' '),
      copyEvent(valid, eventType: ' '),
      copyEvent(valid, eventVersion: ' '),
      copyEvent(valid, protocolVersion: ' '),
      copyEvent(valid, tableId: ' '),
      copyEvent(valid, sessionId: ' '),
      copyEvent(valid, emittedAt: ' '),
      copyEvent(valid, actorRef: ' '),
      copyEvent(valid, prevEventHash: ' '),
      copyEvent(valid, eventHash: ' '),
    ];

    for (final malformed in malformedEvents) {
      expect(
        () => const CoreReducer().apply(TableState.initial(), malformed),
        throwsA(
          isA<InvariantViolation>().having(
            (violation) => violation.code,
            'code',
            CoreInvariantCodes.eventEnvelopeIdentityEmpty,
          ),
        ),
      );
    }
  });

  test('core rejects unsafe or oversized event envelope identities', () {
    final valid = protocolEvent(
      eventId: 'evt_001',
      eventType: 'OpenTableSessionOpened',
      eventSeq: 1,
    );
    final oversizedId = String.fromCharCodes(
      List<int>.filled(const CanonicalJsonLimits().maxTextBytes + 1, 0x78),
    );
    final malformedEvents = <EventEnvelope>[
      copyEvent(valid, eventId: 'evt\n001'),
      copyEvent(valid, tableId: ' tbl_001'),
      copyEvent(valid, eventId: String.fromCharCode(0xd800)),
      copyEvent(valid, eventId: oversizedId),
    ];

    for (final malformed in malformedEvents) {
      expect(
        () => const CoreReducer().apply(TableState.initial(), malformed),
        throwsA(
          isA<InvariantViolation>().having(
            (violation) => violation.code,
            'code',
            CoreInvariantCodes.eventEnvelopeIdentityUnsafe,
          ),
        ),
      );
    }
  });

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
          CoreInvariantCodes.participantSeatedWithoutConnected,
        ),
      ),
    );
  });

  test('core rejects hand-scoped protocol events without an active hand', () {
    final opened = protocolEvent(
      eventId: 'evt_001',
      eventType: 'OpenTableSessionOpened',
      eventSeq: 1,
    );
    final settlement = protocolEvent(
      eventId: 'evt_002',
      eventType: 'SettlementProjected',
      eventSeq: 2,
      handId: 'hand_001',
      payload: const {'hand_id': 'hand_001'},
    );

    expect(
      () => projectOrderedEvents([opened, settlement]),
      throwsA(
        isA<InvariantViolation>().having(
          (violation) => violation.code,
          'code',
          CoreInvariantCodes.handEventWithoutActiveHand,
        ),
      ),
    );
  });

  test(
    'core rejects hand-scoped protocol events for the wrong active hand',
    () {
      final opened = protocolEvent(
        eventId: 'evt_001',
        eventType: 'OpenTableSessionOpened',
        eventSeq: 1,
      );
      final started = protocolEvent(
        eventId: 'evt_002',
        eventType: 'HandStarted',
        eventSeq: 2,
        handId: 'hand_001',
        payload: const {'hand_id': 'hand_001'},
      );
      final showdown = protocolEvent(
        eventId: 'evt_003',
        eventType: 'ShowdownStarted',
        eventSeq: 3,
        handId: 'hand_002',
        payload: const {'hand_id': 'hand_002'},
      );

      expect(
        () => projectOrderedEvents([opened, started, showdown]),
        throwsA(
          isA<InvariantViolation>().having(
            (violation) => violation.code,
            'code',
            CoreInvariantCodes.handEventIdMismatch,
          ),
        ),
      );
    },
  );

  test('core rejects starting another hand before settlement', () {
    final opened = protocolEvent(
      eventId: 'evt_001',
      eventType: 'OpenTableSessionOpened',
      eventSeq: 1,
    );
    final firstStarted = protocolEvent(
      eventId: 'evt_002',
      eventType: 'HandStarted',
      eventSeq: 2,
      handId: 'hand_001',
      payload: const {'hand_id': 'hand_001'},
    );
    final secondStarted = protocolEvent(
      eventId: 'evt_003',
      eventType: 'HandStarted',
      eventSeq: 3,
      handId: 'hand_002',
      payload: const {'hand_id': 'hand_002'},
    );

    expect(
      () => projectOrderedEvents([opened, firstStarted, secondStarted]),
      throwsA(
        isA<InvariantViolation>().having(
          (violation) => violation.code,
          'code',
          CoreInvariantCodes.handStartedWhileActive,
        ),
      ),
    );
  });

  test('core rejects closing a session before close is requested', () {
    final opened = protocolEvent(
      eventId: 'evt_001',
      eventType: 'OpenTableSessionOpened',
      eventSeq: 1,
    );
    final closed = protocolEvent(
      eventId: 'evt_002',
      eventType: 'SessionClosed',
      eventSeq: 2,
    );

    expect(
      () => projectOrderedEvents([opened, closed]),
      throwsA(
        isA<InvariantViolation>().having(
          (violation) => violation.code,
          'code',
          CoreInvariantCodes.sessionClosedWithoutCloseRequest,
        ),
      ),
    );
  });

  test('core rejects wiping a session before it is closed', () {
    final opened = protocolEvent(
      eventId: 'evt_001',
      eventType: 'OpenTableSessionOpened',
      eventSeq: 1,
    );
    final wiped = protocolEvent(
      eventId: 'evt_002',
      eventType: 'SessionWiped',
      eventSeq: 2,
    );

    expect(
      () => projectOrderedEvents([opened, wiped]),
      throwsA(
        isA<InvariantViolation>().having(
          (violation) => violation.code,
          'code',
          CoreInvariantCodes.sessionWipedBeforeClose,
        ),
      ),
    );
  });

  test('core rejects events after a terminal closed state', () {
    final events = <EventEnvelope>[
      protocolEvent(
        eventId: 'evt_001',
        eventType: 'OpenTableSessionOpened',
        eventSeq: 1,
      ),
      protocolEvent(
        eventId: 'evt_002',
        eventType: 'SessionCloseRequested',
        eventSeq: 2,
      ),
      protocolEvent(
        eventId: 'evt_003',
        eventType: 'SessionClosed',
        eventSeq: 3,
      ),
      protocolEvent(
        eventId: 'evt_004',
        eventType: 'ParticipantConnected',
        eventSeq: 4,
      ),
    ];

    expect(
      () => projectOrderedEvents(events),
      throwsA(
        isA<InvariantViolation>().having(
          (violation) => violation.code,
          'code',
          CoreInvariantCodes.terminalStateCannotAdvance,
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
    final event1 = EventEnvelope(
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

    final event2 = EventEnvelope(
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
