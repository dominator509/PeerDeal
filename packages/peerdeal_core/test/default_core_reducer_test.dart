import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:test/test.dart';

import 'fixture_loader.dart';

void main() {
  group('DefaultCoreReducer', () {
    late DefaultCoreReducer reducer;
    late ReducerContext context;

    setUp(() {
      reducer = DefaultCoreReducer();
      context = const ReducerContext(
        protocolVersion: '1.0',
        strictInvariantMode: true,
      );
    });

    test('applies a basic open-to-close sequence deterministically', () {
      final fixture = loadJsonFixture('basic_open_sequence.json');
      final initial = TableState.initial(
        tableId: fixture['initial_state']['table_id'] as String,
        sessionId: fixture['initial_state']['session_id'] as String,
        protocolVersion: fixture['initial_state']['protocol_version'] as String,
      );
      final events = (fixture['events'] as List<dynamic>)
          .map(
            (dynamic raw) => CoreEvent(
              eventId: raw['event_id'] as String,
              eventType: raw['event_type'] as String,
              actorRef: raw['actor_ref'] as String,
              payload: Map<String, Object?>.from(raw['payload'] as Map),
            ),
          )
          .toList();

      final result = reducer.applyEvents(
        initialState: initial,
        events: events,
        context: context,
      );

      expect(result.isSuccess, isTrue);
      expect(result.state.phase, TablePhase.closed);
      expect(result.state.activeHandId, isNull);
      expect(result.state.playersConnected, 0);
      expect(result.state.playersSeated, 0);
      expect(result.state.eventSequence, events.length);
    });

    test('stops projection when an intermediate state violates invariants', () {
      final result = reducer.applyEvents(
        initialState: TableState.initial(),
        events: const <CoreEvent>[
          CoreEvent(
            eventId: 'evt_001',
            eventType: 'OpenTableSessionOpened',
            actorRef: 'host_1',
            payload: <String, Object?>{},
          ),
          CoreEvent(
            eventId: 'evt_002',
            eventType: 'ParticipantSeated',
            actorRef: 'user_1',
            payload: <String, Object?>{},
          ),
          CoreEvent(
            eventId: 'evt_003',
            eventType: 'ParticipantConnected',
            actorRef: 'user_1',
            payload: <String, Object?>{},
          ),
        ],
        context: context,
      );

      expect(result.isSuccess, isFalse);
      expect(result.emittedEvents.map((event) => event.eventId), <String>[
        'evt_001',
        'evt_002',
      ]);
      expect(result.state.eventSequence, 2);
      expect(
        result.violations.map((violation) => violation.code),
        contains(CoreInvariantCodes.seatedExceedsConnected),
      );
    });
  });
}
