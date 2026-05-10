import 'dart:convert';
import 'dart:io';

import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:test/test.dart';

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

  test('game file fixture validates', () {
    final file = File('fixtures/gamefiles/open_table_valid_v1.json');
    final decoded = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
    final errors = GameFileSchema().validate(decoded);
    expect(errors, isEmpty);
  });

  test('invite payload fixture validates', () {
    final file = File('fixtures/invites/open_table_player_invite_v1.json');
    final decoded = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
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
    final file = File('fixtures/commands/open_table_session_command_v1.json');
    final decoded = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;

    final result = catalog.checkCommandEnvelopeJson(decoded);

    expect(result.isSupported, isTrue);
    expect(result.resultCode, ResultCode.okAccepted);
  });

  test('protocol catalog accepts fixture-backed event', () {
    final catalog = ProtocolCatalog();
    final file = File(
      'fixtures/events/open_table_session_opened_event_v1.json',
    );
    final decoded = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;

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
    final result = ProtocolCatalog().checkSnapshotEnvelopeJson({
      'snapshot_type': 'TableSnapshot',
      'snapshot_version': '1.0',
      'protocol_version': currentProtocolVersion.toWire(),
    });

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
