import '../contracts/showdown_models.dart';
import 'holdem_hand_evaluator.dart';

class HoldemShowdownEvaluator {
  const HoldemShowdownEvaluator({this.evaluator = const HoldemHandEvaluator()});

  final HoldemHandEvaluator evaluator;

  ShowdownEvaluationResult evaluate(ShowdownEvaluationInput input) {
    final warnings = <String>[];
    if (input.boardCards.length != 5) {
      warnings.add('ERR_HOLDEM_SHOWDOWN_BOARD_CARD_COUNT');
    }

    final ranked = input.seats.where((seat) => !seat.isFolded).toList()
      ..sort((a, b) => a.seat.compareTo(b.seat));
    if (ranked.any((seat) => seat.holeCards.length != 2)) {
      warnings.add('ERR_HOLDEM_SHOWDOWN_HOLE_CARD_COUNT');
    }

    final activeCards = <String>[
      ...input.boardCards,
      for (final seat in ranked) ...seat.holeCards,
    ];
    if (activeCards.any((card) => !_isCardIdentity(card))) {
      warnings.add('ERR_HOLDEM_SHOWDOWN_CARD_FORMAT');
    }

    if (activeCards.toSet().length != activeCards.length) {
      warnings.add('ERR_HOLDEM_SHOWDOWN_DUPLICATE_CARD');
    }

    if (warnings.isNotEmpty) {
      return ShowdownEvaluationResult(
        results: const <RankedShowdownResult>[],
        warnings: warnings,
      );
    }

    final evaluated =
        [
          for (final seat in ranked)
            _EvaluatedShowdownSeat(
              seat: seat.seat,
              hand: evaluator.evaluateBest(<String>[
                ...input.boardCards,
                ...seat.holeCards,
              ]),
            ),
        ]..sort((a, b) {
          final handComparison = b.hand.compareTo(a.hand);
          if (handComparison != 0) {
            return handComparison;
          }
          return a.seat.compareTo(b.seat);
        });

    return ShowdownEvaluationResult(
      results: [
        for (var i = 0; i < evaluated.length; i++)
          RankedShowdownResult(
            seat: evaluated[i].seat,
            rankIndex: _rankIndexAt(evaluated, i),
            summary: evaluated[i].hand.summary,
          ),
      ],
      warnings: warnings,
    );
  }
}

class _EvaluatedShowdownSeat {
  const _EvaluatedShowdownSeat({required this.seat, required this.hand});

  final int seat;
  final HoldemHandEvaluation hand;
}

int _rankIndexAt(List<_EvaluatedShowdownSeat> seats, int index) {
  var rankIndex = 0;
  for (var i = 1; i <= index; i++) {
    if (seats[i].hand.compareTo(seats[i - 1].hand) != 0) {
      rankIndex++;
    }
  }
  return rankIndex;
}

bool _isCardIdentity(String card) {
  if (card.length != 2) {
    return false;
  }

  const ranks = <String>{
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    'T',
    'J',
    'Q',
    'K',
    'A',
  };
  const suits = <String>{'c', 'd', 'h', 's'};
  return ranks.contains(card[0]) && suits.contains(card[1]);
}
