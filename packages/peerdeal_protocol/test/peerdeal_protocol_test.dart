import 'dart:convert';
import 'dart:io';

import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:test/test.dart';

Map<String, Object?> fixtureJson(String path) {
  return jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
}

List<File> protocolFixtureFiles() {
  return Directory('fixtures')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

bool isRejectedFixture(File fixture) {
  final name = fixture.uri.pathSegments.last;
  return name.startsWith('invalid_') || name.startsWith('unsupported_');
}

void main() {
  test('canonical json encoding is stable for map key order', () {
    final a = canonicalJsonEncode({
      'b': 2,
      'a': 1,
      'nested': {'z': true, 'x': false},
    });

    final b = canonicalJsonEncode({
      'nested': {'x': false, 'z': true},
      'a': 1,
      'b': 2,
    });

    expect(a, equals(b));
  });

  test('all protocol fixtures are JSON objects', () {
    final fixtures = protocolFixtureFiles();

    expect(fixtures, isNotEmpty);
    for (final fixture in fixtures) {
      final decoded = jsonDecode(fixture.readAsStringSync());

      expect(decoded, isA<Map<String, Object?>>(), reason: fixture.path);
    }
  });

  test('each protocol fixture category has accepted and rejected examples', () {
    const categories = <String>[
      'commands',
      'events',
      'gamefiles',
      'invites',
      'snapshots',
    ];
    final fixtures = protocolFixtureFiles();

    for (final category in categories) {
      final categoryFixtures = fixtures
          .where(
            (fixture) => fixture.path.contains(
              '${Platform.pathSeparator}$category${Platform.pathSeparator}',
            ),
          )
          .toList();

      expect(categoryFixtures, isNotEmpty, reason: category);
      expect(
        categoryFixtures.any((fixture) => !isRejectedFixture(fixture)),
        isTrue,
        reason: '$category accepted fixture',
      );
      expect(
        categoryFixtures.any(isRejectedFixture),
        isTrue,
        reason: '$category rejected fixture',
      );
    }
  });

  test('game file fixture validates', () {
    final decoded = fixtureJson('fixtures/gamefiles/open_table_valid_v1.json');
    final errors = GameFileSchema().validate(decoded);
    expect(errors, isEmpty);
  });

  test('invite payload fixture validates', () {
    final decoded = fixtureJson(
      'fixtures/invites/open_table_player_invite_v1.json',
    );
    final errors = InvitePayloadSchema().validate(decoded);
    expect(errors, isEmpty);
  });

  test('event hash helper returns non-empty sha256', () {
    final hash = computeCanonicalHash({
      'event_type': 'OpenTableSessionOpened',
      'payload': {'config_id': 'cfg_open_table_001'},
    });
    expect(hash.length, equals(64));
  });

  test('protocol result code wire values are stable', () {
    expect(
      ProtocolResultCodes.errProtocolIncompatible,
      'ERR_PROTOCOL_INCOMPATIBLE',
    );
    expect(
      ProtocolResultCodes.errReplayEventSchemaUnsupported,
      'ERR_REPLAY_EVENT_SCHEMA_UNSUPPORTED',
    );
    expect(
      ProtocolResultCodes.errSnapshotSchemaUnsupported,
      'ERR_SNAPSHOT_SCHEMA_UNSUPPORTED',
    );
  });

  test('protocol diagnostic serializes optional details consistently', () {
    const diagnostic = ProtocolDiagnostic(
      code: ProtocolResultCodes.errProtocolIncompatible,
      message: 'Protocol version is not supported.',
      expected: '1.0.0',
      actual: '2.0.0',
    );

    expect(diagnostic.toJson(), {
      'code': 'ERR_PROTOCOL_INCOMPATIBLE',
      'message': 'Protocol version is not supported.',
      'expected': '1.0.0',
      'actual': '2.0.0',
    });
  });

  test('protocol catalog accepts fixture-backed command', () {
    final catalog = ProtocolCatalog();
    final decoded = fixtureJson(
      'fixtures/commands/open_table_session_command_v1.json',
    );

    final result = catalog.checkCommandEnvelopeJson(decoded);

    expect(result.isSupported, isTrue);
    expect(result.resultCode, ResultCode.okAccepted);
  });

  test('protocol catalog accepts fixture-backed event', () {
    final catalog = ProtocolCatalog();
    final decoded = fixtureJson(
      'fixtures/events/open_table_session_opened_event_v1.json',
    );

    final result = catalog.checkEventEnvelopeJson(decoded);

    expect(result.isSupported, isTrue);
    expect(result.resultCode, ResultCode.okAccepted);
  });

  test('protocol catalog accepts scaffold replay and recovery events', () {
    const supportedEventTypes = <String>[
      'ParticipantAdmitted',
      'HandStarted',
      'PlayerCalled',
      'IgnoredBecauseCoveredBySnapshot',
      'RecoveryPauseEnded',
    ];

    for (final eventType in supportedEventTypes) {
      final result = ProtocolCatalog().check(
        kind: ProtocolArtifactKind.event,
        type: eventType,
        artifactVersion: '1.0',
        protocolVersion: currentProtocolVersion.toWire(),
      );

      expect(result.isSupported, isTrue, reason: eventType);
      expect(result.resultCode, ResultCode.okAccepted, reason: eventType);
    }
  });

  test('protocol catalog rejects unsupported protocol version fail-safe', () {
    final result = ProtocolCatalog().check(
      kind: ProtocolArtifactKind.command,
      type: 'OpenTableSession',
      artifactVersion: '1.0',
      protocolVersion: '2.0.0',
    );

    expect(result.isSupported, isFalse);
    expect(result.resultCode, ResultCode.errProtocolIncompatible);
  });

  test('protocol catalog rejects unsupported protocol command fixture', () {
    final decoded = fixtureJson(
      'fixtures/commands/unsupported_protocol_open_table_session_command_v2.json',
    );
    final result = ProtocolCatalog().checkCommandEnvelopeJson(decoded);

    expect(result.isSupported, isFalse);
    expect(result.resultCode, ResultCode.errProtocolIncompatible);
  });

  test('protocol catalog rejects unsupported protocol event fixture', () {
    final decoded = fixtureJson(
      'fixtures/events/unsupported_protocol_open_table_session_opened_event_v2.json',
    );
    final result = ProtocolCatalog().checkEventEnvelopeJson(decoded);

    expect(result.isSupported, isFalse);
    expect(result.resultCode, ResultCode.errProtocolIncompatible);
  });

  test('protocol catalog rejects unsupported protocol snapshot fixture', () {
    final decoded = fixtureJson(
      'fixtures/snapshots/unsupported_protocol_table_snapshot_v2.json',
    );
    final result = ProtocolCatalog().checkSnapshotEnvelopeJson(decoded);

    expect(result.isSupported, isFalse);
    expect(result.resultCode, ResultCode.errProtocolIncompatible);
  });

  test('protocol catalog rejects unknown artifact fail-safe', () {
    final result = ProtocolCatalog().check(
      kind: ProtocolArtifactKind.command,
      type: 'UnknownCommand',
      artifactVersion: '1.0',
      protocolVersion: currentProtocolVersion.toWire(),
    );

    expect(result.isSupported, isFalse);
    expect(result.resultCode, ResultCode.errSchemaInvalid);
  });

  test('protocol catalog rejects malformed command envelope fail-safe', () {
    final result = ProtocolCatalog().checkCommandEnvelopeJson({
      'command_type': 'OpenTableSession',
      'protocol_version': currentProtocolVersion.toWire(),
    });

    expect(result.isSupported, isFalse);
    expect(result.resultCode, ResultCode.errSchemaInvalid);
  });

  test('rejected game file fixture fails schema validation', () {
    final decoded = fixtureJson('fixtures/gamefiles/invalid_mode_type_v1.json');
    final errors = GameFileSchema().validate(decoded);

    expect(errors, contains('mode.mode_type must be tournament or open_table'));
  });

  test('rejected invite fixture fails schema validation', () {
    final decoded = fixtureJson('fixtures/invites/invalid_role_hint_v1.json');
    final errors = InvitePayloadSchema().validate(decoded);

    expect(errors, contains('role_hint must be player, spectator, or cohost'));
  });

  test('protocol catalog rejects unsupported command fixture fail-safe', () {
    final decoded = fixtureJson(
      'fixtures/commands/unsupported_command_v1.json',
    );
    final result = ProtocolCatalog().checkCommandEnvelopeJson(decoded);

    expect(result.isSupported, isFalse);
    expect(result.resultCode, ResultCode.errSchemaInvalid);
  });

  test('protocol catalog rejects unsupported event fixture fail-safe', () {
    final decoded = fixtureJson('fixtures/events/unsupported_event_v1.json');
    final result = ProtocolCatalog().checkEventEnvelopeJson(decoded);

    expect(result.isSupported, isFalse);
    expect(result.resultCode, ResultCode.errSchemaInvalid);
  });

  test('protocol catalog rejects unsupported snapshot fixture fail-safe', () {
    final decoded = fixtureJson(
      'fixtures/snapshots/unsupported_snapshot_v1.json',
    );
    final result = ProtocolCatalog().checkSnapshotEnvelopeJson(decoded);

    expect(result.isSupported, isFalse);
    expect(result.resultCode, ResultCode.errSchemaInvalid);
  });

  test('snapshot envelope includes catalog identity fields', () {
    const snapshot = SnapshotEnvelope(
      snapshotId: 'snap_1',
      protocolVersion: '1.0.0',
      tableId: 'table_1',
      sessionId: 'session_1',
      snapshotBaseEventSeq: 1,
      snapshotHash: 'snap_hash',
      payload: <String, Object?>{},
    );

    expect(snapshot.toJson()['snapshot_type'], 'TableSnapshot');
    expect(snapshot.toJson()['snapshot_version'], '1.0');
  });

  test('protocol catalog accepts supported snapshot envelope', () {
    final decoded = fixtureJson('fixtures/snapshots/table_snapshot_v1.json');
    final result = ProtocolCatalog().checkSnapshotEnvelopeJson(decoded);

    expect(result.isSupported, isTrue);
    expect(result.resultCode, ResultCode.okAccepted);
  });

  test('protocol catalog rejects unsupported snapshot envelope fail-safe', () {
    final result = ProtocolCatalog().checkSnapshotEnvelopeJson({
      'snapshot_type': 'UnknownSnapshot',
      'snapshot_version': '1.0',
      'protocol_version': currentProtocolVersion.toWire(),
    });

    expect(result.isSupported, isFalse);
    expect(result.resultCode, ResultCode.errSchemaInvalid);
  });

  test('protocol catalog rejects typed unsupported event fail-safe', () {
    final result = ProtocolCatalog().checkEventEnvelope(
      const EventEnvelope(
        eventId: 'evt_unknown',
        eventType: 'UnknownEvent',
        eventVersion: '1.0',
        protocolVersion: '1.0.0',
        eventSeq: 1,
        tableId: 'table_1',
        sessionId: 'session_1',
        handId: null,
        emittedAt: '2026-04-25T00:00:00Z',
        actorRef: 'system',
        payload: <String, Object?>{},
        prevEventHash: 'root',
        eventHash: 'hash_1',
      ),
    );

    expect(result.isSupported, isFalse);
    expect(result.resultCode, ResultCode.errSchemaInvalid);
  });
}
