import 'package:meta/meta.dart';

@immutable
class ShowdownSeatInput {
  const ShowdownSeatInput({
    required this.seat,
    required this.holeCards,
    required this.isFolded,
  });

  final int seat;
  final List<String> holeCards;
  final bool isFolded;
}

@immutable
class ShowdownEvaluationInput {
  const ShowdownEvaluationInput({
    required this.boardCards,
    required this.seats,
  });

  final List<String> boardCards;
  final List<ShowdownSeatInput> seats;
}

@immutable
class RankedShowdownResult {
  const RankedShowdownResult({
    required this.seat,
    required this.rankIndex,
    required this.summary,
  });

  final int seat;
  final int rankIndex;
  final String summary;
}

@immutable
class ShowdownEvaluationResult {
  const ShowdownEvaluationResult({
    required this.results,
    this.warnings = const <String>[],
  });

  final List<RankedShowdownResult> results;
  final List<String> warnings;
}
