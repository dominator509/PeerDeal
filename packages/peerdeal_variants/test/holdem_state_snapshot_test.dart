import 'dart:convert';

import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';
import 'package:test/test.dart';

void main() {
  test('round-trips the typed Holdem state snapshot through JSON', () {
    final snapshot = HoldemStateSnapshot(
      tableState: TableState.initial(
        tableId: 'table_001',
        sessionId: 'session_001',
        protocolVersion: '1.0.0',
      ),
      handState: _handState(),
      eventCursor: _cursor(),
    );

    final persisted = Map<String, Object?>.from(
      jsonDecode(jsonEncode(snapshot.toJson())) as Map,
    );
    final restored = HoldemStateSnapshot.fromJson(
      persisted,
      eventIdFactory: (eventType, eventSeq) => '$eventType-$eventSeq',
      emittedAtFactory: () => '2026-08-10T00:00:00.000Z',
    );

    expect(restored.toJson(), snapshot.toJson());
  });

  test('rejects mismatched table and cursor scope', () {
    expect(
      () => HoldemStateSnapshot(
        tableState: TableState.initial(
          tableId: 'table_001',
          sessionId: 'session_001',
          protocolVersion: '1.0.0',
        ),
        handState: _handState(),
        eventCursor: HoldemEventCursor(
          protocolVersion: '1.0.0',
          tableId: 'table_002',
          sessionId: 'session_001',
          nextEventSeq: 1,
          previousEventHash: 'genesis',
          actorRef: 'peer_local',
          eventIdFactory: (_, eventSeq) => 'event-$eventSeq',
          emittedAtFactory: () => 'timestamp',
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('rejects malformed snapshot component shapes', () {
    final malformed = <String, Object?>{
      'table_state': <String, Object?>{},
      'hand_state': <String, Object?>{},
      'event_cursor': <String, Object?>{},
    };

    expect(
      () => HoldemStateSnapshot.fromJson(
        malformed,
        eventIdFactory: (_, eventSeq) => 'event-$eventSeq',
        emittedAtFactory: () => 'timestamp',
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects structurally oversized snapshot roots during hydration', () {
    final oversized =
        HoldemStateSnapshot(
          tableState: TableState.initial(
            tableId: 'table_001',
            sessionId: 'session_001',
            protocolVersion: '1.0.0',
          ),
          handState: _handState(),
          eventCursor: _cursor(),
        ).toJson()..addAll(<String, Object?>{
          for (var index = 0; index < 254; index++) 'extra_$index': index,
        });

    expect(
      () => HoldemStateSnapshot.fromJson(
        oversized,
        eventIdFactory: (_, eventSeq) => 'event-$eventSeq',
        emittedAtFactory: () => 'timestamp',
      ),
      throwsA(isA<FormatException>()),
    );
  });
}

HoldemHandState _handState() => HoldemHandState(
  handId: 'hand_001',
  phase: HoldemHandPhase.handIdle,
  bettingRound: HoldemBettingRound.none,
  seats: <HoldemSeatState>[],
  currentActorSeat: 0,
  buttonSeat: 0,
  smallBlindSeat: 0,
  bigBlindSeat: 1,
  currentBetToCall: 0,
  minimumRaiseAmount: 1,
);

HoldemEventCursor _cursor() => HoldemEventCursor(
  protocolVersion: '1.0.0',
  tableId: 'table_001',
  sessionId: 'session_001',
  nextEventSeq: 1,
  previousEventHash: 'genesis',
  actorRef: 'peer_local',
  eventIdFactory: (eventType, eventSeq) => '$eventType-$eventSeq',
  emittedAtFactory: () => '2026-08-10T00:00:00.000Z',
);
