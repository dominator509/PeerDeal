import '../contracts/showdown_models.dart';

class HoldemShowdownStub {
  const HoldemShowdownStub();

  ShowdownEvaluationResult evaluate(ShowdownEvaluationInput input) {
    final warnings = <String>['Showdown evaluator is a starter stub only.'];
    if (input.boardCards.length != 5) {
      warnings.add('ERR_HOLDEM_SHOWDOWN_BOARD_CARD_COUNT');
    }

    final ranked = input.seats.where((seat) => !seat.isFolded).toList()
      ..sort((a, b) => a.seat.compareTo(b.seat));
    if (ranked.any((seat) => seat.holeCards.length != 2)) {
      warnings.add('ERR_HOLDEM_SHOWDOWN_HOLE_CARD_COUNT');
    }

    if (warnings.length > 1) {
      return ShowdownEvaluationResult(
        results: const <RankedShowdownResult>[],
        warnings: warnings,
      );
    }

    return ShowdownEvaluationResult(
      results: [
        for (var i = 0; i < ranked.length; i++)
          RankedShowdownResult(
            seat: ranked[i].seat,
            rankIndex: i,
            summary: 'Stub evaluation only - replace with real evaluator.',
          ),
      ],
      warnings: warnings,
    );
  }
}
