import 'dart:convert';
import 'dart:io';

import 'package:peerdeal_variants/peerdeal_variants.dart';
import 'package:test/test.dart';

void main() {
  test(
    'loads the opening-hand fixture through strict persisted state parsing',
    () {
      final fixture = _fixtureJson('holdem_opening_hand.json');

      expect(fixture['variant_id'], 'holdem_nlhe');
      expect(fixture['mode_type'], 'open_table');

      final state = HoldemHandState.fromJson(fixture);

      expect(state.handId, 'hand_001');
      expect(state.phase, HoldemHandPhase.bettingPreflop);
      expect(state.bettingRound, HoldemBettingRound.preflop);
      expect(state.currentActorSeat, 2);
      expect(state.buttonSeat, 1);
      expect(state.smallBlindSeat, 2);
      expect(state.bigBlindSeat, 3);
      expect(state.currentBetToCall, 100);
      expect(state.minimumRaiseAmount, 100);
      expect(state.pot, 150);
      expect(state.seats.map((seat) => seat.seat).toList(), <int>[1, 2, 3]);
      expect(
        state.seats.map((seat) => seat.committedThisHand).toList(),
        <int>[0, 50, 100],
      );
      expect(state.boardCards, isEmpty);
      expect(state.actedSeatsThisRound, isEmpty);
      expect(state.lastAggressorSeat, isNull);
      expect(state.lastActionSummary, isNull);
    },
  );

  test('loads the all-in edge fixture through strict persisted parsing', () {
    final state = HoldemHandState.fromJson(
      _fixtureJson('holdem_all_in_edge.json'),
    );

    expect(state.phase, HoldemHandPhase.handComplete);
    expect(state.bettingRound, HoldemBettingRound.river);
    expect(state.boardCards, hasLength(5));
    expect(
      state.seats.every((seat) => seat.allIn && seat.stack == 0),
      isTrue,
    );
  });

  test('every non-invalid Holdem fixture is accepted by the typed parser', () {
    final fixtures = _fixtureFiles()
        .where((file) => !file.uri.pathSegments.last.startsWith('invalid_'))
        .toList();

    expect(fixtures, isNotEmpty);
    for (final fixture in fixtures) {
      expect(
        () => HoldemHandState.fromJson(
          _fixtureJson(fixture.uri.pathSegments.last),
        ),
        returnsNormally,
        reason: fixture.path,
      );
    }
  });

  test('every invalid Holdem fixture is rejected by the typed parser', () {
    final fixtures = _fixtureFiles()
        .where((file) => file.uri.pathSegments.last.startsWith('invalid_'))
        .toList();

    expect(fixtures, isNotEmpty);
    for (final fixture in fixtures) {
      expect(
        () => HoldemHandState.fromJson(
          _fixtureJson(fixture.uri.pathSegments.last),
        ),
        throwsA(isA<FormatException>()),
        reason: fixture.path,
      );
    }
  });

  test('round-trips HoldemHandState through JSON without losing fields', () {
    final state = HoldemHandState(
      handId: 'hand_001',
      phase: HoldemHandPhase.bettingFlop,
      bettingRound: HoldemBettingRound.flop,
      seats: <HoldemSeatState>[
        HoldemSeatState(
          seat: 0,
          stack: 900,
          inHand: true,
          folded: false,
          allIn: false,
          committedThisRound: 100,
          committedThisHand: 100,
        ),
        HoldemSeatState(
          seat: 1,
          stack: 0,
          inHand: true,
          folded: false,
          allIn: true,
          committedThisRound: 1000,
          committedThisHand: 1000,
        ),
      ],
      currentActorSeat: 0,
      buttonSeat: 1,
      smallBlindSeat: 0,
      bigBlindSeat: 1,
      currentBetToCall: 100,
      minimumRaiseAmount: 200,
      boardCards: <String>['Ah', 'Kd', '7c'],
      actedSeatsThisRound: <int>[1],
      pot: 1100,
      lastAggressorSeat: 1,
      lastActionSummary: 'Seat 1 called.',
    );

    final persisted = Map<String, Object?>.from(
      jsonDecode(jsonEncode(state.toJson())) as Map,
    );
    final restored = HoldemHandState.fromJson(persisted);

    expect(restored.toJson(), state.toJson());
  });

  test('rejects unknown phases and malformed seat fields', () {
    final unknownPhase = _stateJson()..['phase'] = 'unknown_phase';

    expect(
      () => HoldemHandState.fromJson(unknownPhase),
      throwsA(isA<FormatException>()),
    );

    final malformedSeat = _stateJson()
      ..['seats'] = <Object?>[
        <String, Object?>{
          ...const <String, Object?>{
            'seat': 0,
            'stack': 100,
            'in_hand': true,
            'folded': false,
            'all_in': false,
            'committed_this_round': 0,
            'committed_this_hand': 'zero',
          },
        },
      ];

    expect(
      () => HoldemHandState.fromJson(malformedSeat),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects malformed collection and nested object shapes', () {
    final malformedBoard = _stateJson()..['board_cards'] = <Object?>['Ah', 7];
    expect(
      () => HoldemHandState.fromJson(malformedBoard),
      throwsA(isA<FormatException>()),
    );

    final malformedSeatObject = _stateJson()
      ..['seats'] = <Object?>[
        <Object?, Object?>{1: 'not an object key'},
      ];
    expect(
      () => HoldemHandState.fromJson(malformedSeatObject),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects impossible persisted monetary and seat state', () {
    final cases = <Map<String, Object?>>[
      _stateJson()..['pot'] = -1,
      _stateJson()..['current_bet_to_call'] = -1,
      _stateJson()..['minimum_raise_amount'] = 0,
      _stateJson()
        ..['seats'] = <Object?>[
          <String, Object?>{..._seatJson(), 'stack': -1},
        ],
      _stateJson()
        ..['seats'] = <Object?>[
          <String, Object?>{..._seatJson(), 'all_in': true, 'stack': 1},
        ],
      _stateJson()..['seats'] = <Object?>[_seatJson(), _seatJson()],
    ];

    for (final state in cases) {
      expect(
        () => HoldemHandState.fromJson(state),
        throwsA(isA<FormatException>()),
      );
    }
  });

  test('rejects unsafe and duplicate persisted board state', () {
    final unsafeHandId = _stateJson()..['hand_id'] = ' hand_001';
    final unsafeSummary = _stateJson()..['last_action_summary'] = 'bad\ntext';
    final invalidBoard = _stateJson()..['board_cards'] = <Object?>['1x'];
    final duplicateBoard = _stateJson()
      ..['board_cards'] = <Object?>['Ah', 'Ah'];

    for (final state in <Map<String, Object?>>[
      unsafeHandId,
      unsafeSummary,
      invalidBoard,
      duplicateBoard,
    ]) {
      expect(
        () => HoldemHandState.fromJson(state),
        throwsA(isA<FormatException>()),
      );
    }
  });

  test('direct state validation rejects oversized and C1 identity text', () {
    final oversizedHandId = String.fromCharCodes(
      List<int>.filled(HoldemInputLimits.defaultMaxTextBytes + 1, 0x78),
    );
    final states = <HoldemHandState>[
      HoldemHandState(
        handId: String.fromCharCode(0xd800),
        phase: HoldemHandPhase.handIdle,
        bettingRound: HoldemBettingRound.none,
        seats: const <HoldemSeatState>[],
        currentActorSeat: 0,
        buttonSeat: 0,
        smallBlindSeat: 0,
        bigBlindSeat: 0,
        currentBetToCall: 0,
        boardCards: const <String>[],
        minimumRaiseAmount: 1,
      ),
      HoldemHandState(
        handId: oversizedHandId,
        phase: HoldemHandPhase.handIdle,
        bettingRound: HoldemBettingRound.none,
        seats: const <HoldemSeatState>[],
        currentActorSeat: 0,
        buttonSeat: 0,
        smallBlindSeat: 0,
        bigBlindSeat: 1,
        currentBetToCall: 0,
        minimumRaiseAmount: 1,
      ),
      HoldemHandState(
        handId: 'hand_001\u0085',
        phase: HoldemHandPhase.handIdle,
        bettingRound: HoldemBettingRound.none,
        seats: const <HoldemSeatState>[],
        currentActorSeat: 0,
        buttonSeat: 0,
        smallBlindSeat: 0,
        bigBlindSeat: 1,
        currentBetToCall: 0,
        minimumRaiseAmount: 1,
      ),
    ];

    for (final state in states) {
      expect(state.validate().reasonCode, 'ERR_HOLDEM_STATE_HAND_ID_INVALID');
    }
  });

  test(
    'rejects structurally oversized Holdem collections during hydration',
    () {
      final oversizedSeats = _stateJson()
        ..['seats'] = List<Object?>.generate(
          257,
          (_) => <String, Object?>{
            'seat': 0,
            'stack': 100,
            'in_hand': true,
            'folded': false,
            'all_in': false,
            'committed_this_round': 0,
            'committed_this_hand': 0,
          },
        );

      expect(
        () => HoldemHandState.fromJson(oversizedSeats),
        throwsA(isA<FormatException>()),
      );
    },
  );
}

Map<String, Object?> _stateJson() => <String, Object?>{
  'hand_id': 'hand_001',
  'phase': HoldemHandPhase.handIdle.name,
  'betting_round': HoldemBettingRound.none.name,
  'seats': <Object?>[],
  'current_actor_seat': 0,
  'button_seat': 0,
  'small_blind_seat': 0,
  'big_blind_seat': 1,
  'current_bet_to_call': 0,
  'minimum_raise_amount': 1,
  'board_cards': <Object?>[],
  'acted_seats_this_round': <Object?>[],
  'pot': 0,
  'last_aggressor_seat': null,
  'last_action_summary': null,
};

Map<String, Object?> _fixtureJson(String fileName) =>
    Map<String, Object?>.from(
      jsonDecode(File('test/fixtures/$fileName').readAsStringSync()) as Map,
    );

List<File> _fixtureFiles() => Directory('test/fixtures')
    .listSync()
    .whereType<File>()
    .where((file) => file.path.endsWith('.json'))
    .toList(growable: false);

Map<String, Object?> _seatJson() => <String, Object?>{
  'seat': 0,
  'stack': 100,
  'in_hand': true,
  'folded': false,
  'all_in': false,
  'committed_this_round': 0,
  'committed_this_hand': 0,
};
