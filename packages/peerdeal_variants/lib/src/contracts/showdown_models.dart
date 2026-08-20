import 'package:meta/meta.dart';

import '../holdem/holdem_input_limits.dart';

@immutable
class ShowdownSeatInput {
  ShowdownSeatInput({
    required this.seat,
    required List<String> holeCards,
    required this.isFolded,
  }) : holeCards = List<String>.unmodifiable(holeCards);

  final int seat;
  final List<String> holeCards;
  final bool isFolded;
}

@immutable
class ShowdownEvaluationInput {
  ShowdownEvaluationInput({
    required List<String> boardCards,
    required List<ShowdownSeatInput> seats,
  }) : boardCards = List<String>.unmodifiable(boardCards),
       seats = List<ShowdownSeatInput>.unmodifiable(seats);

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
  ShowdownWinnerGroup({required this.rankIndex, required List<int> seats})
    : seats = List<int>.unmodifiable(seats);

  final int rankIndex;
  final List<int> seats;
}

@immutable
class ShowdownSliceWinnerProjection {
  ShowdownSliceWinnerProjection({
    required Map<int, List<String>> winningSeatIdsBySliceIndex,
    required List<int> unawardableSliceIndexes,
    List<String> warnings = const <String>[],
  }) : winningSeatIdsBySliceIndex = _freezeStringListMap(
         winningSeatIdsBySliceIndex,
       ),
       unawardableSliceIndexes = List<int>.unmodifiable(
         unawardableSliceIndexes,
       ),
       warnings = List<String>.unmodifiable(warnings);

  final Map<int, List<String>> winningSeatIdsBySliceIndex;
  final List<int> unawardableSliceIndexes;
  final List<String> warnings;

  bool get hasUnawardableSlices =>
      unawardableSliceIndexes.isNotEmpty || warnings.isNotEmpty;
}

@immutable
class ShowdownEvaluationResult {
  ShowdownEvaluationResult({
    required List<RankedShowdownResult> results,
    List<String> warnings = const <String>[],
  }) : results = List<RankedShowdownResult>.unmodifiable(results),
       warnings = List<String>.unmodifiable(warnings);

  final List<RankedShowdownResult> results;
  final List<String> warnings;

  List<ShowdownWinnerGroup> get winnerGroups {
    if (warnings.isNotEmpty ||
        results.isEmpty ||
        _resultInputWarning() != null) {
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
    if (warnings.isNotEmpty ||
        results.isEmpty ||
        _resultInputWarning() != null ||
        eligibleSeatsBySliceIndex.length >
            HoldemInputLimits.defaultMaxPotSlices ||
        eligibleSeatsBySliceIndex.values.any(
          (seats) => seats.length > HoldemInputLimits.defaultMaxSeatIdsPerSlice,
        )) {
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
    final warning = _projectionInputWarning(contestedSeatIdsBySliceIndex);
    if (warning != null) {
      return ShowdownSliceWinnerProjection(
        winningSeatIdsBySliceIndex: const <int, List<String>>{},
        unawardableSliceIndexes: const <int>[],
        warnings: <String>[warning],
      );
    }

    final winnersBySlice = <int, List<String>>{};
    final unawardableSliceIndexes = <int>[];
    final sliceIndexes = contestedSeatIdsBySliceIndex.keys.toList()..sort();
    for (final sliceIndex in sliceIndexes) {
      final contestedSeatIds =
          contestedSeatIdsBySliceIndex[sliceIndex] ?? const <String>[];
      if (contestedSeatIds.isEmpty) {
        unawardableSliceIndexes.add(sliceIndex);
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

  String? _projectionInputWarning(
    Map<int, List<String>> contestedSeatIdsBySliceIndex,
  ) {
    final resultWarning = _resultInputWarning();
    if (resultWarning != null) {
      return resultWarning;
    }
    if (contestedSeatIdsBySliceIndex.length >
        HoldemInputLimits.defaultMaxPotSlices) {
      return 'ERR_HOLDEM_SHOWDOWN_SLICE_COUNT';
    }
    if (contestedSeatIdsBySliceIndex.values.any(
      (seatIds) => seatIds.length > HoldemInputLimits.defaultMaxSeatIdsPerSlice,
    )) {
      return 'ERR_HOLDEM_SHOWDOWN_SLICE_SEAT_COUNT';
    }
    return null;
  }

  String? _resultInputWarning() {
    if (results.length > HoldemInputLimits.defaultMaxShowdownResults) {
      return 'ERR_HOLDEM_SHOWDOWN_RESULT_COUNT';
    }

    final seats = <int>{};
    for (final result in results) {
      if (result.seat < 0) {
        return 'ERR_HOLDEM_SHOWDOWN_SEAT_ID_INVALID';
      }
      if (!seats.add(result.seat)) {
        return 'ERR_HOLDEM_SHOWDOWN_SEAT_ID_DUPLICATE';
      }
      if (result.rankIndex < 0) {
        return 'ERR_HOLDEM_SHOWDOWN_RANK_INDEX_INVALID';
      }
      if (!_isSafeText(result.summary)) {
        return 'ERR_HOLDEM_SHOWDOWN_SUMMARY_INVALID';
      }
    }
    return null;
  }
}

bool _isSafeText(String value) {
  return value.trim().isNotEmpty &&
      value.trim() == value &&
      HoldemInputLimits.isWithinTextLimit(value) &&
      value.codeUnits.every(
        (unit) => unit >= 0x20 && !(unit >= 0x7f && unit <= 0x9f),
      );
}

String _defaultSeatIdFor(int seat) => seat.toString();

Map<int, List<String>> _freezeStringListMap(Map<int, List<String>> source) {
  return Map<int, List<String>>.unmodifiable(<int, List<String>>{
    for (final entry in source.entries)
      entry.key: List<String>.unmodifiable(entry.value),
  });
}
