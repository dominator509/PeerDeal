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

String catalogEntryKey(ProtocolCatalogEntry entry) {
  return entry.key;
}

ProtocolCompatibilityResult catalogResultForFixture(
  ProtocolCatalog catalog,
  File fixture,
) {
  final decoded =
      jsonDecode(fixture.readAsStringSync()) as Map<String, Object?>;
  final path = fixture.path;

  if (path.contains(
    '${Platform.pathSeparator}commands${Platform.pathSeparator}',
  )) {
    return catalog.checkCommandEnvelopeJson(decoded);
  }
  if (path.contains(
    '${Platform.pathSeparator}events${Platform.pathSeparator}',
  )) {
    return catalog.checkEventEnvelopeJson(decoded);
  }
  if (path.contains(
    '${Platform.pathSeparator}snapshots${Platform.pathSeparator}',
  )) {
    return catalog.checkSnapshotEnvelopeJson(decoded);
  }
  if (path.contains(
    '${Platform.pathSeparator}gamefiles${Platform.pathSeparator}',
  )) {
    return catalog.checkGameFileJson(decoded);
  }
  if (path.contains(
    '${Platform.pathSeparator}invites${Platform.pathSeparator}',
  )) {
    return catalog.checkInvitePayloadJson(decoded);
  }

  throw ArgumentError.value(path, 'fixture.path', 'Unsupported fixture family');
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

  test('canonical json rejects bounded structure and value violations', () {
    expect(
      () => canonicalJsonEncode({
        'a': 1,
        'b': 2,
      }, limits: const CanonicalJsonLimits(maxMapEntries: 1)),
      throwsFormatException,
    );
    expect(
      () => canonicalJsonEncode({
        'nested': [1, 2],
      }, limits: const CanonicalJsonLimits(maxListItems: 1)),
      throwsFormatException,
    );
    expect(
      () => canonicalJsonEncode({'value': Object()}),
      throwsFormatException,
    );
    expect(
      () => canonicalJsonEncode({
        'value': 'long',
      }, limits: const CanonicalJsonLimits(maxTextBytes: 3)),
      throwsFormatException,
    );
    expect(
      () => const CanonicalJsonLimits(maxEncodedBytes: 0).validate(),
      throwsArgumentError,
    );
  });

  test('canonical json rejects non-round-tripping UTF-8 text', () {
    final malformed = String.fromCharCode(0xd800);
    const limits = CanonicalJsonLimits();

    expect(limits.isWithinUtf8TextLimit(malformed), isFalse);
    expect(
      () => canonicalJsonEncode(<String, Object?>{'value': malformed}),
      throwsFormatException,
    );
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

  test('invite payload rejects unsafe or non-text required fields', () {
    final decoded =
        fixtureJson('fixtures/invites/open_table_player_invite_v1.json')
          ..['session_id'] = 42
          ..['invite_code'] = ' ALPHA7'
          ..['signature'] = '';

    final errors = InvitePayloadSchema().validate(decoded);

    expect(errors, contains('session_id must be a string'));
    expect(errors, contains('invite_code must be non-empty and unpadded'));
    expect(errors, contains('signature must be non-empty and unpadded'));
  });

  test('invite payload rejects unsupported mode type', () {
    final decoded = fixtureJson(
      'fixtures/invites/open_table_player_invite_v1.json',
    )..['mode_type'] = 'private_table';

    final errors = InvitePayloadSchema().validate(decoded);

    expect(errors, contains('mode_type must be tournament or open_table'));
  });

  test('invite payload rejects control characters in required text', () {
    final decoded = fixtureJson(
      'fixtures/invites/open_table_player_invite_v1.json',
    )..['invite_id'] = 'inv_001\u0000';

    final errors = InvitePayloadSchema().validate(decoded);

    expect(errors, contains('invite_id contains a control character'));
  });

  test('invite payload rejects C1 control characters in required text', () {
    final decoded = fixtureJson(
      'fixtures/invites/open_table_player_invite_v1.json',
    )..['invite_id'] = 'inv_001\u0085';

    final errors = InvitePayloadSchema().validate(decoded);

    expect(errors, contains('invite_id contains a control character'));
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
    expect(
      ProtocolResultCodes.all.toSet(),
      hasLength(ProtocolResultCodes.all.length),
    );
  });

  test('protocol diagnostic serializes optional details consistently', () {
    final diagnostic = ProtocolDiagnostic(
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

  test('protocol diagnostic owns nested optional details', () {
    final expected = <String, Object?>{
      'allowed': <Object?>['1.0.0'],
    };
    final actual = <String, Object?>{
      'received': <Object?>['2.0.0'],
    };
    final diagnostic = ProtocolDiagnostic(
      code: ProtocolResultCodes.errProtocolIncompatible,
      message: 'Protocol version is not supported.',
      expected: expected,
      actual: actual,
    );
    final serialized = diagnostic.toJson();

    expected['allowed'] = <Object?>['changed'];
    actual['received'] = <Object?>['changed'];

    expect(diagnostic.expected, {
      'allowed': ['1.0.0'],
    });
    expect(diagnostic.actual, {
      'received': ['2.0.0'],
    });
    expect(serialized, {
      'code': 'ERR_PROTOCOL_INCOMPATIBLE',
      'message': 'Protocol version is not supported.',
      'expected': {
        'allowed': ['1.0.0'],
      },
      'actual': {
        'received': ['2.0.0'],
      },
    });
    expect(
      () => (serialized['expected']! as Map<Object?, Object?>)['allowed'] =
          <Object?>['changed again'],
      throwsUnsupportedError,
    );
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

  test('accepted protocol fixtures are locked by the catalog', () {
    const catalog = ProtocolCatalog();
    final fixtures = protocolFixtureFiles()
        .where((fixture) => !isRejectedFixture(fixture))
        .toList();

    expect(fixtures, isNotEmpty);
    for (final fixture in fixtures) {
      final result = catalogResultForFixture(catalog, fixture);

      expect(result.isSupported, isTrue, reason: fixture.path);
      expect(result.resultCode, ResultCode.okAccepted, reason: fixture.path);
      expect(result.entry, isNotNull, reason: fixture.path);
    }
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

  test('protocol catalog accepts Holdem lifecycle event fixtures', () {
    const fixturePaths = <String>[
      'fixtures/events/holdem_hand_started_event_v1.json',
      'fixtures/events/holdem_showdown_started_event_v1.json',
      'fixtures/events/holdem_showdown_revealed_event_v1.json',
      'fixtures/events/holdem_settlement_projected_event_v1.json',
      'fixtures/events/holdem_uncontested_settlement_projected_event_v1.json',
      'fixtures/events/holdem_settlement_blocked_event_v1.json',
      'fixtures/events/holdem_settlement_blocked_empty_pot_event_v1.json',
      'fixtures/events/holdem_settlement_blocked_invalid_showdown_event_v1.json',
      'fixtures/events/holdem_hand_settled_event_v1.json',
    ];
    const catalog = ProtocolCatalog();

    for (final fixturePath in fixturePaths) {
      final result = catalog.checkEventEnvelopeJson(fixtureJson(fixturePath));

      expect(result.isSupported, isTrue, reason: fixturePath);
      expect(result.resultCode, ResultCode.okAccepted, reason: fixturePath);
    }
  });

  test('Holdem blocked settlement fixtures carry stable reason codes', () {
    const fixtureCases = <String, List<String>>{
      'fixtures/events/holdem_settlement_blocked_event_v1.json': <String>[
        'ERR_HOLDEM_SETTLEMENT_PROJECT_UNAWARDABLE',
      ],
      'fixtures/events/holdem_settlement_blocked_empty_pot_event_v1.json':
          <String>['ERR_HOLDEM_SETTLEMENT_PROJECT_EMPTY_POT'],
      'fixtures/events/holdem_settlement_blocked_invalid_showdown_event_v1.json':
          <String>['ERR_HOLDEM_SETTLEMENT_PROJECT_INVALID_SHOWDOWN'],
    };

    for (final entry in fixtureCases.entries) {
      final decoded = fixtureJson(entry.key);
      final payload = decoded['payload']! as Map<String, Object?>;

      expect(payload['reason_codes'], entry.value, reason: entry.key);
      expect(payload['warnings'], containsAll(entry.value), reason: entry.key);
    }
  });

  test('protocol catalog accepts scaffold replay and recovery events', () {
    const supportedEventTypes = <String>[
      'OpenTableSessionOpened',
      'ParticipantAdmitted',
      'ParticipantConnected',
      'ParticipantSeated',
      'HandStarted',
      'PlayerFolded',
      'PlayerChecked',
      'PlayerCalled',
      'PlayerBet',
      'PlayerRaised',
      'PlayerAllIn',
      'ShowdownStarted',
      'ShowdownRevealed',
      'SettlementProjected',
      'SettlementBlocked',
      'HandSettled',
      'SessionCloseRequested',
      'SessionClosed',
      'SessionWiped',
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

  test('default protocol catalog entries are unique', () {
    final keys = defaultProtocolCatalogEntries.map(catalogEntryKey).toList();

    expect(keys.toSet(), hasLength(keys.length));
  });

  test('default protocol catalog lock is complete', () {
    final report = const ProtocolCatalog().validateLock();

    expect(report.isLocked, isTrue);
    expect(report.errors, isEmpty);
  });

  test('protocol catalog lock detects duplicate entries', () {
    const entry = ProtocolCatalogEntry(
      kind: ProtocolArtifactKind.command,
      type: 'OpenTableSession',
      artifactVersion: '1.0',
      protocolVersion: currentProtocolVersion,
    );
    final report =
        ProtocolCatalog.withEntries(
          entries: <ProtocolCatalogEntry>[entry, entry],
        ).validateLock(
          requiredKinds: <ProtocolArtifactKind>[ProtocolArtifactKind.command],
        );

    expect(report.isLocked, isFalse);
    expect(
      report.errors,
      contains(startsWith('ERR_PROTOCOL_CATALOG_DUPLICATE_ENTRY:')),
    );
  });

  test('protocol catalog lock detects missing artifact families', () {
    final report = ProtocolCatalog.withEntries(
      entries: <ProtocolCatalogEntry>[],
    ).validateLock();

    expect(report.isLocked, isFalse);
    expect(
      report.errors,
      contains(
        'ERR_PROTOCOL_CATALOG_MISSING_KIND:${ProtocolArtifactKind.command.name}',
      ),
    );
    expect(
      report.errors,
      contains(
        'ERR_PROTOCOL_CATALOG_MISSING_KIND:${ProtocolArtifactKind.resultCode.name}',
      ),
    );
  });

  test('protocol catalog exposes complete scaffold artifact families', () {
    const catalog = ProtocolCatalog();

    expect(catalog.supportedTypesFor(ProtocolArtifactKind.command), [
      'OpenTableSession',
      'StartHand',
      'PlayerFold',
      'PlayerCheck',
      'PlayerCall',
      'PlayerBet',
      'PlayerRaise',
      'PlayerAllIn',
      'RequestSessionClose',
    ]);
    expect(catalog.supportedTypesFor(ProtocolArtifactKind.event), [
      'OpenTableSessionOpened',
      'ParticipantAdmitted',
      'ParticipantConnected',
      'ParticipantSeated',
      'HandStarted',
      'PlayerFolded',
      'PlayerChecked',
      'PlayerCalled',
      'PlayerBet',
      'PlayerRaised',
      'PlayerAllIn',
      'ShowdownStarted',
      'ShowdownRevealed',
      'SettlementProjected',
      'SettlementBlocked',
      'HandSettled',
      'SessionCloseRequested',
      'SessionClosed',
      'SessionWiped',
      'IgnoredBecauseCoveredBySnapshot',
      'RecoveryPauseEnded',
    ]);
    expect(catalog.supportedTypesFor(ProtocolArtifactKind.snapshot), [
      'TableSnapshot',
    ]);
    expect(catalog.supportedTypesFor(ProtocolArtifactKind.gameFile), [
      'peerdeal.gamefile',
    ]);
    expect(catalog.supportedTypesFor(ProtocolArtifactKind.invitePayload), [
      'InvitePayload',
    ]);
    expect(
      catalog.supportedTypesFor(ProtocolArtifactKind.resultCode),
      ProtocolResultCodes.all,
    );
  });

  test('default protocol catalog groups compose the public catalog', () {
    expect(defaultProtocolCatalogEntries, [
      ...supportedCommandCatalogEntries,
      ...supportedEventCatalogEntries,
      ...supportedSnapshotCatalogEntries,
      ...supportedGameFileCatalogEntries,
      ...supportedInvitePayloadCatalogEntries,
      ...supportedResultCodeCatalogEntries,
    ]);
  });

  test('protocol catalog accepts Game File identities', () {
    const fixturePaths = <String>[
      'fixtures/gamefiles/open_table_valid_v1.json',
      'fixtures/gamefiles/tournament_valid_v1.json',
    ];
    const catalog = ProtocolCatalog();

    for (final fixturePath in fixturePaths) {
      final result = catalog.checkGameFileJson(fixtureJson(fixturePath));

      expect(result.isSupported, isTrue, reason: fixturePath);
      expect(result.resultCode, ResultCode.okAccepted, reason: fixturePath);
    }
  });

  test('protocol catalog accepts invite payload identities', () {
    final result = const ProtocolCatalog().checkInvitePayloadJson(
      fixtureJson('fixtures/invites/open_table_player_invite_v1.json'),
    );

    expect(result.isSupported, isTrue);
    expect(result.resultCode, ResultCode.okAccepted);
  });

  test('protocol catalog accepts public protocol result code identities', () {
    const catalog = ProtocolCatalog();

    for (final code in ProtocolResultCodes.all) {
      final result = catalog.checkResultCode(code);

      expect(result.isSupported, isTrue, reason: code);
      expect(result.resultCode, ResultCode.okAccepted, reason: code);
    }
  });

  test('protocol catalog accepts scaffold command and action identities', () {
    const commandTypes = <String>[
      'OpenTableSession',
      'StartHand',
      'PlayerFold',
      'PlayerCheck',
      'PlayerCall',
      'PlayerBet',
      'PlayerRaise',
      'PlayerAllIn',
      'RequestSessionClose',
    ];

    for (final commandType in commandTypes) {
      final result = ProtocolCatalog().check(
        kind: ProtocolArtifactKind.command,
        type: commandType,
        artifactVersion: '1.0',
        protocolVersion: currentProtocolVersion.toWire(),
      );

      expect(result.isSupported, isTrue, reason: commandType);
      expect(result.resultCode, ResultCode.okAccepted, reason: commandType);
    }
  });

  test('protocol catalog accepts settlement path event identities', () {
    const eventTypes = <String>[
      'ShowdownStarted',
      'ShowdownRevealed',
      'SettlementProjected',
      'SettlementBlocked',
      'HandSettled',
    ];

    for (final eventType in eventTypes) {
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

  test('protocol catalog rejects unsupported protocol Game File fail-safe', () {
    final decoded = fixtureJson('fixtures/gamefiles/open_table_valid_v1.json');
    decoded['protocol_version'] = '2.0.0';

    final result = const ProtocolCatalog().checkGameFileJson(decoded);

    expect(result.isSupported, isFalse);
    expect(result.resultCode, ResultCode.errProtocolIncompatible);
  });

  test('protocol catalog rejects unsupported protocol invite fail-safe', () {
    final decoded = fixtureJson(
      'fixtures/invites/open_table_player_invite_v1.json',
    );
    decoded['protocol_version'] = '2.0.0';

    final result = const ProtocolCatalog().checkInvitePayloadJson(decoded);

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
    final snapshot = SnapshotEnvelope(
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

  test('event envelope round-trips through JSON', () {
    final event = EventEnvelope.fromJson(
      EventEnvelope(
        eventId: 'evt_1',
        eventType: 'RecoveryEventPersisted',
        eventVersion: '1.0',
        protocolVersion: '1.0.0',
        eventSeq: 1,
        tableId: 'table_1',
        sessionId: 'session_1',
        handId: null,
        emittedAt: '2026-06-08T00:00:00Z',
        actorRef: 'system',
        payload: <String, Object?>{'kind': 'recovery'},
        prevEventHash: genesisEventHash,
        eventHash: 'hash_1',
      ).toJson(),
    );

    expect(event.eventId, 'evt_1');
    expect(event.payload['kind'], 'recovery');
    expect(event.eventHash, 'hash_1');
  });

  test('genesis event hash matches accepted open-session fixture', () {
    final decoded = fixtureJson(
      'fixtures/events/open_table_session_opened_event_v1.json',
    );

    expect(decoded['prev_event_hash'], genesisEventHash);
  });

  test('snapshot envelope round-trips through JSON', () {
    final snapshot = SnapshotEnvelope.fromJson(
      SnapshotEnvelope(
        snapshotId: 'snap_1',
        protocolVersion: '1.0.0',
        tableId: 'table_1',
        sessionId: 'session_1',
        snapshotBaseEventSeq: 1,
        snapshotHash: 'snap_hash',
        payload: <String, Object?>{'kind': 'table'},
      ).toJson(),
    );

    expect(snapshot.snapshotId, 'snap_1');
    expect(snapshot.snapshotType, 'TableSnapshot');
    expect(snapshot.payload['kind'], 'table');
  });

  test('rejects structurally oversized direct snapshot hydration', () {
    final oversized =
        SnapshotEnvelope(
            snapshotId: 'snap_1',
            protocolVersion: '1.0.0',
            tableId: 'table_1',
            sessionId: 'session_1',
            snapshotBaseEventSeq: 1,
            snapshotHash: 'snap_hash',
            payload: <String, Object?>{},
          ).toJson()
          ..['payload'] = <String, Object?>{
            for (var index = 0; index < 257; index += 1) 'key_$index': index,
          };

    expect(
      () => SnapshotEnvelope.fromJson(oversized),
      throwsA(isA<FormatException>()),
    );
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

  test('protocol catalog rejects unsupported result code fail-safe', () {
    final result = const ProtocolCatalog().checkResultCode('ERR_UNKNOWN');

    expect(result.isSupported, isFalse);
    expect(result.resultCode, ResultCode.errSchemaInvalid);
  });

  test('protocol catalog rejects typed unsupported event fail-safe', () {
    final result = ProtocolCatalog().checkEventEnvelope(
      EventEnvelope(
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
