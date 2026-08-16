import 'package:meta/meta.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import 'holdem_betting_round.dart';
import 'holdem_hand_phase.dart';

@immutable
class HoldemSeatState {
  const HoldemSeatState({
    required this.seat,
    required this.stack,
    required this.inHand,
    required this.folded,
    required this.allIn,
    this.committedThisRound = 0,
    this.committedThisHand = 0,
  });

  factory HoldemSeatState.fromJson(Map<String, Object?> json) {
    canonicalJsonEncode(json);
    final state = HoldemSeatState(
      seat: _requiredInt(json, 'seat'),
      stack: _requiredInt(json, 'stack'),
      inHand: _requiredBool(json, 'in_hand'),
      folded: _requiredBool(json, 'folded'),
      allIn: _requiredBool(json, 'all_in'),
      committedThisRound: _requiredInt(json, 'committed_this_round'),
      committedThisHand: _requiredInt(json, 'committed_this_hand'),
    );
    if (state.seat < 0) {
      throw const FormatException('Holdem seat id cannot be negative.');
    }
    if (state.stack < 0 ||
        state.committedThisRound < 0 ||
        state.committedThisHand < 0) {
      throw const FormatException('Holdem monetary state cannot be negative.');
    }
    if (state.committedThisRound > state.committedThisHand) {
      throw const FormatException(
        'Holdem round commitment cannot exceed hand commitment.',
      );
    }
    if (state.allIn && state.stack != 0) {
      throw const FormatException(
        'Holdem all-in state must have zero remaining stack.',
      );
    }
    return state;
  }

  final int seat;
  final int stack;
  final bool inHand;
  final bool folded;
  final bool allIn;
  final int committedThisRound;
  final int committedThisHand;

  Map<String, Object?> toJson() => <String, Object?>{
    'seat': seat,
    'stack': stack,
    'in_hand': inHand,
    'folded': folded,
    'all_in': allIn,
    'committed_this_round': committedThisRound,
    'committed_this_hand': committedThisHand,
  };

  HoldemSeatState copyWith({
    int? stack,
    bool? inHand,
    bool? folded,
    bool? allIn,
    int? committedThisRound,
    int? committedThisHand,
  }) {
    return HoldemSeatState(
      seat: seat,
      stack: stack ?? this.stack,
      inHand: inHand ?? this.inHand,
      folded: folded ?? this.folded,
      allIn: allIn ?? this.allIn,
      committedThisRound: committedThisRound ?? this.committedThisRound,
      committedThisHand: committedThisHand ?? this.committedThisHand,
    );
  }
}

@immutable
class HoldemHandState {
  HoldemHandState({
    required this.handId,
    required this.phase,
    required this.bettingRound,
    required List<HoldemSeatState> seats,
    required this.currentActorSeat,
    required this.buttonSeat,
    required this.smallBlindSeat,
    required this.bigBlindSeat,
    required this.currentBetToCall,
    required this.minimumRaiseAmount,
    List<String> boardCards = const <String>[],
    List<int> actedSeatsThisRound = const <int>[],
    this.pot = 0,
    this.lastAggressorSeat,
    this.lastActionSummary,
  }) : seats = List<HoldemSeatState>.unmodifiable(seats),
       boardCards = List<String>.unmodifiable(boardCards),
       actedSeatsThisRound = List<int>.unmodifiable(actedSeatsThisRound);

  factory HoldemHandState.fromJson(Map<String, Object?> json) {
    canonicalJsonEncode(json);
    final seats = _requiredList(json, 'seats');
    final state = HoldemHandState(
      handId: _requiredString(json, 'hand_id'),
      phase: _enumByName(HoldemHandPhase.values, json['phase'], 'phase'),
      bettingRound: _enumByName(
        HoldemBettingRound.values,
        json['betting_round'],
        'betting_round',
      ),
      seats: List<HoldemSeatState>.unmodifiable(
        seats.map(
          (seat) =>
              HoldemSeatState.fromJson(_requiredObject(seat, 'seats entry')),
        ),
      ),
      currentActorSeat: _requiredInt(json, 'current_actor_seat'),
      buttonSeat: _requiredInt(json, 'button_seat'),
      smallBlindSeat: _requiredInt(json, 'small_blind_seat'),
      bigBlindSeat: _requiredInt(json, 'big_blind_seat'),
      currentBetToCall: _requiredInt(json, 'current_bet_to_call'),
      minimumRaiseAmount: _requiredInt(json, 'minimum_raise_amount'),
      boardCards: List<String>.unmodifiable(
        _requiredStringList(json, 'board_cards'),
      ),
      actedSeatsThisRound: List<int>.unmodifiable(
        _requiredIntList(json, 'acted_seats_this_round'),
      ),
      pot: _requiredInt(json, 'pot'),
      lastAggressorSeat: _nullableInt(json, 'last_aggressor_seat'),
      lastActionSummary: _nullableString(json, 'last_action_summary'),
    );
    _validatePersistedState(state);
    return state;
  }

  final String handId;
  final HoldemHandPhase phase;
  final HoldemBettingRound bettingRound;
  final List<HoldemSeatState> seats;
  final int currentActorSeat;
  final int buttonSeat;
  final int smallBlindSeat;
  final int bigBlindSeat;
  final int currentBetToCall;
  final int minimumRaiseAmount;
  final List<String> boardCards;
  final List<int> actedSeatsThisRound;
  final int pot;
  final int? lastAggressorSeat;
  final String? lastActionSummary;

