import 'dart:convert';

import 'package:peerdeal_variants/peerdeal_variants.dart';
import 'package:test/test.dart';

void main() {
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

Map<String, Object?> _seatJson() => <String, Object?>{
  'seat': 0,
  'stack': 100,
  'in_hand': true,
  'folded': false,
  'all_in': false,
  'committed_this_round': 0,
  'committed_this_hand': 0,
};
