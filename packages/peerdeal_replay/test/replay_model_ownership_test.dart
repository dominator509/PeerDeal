import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_replay/peerdeal_replay.dart';
import 'package:test/test.dart';

void main() {
  final event = EventEnvelope(
    eventId: 'event_1',
    eventType: 'SessionOpened',
    eventVersion: '1.0',
    protocolVersion: '1.0',
    eventSeq: 1,
    tableId: 'table_1',
    sessionId: 'session_1',
    handId: null,
    emittedAt: '2026-08-12T00:00:00Z',
    actorRef: 'peer_a',
    payload: <String, Object?>{},
    prevEventHash: genesisEventHash,
    eventHash: 'hash_1',
  );
  final mismatch = ReplayMismatch(
    code: 'ERR_TEST_REPLAY',
    message: 'Test replay mismatch.',
    expected: 'expected',
    actual: 'actual',
  );

  test('replay request and suffix result own and freeze event collections', () {
    final events = <EventEnvelope>[event];
    final request = ReplayRequest(
      tableId: 'table_1',
      sessionId: 'session_1',
      protocolVersion: '1.0',
      scope: ReplayScope.session,
      events: events,
    );
    final suffix = SnapshotSuffixResult(
      eventsToApply: events,
      snapshotBaseEventSeq: 0,
    );

    events.clear();

    expect(request.events, <EventEnvelope>[event]);
    expect(suffix.eventsToApply, <EventEnvelope>[event]);
    expect(() => request.events.clear(), throwsUnsupportedError);
    expect(() => suffix.eventsToApply.clear(), throwsUnsupportedError);
  });

  test('replay result owns and freezes warnings and mismatches', () {
    final warnings = <String>['warning_1'];
    final mismatches = <ReplayMismatch>[mismatch];
    final result = ReplayResult<bool>(
      isSuccess: false,
      state: null,
      finalAppliedEventSeq: null,
      reconstructedAnchor: null,
      warnings: warnings,
      mismatches: mismatches,
    );

    warnings.clear();
    mismatches.clear();

    expect(result.warnings, <String>['warning_1']);
    expect(result.mismatches, <ReplayMismatch>[mismatch]);
    expect(() => result.warnings.clear(), throwsUnsupportedError);
    expect(() => result.mismatches.clear(), throwsUnsupportedError);
  });

  test('replay mismatch owns nested diagnostic details', () {
    final expected = <String, Object?>{
      'allowed': <Object?>['anchor_a'],
    };
    final actual = <String, Object?>{
      'received': <Object?>['anchor_b'],
    };
    final mismatch = ReplayMismatch(
      code: 'ERR_TEST_REPLAY',
      message: 'Test replay mismatch.',
      expected: expected,
      actual: actual,
    );
    final diagnostic = mismatch.toProtocolDiagnostic();

    expected['allowed'] = <Object?>['changed'];
    actual['received'] = <Object?>['changed'];

    expect(mismatch.expected, {
      'allowed': ['anchor_a'],
    });
    expect(mismatch.actual, {
      'received': ['anchor_b'],
    });
    expect(diagnostic.toJson(), {
      'code': 'ERR_TEST_REPLAY',
      'message': 'Test replay mismatch.',
      'expected': {
        'allowed': ['anchor_a'],
      },
      'actual': {
        'received': ['anchor_b'],
      },
    });
  });
}
