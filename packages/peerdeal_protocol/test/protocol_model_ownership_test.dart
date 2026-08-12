import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:test/test.dart';

void main() {
  group('protocol model collection ownership', () {
    test('envelope payloads are recursively owned', () {
      final nestedValues = <Object?>['before'];
      final nested = <String, Object?>{'values': nestedValues};
      final payload = <String, Object?>{'nested': nested};

      final command = CommandEnvelope(
        commandId: 'cmd-1',
        commandType: 'OpenTableSession',
        commandVersion: '1.0',
        protocolVersion: '1.0.0',
        tableId: 'table-1',
        sessionId: 'session-1',
        handId: null,
        issuedAt: '2026-01-01T00:00:00Z',
        actorRef: 'actor-1',
        payload: payload,
      );
      final event = EventEnvelope(
        eventId: 'event-1',
        eventType: 'OpenTableSessionOpened',
        eventVersion: '1.0',
        protocolVersion: '1.0.0',
        eventSeq: 1,
        tableId: 'table-1',
        sessionId: 'session-1',
        handId: null,
        emittedAt: '2026-01-01T00:00:00Z',
        actorRef: 'actor-1',
        payload: payload,
        prevEventHash: genesisEventHash,
        eventHash: 'hash-1',
      );
      final snapshot = SnapshotEnvelope(
        snapshotId: 'snapshot-1',
        protocolVersion: '1.0.0',
        tableId: 'table-1',
        sessionId: 'session-1',
        snapshotBaseEventSeq: 1,
        snapshotHash: 'hash-1',
        payload: payload,
      );

      nestedValues.add('after');
      nested['later'] = true;
      payload['outside'] = true;

      for (final ownedPayload in <Map<String, Object?>>[
        command.payload,
        event.payload,
        snapshot.payload,
      ]) {
        final ownedNested = ownedPayload['nested']! as Map<Object?, Object?>;
        final ownedValues = ownedNested['values']! as List<Object?>;
        expect(ownedValues, <Object?>['before']);
        expect(ownedNested.containsKey('later'), isFalse);
        expect(ownedPayload.containsKey('outside'), isFalse);
        expect(() => ownedValues.add('blocked'), throwsUnsupportedError);
        expect(() => ownedNested['blocked'] = true, throwsUnsupportedError);
        expect(() => ownedPayload['blocked'] = true, throwsUnsupportedError);
      }
    });

    test('custom catalogs own entry collections and reports own errors', () {
      const entry = ProtocolCatalogEntry(
        kind: ProtocolArtifactKind.command,
        type: 'OpenTableSession',
        artifactVersion: '1.0',
        protocolVersion: currentProtocolVersion,
      );
      final entries = <ProtocolCatalogEntry>[entry];
      final catalog = ProtocolCatalog.withEntries(entries: entries);
      final errors = <String>['error'];
      final report = ProtocolCatalogLockReport(errors: errors);

      entries.clear();
      errors.clear();

      expect(catalog.entries, hasLength(1));
      expect(report.errors, <String>['error']);
      expect(() => catalog.entries.clear(), throwsUnsupportedError);
      expect(() => report.errors.clear(), throwsUnsupportedError);
    });
  });
}
