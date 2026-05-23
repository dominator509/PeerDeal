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
class ShowdownSliceWinnerProjection {
  const ShowdownSliceWinnerProjection({
    required this.winningSeatIdsBySliceIndex,
    required this.unawardableSliceIndexes,
  });

  final Map<int, List<String>> winningSeatIdsBySliceIndex;
  final List<int> unawardableSliceIndexes;

  bool get hasUnawardableSlices => unawardableSliceIndexes.isNotEmpty;
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

  Map<int, List<String>> winningSeatIdsBySliceIndex({
    required Map<int, Set<int>> eligibleSeatsBySliceIndex,
    String Function(int seat) seatIdFor = _defaultSeatIdFor,
  }) {
    if (warnings.isNotEmpty || results.isEmpty) {
      return const <int, List<String>>{};
    }

    final winnersBySlice = <int, List<String>>{};
    final sliceIndexes = eligibleSeatsBySliceIndex.keys.toList()..sort();
    for (final sliceIndex in sliceIndexes) {
      final eligibleSeats = eligibleSeatsBySliceIndex[sliceIndex];
      if (eligibleSeats == null || eligibleSeats.isEmpty) {
        continue;
      }

      for (final group in winnerGroups) {
        final winners =
            group.seats.where(eligibleSeats.contains).map(seatIdFor).toList()
              ..sort();
        if (winners.isNotEmpty) {
          winnersBySlice[sliceIndex] = winners;
          break;
        }
      }
    }

    return winnersBySlice;
  }

  Map<int, List<String>> winningContestedSeatIdsBySliceIndex({
    required Map<int, List<String>> contestedSeatIdsBySliceIndex,
    required int? Function(String seatId) seatForId,
  }) {
    return projectContestedSeatIdsBySliceIndex(
      contestedSeatIdsBySliceIndex: contestedSeatIdsBySliceIndex,
      seatForId: seatForId,
    ).winningSeatIdsBySliceIndex;
  }

  ShowdownSliceWinnerProjection projectContestedSeatIdsBySliceIndex({
    required Map<int, List<String>> contestedSeatIdsBySliceIndex,
    required int? Function(String seatId) seatForId,
  }) {
    final winnersBySlice = <int, List<String>>{};
    final unawardableSliceIndexes = <int>[];
    final sliceIndexes = contestedSeatIdsBySliceIndex.keys.toList()..sort();
    for (final sliceIndex in sliceIndexes) {
      final contestedSeatIds =
          contestedSeatIdsBySliceIndex[sliceIndex] ?? const <String>[];
      if (contestedSeatIds.isEmpty) {
        continue;
      }

      if (warnings.isNotEmpty || results.isEmpty) {
        unawardableSliceIndexes.add(sliceIndex);
        continue;
      }

      final idsBySeat = <int, List<String>>{};
      for (final seatId in contestedSeatIds) {
        final seat = seatForId(seatId);
        if (seat == null) {
          continue;
        }
        idsBySeat.putIfAbsent(seat, () => <String>[]).add(seatId);
      }

      if (idsBySeat.isEmpty) {
        unawardableSliceIndexes.add(sliceIndex);
        continue;
      }

      var isAwardable = false;
      for (final group in winnerGroups) {
        final winners = <String>[
          for (final seat in group.seats)
            ...idsBySeat[seat] ?? const <String>[],
        ]..sort();
        if (winners.isNotEmpty) {
          winnersBySlice[sliceIndex] = winners;
          isAwardable = true;
          break;
        }
      }

      if (!isAwardable) {
        unawardableSliceIndexes.add(sliceIndex);
      }
    }

    return ShowdownSliceWinnerProjection(
      winningSeatIdsBySliceIndex: winnersBySlice,
      unawardableSliceIndexes: unawardableSliceIndexes,
    );
  }
}

String _defaultSeatIdFor(int seat) => seat.toString();
