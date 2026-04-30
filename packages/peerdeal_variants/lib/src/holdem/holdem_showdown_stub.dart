import '../contracts/showdown_models.dart';

class HoldemShowdownStub {
  const HoldemShowdownStub();

  ShowdownEvaluationResult evaluate(ShowdownEvaluationInput input) {
    final ranked = input.seats
        .where((seat) => !seat.isFolded)
        .toList()
      ..sort((a, b) => a.seat.compareTo(b.seat));

    return ShowdownEvaluationResult(
      results: [
        for (var i = 0; i < ranked.length; i++)
          RankedShowdownResult(
            seat: ranked[i].seat,
            rankIndex: i,
            summary: 'Stub evaluation only — replace with real evaluator.',
          ),
      ],
      warnings: const <String>[
        'Showdown evaluator is a starter stub only.',
      ],
    );
  }
}