  Map<String, Object?> toJson() => <String, Object?>{
    'hand_id': handId,
    'phase': phase.name,
    'betting_round': bettingRound.name,
    'seats': seats.map((seat) => seat.toJson()).toList(growable: false),
    'current_actor_seat': currentActorSeat,
    'button_seat': buttonSeat,
    'small_blind_seat': smallBlindSeat,
    'big_blind_seat': bigBlindSeat,
    'current_bet_to_call': currentBetToCall,
    'minimum_raise_amount': minimumRaiseAmount,
    'board_cards': List<String>.from(boardCards),
    'acted_seats_this_round': List<int>.from(actedSeatsThisRound),
    'pot': pot,
    'last_aggressor_seat': lastAggressorSeat,
    'last_action_summary': lastActionSummary,
  };

  HoldemSeatState? findSeat(int seat) {
    for (final entry in seats) {
      if (entry.seat == seat) {
        return entry;
      }
    }
    return null;
  }

  HoldemHandState copyWith({
    HoldemHandPhase? phase,
    HoldemBettingRound? bettingRound,
    List<HoldemSeatState>? seats,
    int? currentActorSeat,
    int? currentBetToCall,
    int? minimumRaiseAmount,
    List<String>? boardCards,
    List<int>? actedSeatsThisRound,
    int? pot,
    int? lastAggressorSeat,
    String? lastActionSummary,
  }) {
    return HoldemHandState(
      handId: handId,
      phase: phase ?? this.phase,
      bettingRound: bettingRound ?? this.bettingRound,
      seats: seats ?? this.seats,
      currentActorSeat: currentActorSeat ?? this.currentActorSeat,
      buttonSeat: buttonSeat,
      smallBlindSeat: smallBlindSeat,
      bigBlindSeat: bigBlindSeat,
      currentBetToCall: currentBetToCall ?? this.currentBetToCall,
      minimumRaiseAmount: minimumRaiseAmount ?? this.minimumRaiseAmount,
      boardCards: boardCards ?? this.boardCards,
      actedSeatsThisRound: actedSeatsThisRound ?? this.actedSeatsThisRound,
      pot: pot ?? this.pot,
      lastAggressorSeat: lastAggressorSeat ?? this.lastAggressorSeat,
      lastActionSummary: lastActionSummary ?? this.lastActionSummary,
    );
  }
}

void _validatePersistedState(HoldemHandState state) {
  if (!_isSafeText(state.handId)) {
    throw const FormatException('Holdem hand id is invalid.');
  }
  if (state.currentBetToCall < 0 ||
      state.minimumRaiseAmount <= 0 ||
      state.pot < 0) {
    throw const FormatException('Holdem monetary state is invalid.');
  }

  final seatIds = <int>{};
  for (final seat in state.seats) {
    if (!seatIds.add(seat.seat)) {
      throw const FormatException('Holdem seat ids must be unique.');
    }
  }

  final actedSeatIds = <int>{};
  for (final seat in state.actedSeatsThisRound) {
    if (seat < 0 || !actedSeatIds.add(seat)) {
      throw const FormatException(
        'Holdem acted seat ids must be unique and non-negative.',
      );
    }
  }

  final boardCards = <String>{};
  for (final card in state.boardCards) {
    if (!_isSafeText(card) || !boardCards.add(card)) {
      throw const FormatException(
        'Holdem board cards must be unique and safe.',
      );
    }
  }
  if (state.boardCards.length > 5) {
    throw const FormatException(
      'Holdem board cannot contain more than five cards.',
    );
  }

  if (state.lastAggressorSeat != null && state.lastAggressorSeat! < 0) {
    throw const FormatException('Holdem aggressor seat cannot be negative.');
  }
  if (state.lastActionSummary != null &&
      !_isSafeText(state.lastActionSummary!)) {
    throw const FormatException('Holdem action summary is invalid.');
  }
}

bool _isSafeText(String value) {
  return value.trim().isNotEmpty &&
      value.trim() == value &&
      value.codeUnits.every(
        (unit) => unit >= 0x20 && !(unit >= 0x7f && unit <= 0x9f),
      );
}

Map<String, Object?> _requiredObject(Object? value, String key) {
  if (value is! Map<Object?, Object?>) {
    throw FormatException('Holdem $key must be an object.');
  }
  final entries = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw FormatException('Holdem $key contains a non-string key.');
    }
    entries[entry.key as String] = entry.value;
  }
  return Map<String, Object?>.unmodifiable(entries);
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('Holdem $key must be a string.');
  }
  return value;
}

String? _nullableString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value != null && value is! String) {
    throw FormatException('Holdem $key must be a string or null.');
  }
  return value as String?;
}

int _requiredInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('Holdem $key must be an integer.');
  }
  return value;
}

int? _nullableInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value != null && value is! int) {
    throw FormatException('Holdem $key must be an integer or null.');
  }
  return value as int?;
}

bool _requiredBool(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! bool) {
    throw FormatException('Holdem $key must be a boolean.');
  }
  return value;
}

List<Object?> _requiredList(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! List) {
    throw FormatException('Holdem $key must be an array.');
  }
  return List<Object?>.from(value);
}

List<String> _requiredStringList(Map<String, Object?> json, String key) {
  final values = _requiredList(json, key);
  final result = <String>[];
  for (final value in values) {
    if (value is! String) {
      throw FormatException('Holdem $key must contain only strings.');
    }
    result.add(value);
  }
  return result;
}

List<int> _requiredIntList(Map<String, Object?> json, String key) {
  final values = _requiredList(json, key);
  final result = <int>[];
  for (final value in values) {
    if (value is! int) {
      throw FormatException('Holdem $key must contain only integers.');
    }
    result.add(value);
  }
  return result;
}

T _enumByName<T extends Enum>(Iterable<T> values, Object? value, String key) {
  if (value is! String) {
    throw FormatException('Holdem $key must be a string.');
  }
  try {
    return values.byName(value);
  } on ArgumentError {
    throw FormatException('Unknown Holdem $key: $value.');
  }
}
