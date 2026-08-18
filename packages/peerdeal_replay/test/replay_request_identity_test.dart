import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_replay/peerdeal_replay.dart';
import 'package:test/test.dart';

import 'fakes/fake_table_projector.dart';

void main() {
  final engine = BasicReplayEngine<FakeTableProjection>(
    projector: FakeTableProjector(),
  );

  test('rejects C1 request scope text before projection', () {
    final result = engine.replay(
      ReplayRequest(
        tableId: 'table_1',
        sessionId: 'session_\u0085',
        protocolVersion: '1.0.0',
        scope: ReplayScope.session,
        events: const <EventEnvelope>[],
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.state, isNull);
    expect(result.mismatches.single.code, 'ERR_REPLAY_REQUEST_SCOPE_INVALID');
    expect(result.mismatches.single.actual, ['session_id']);
  });

  test('rejects oversized request scope text before projection', () {
    final result = engine.replay(
      ReplayRequest(
        tableId: List<String>.filled(4097, 't').join(),
        sessionId: 'session_1',
        protocolVersion: '1.0.0',
        scope: ReplayScope.session,
        events: const <EventEnvelope>[],
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.state, isNull);
    expect(result.mismatches.single.code, 'ERR_REPLAY_REQUEST_SCOPE_INVALID');
    expect(result.mismatches.single.actual, ['table_id']);
  });

  test('rejects non-round-tripping request scope text', () {
    final result = engine.replay(
      ReplayRequest(
        tableId: 'table_1',
        sessionId: String.fromCharCode(0xd800),
        protocolVersion: '1.0.0',
        scope: ReplayScope.session,
        events: const <EventEnvelope>[],
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.state, isNull);
    expect(result.mismatches.single.code, 'ERR_REPLAY_REQUEST_SCOPE_INVALID');
    expect(result.mismatches.single.actual, ['session_id']);
  });
}
