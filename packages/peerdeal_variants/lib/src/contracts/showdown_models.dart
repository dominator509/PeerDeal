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
class ShowdownWinnerGroup {
  const ShowdownWinnerGroup({required this.rankIndex, required this.seats});

  final int rankIndex;
  final List<int> seats;
}

@immutable
class ShowdownEvaluationResult {
  const ShowdownEvaluationResult({
    required this.results,
    this.warnings = const <String>[],
  });

  final List<RankedShowdownResult> results;
  final List<String> warnings;

  List<ShowdownWinnerGroup> get winnerGroups {
    if (warnings.isNotEmpty || results.isEmpty) {
      return const <ShowdownWinnerGroup>[];
    }

    final seatsByRank = <int, List<int>>{};
    for (final result in results) {
      seatsByRank.putIfAbsent(result.rankIndex, () => <int>[]).add(result.seat);
    }

    final rankIndexes = seatsByRank.keys.toList()..sort();
    return [
      for (final rankIndex in rankIndexes)
        ShowdownWinnerGroup(
          rankIndex: rankIndex,
          seats: seatsByRank[rankIndex]!..sort(),
        ),
    ];
  }
}
