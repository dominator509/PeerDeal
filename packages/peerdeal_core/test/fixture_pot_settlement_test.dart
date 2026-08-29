import 'dart:io';

import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:test/test.dart';

import 'fixture_loader.dart';

void main() {
  test('loads every checked-in pot fixture through the typed decoder', () {
    final fixtureFiles = _potFixtureDirectory()
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .toList(growable: false);

    expect(fixtureFiles, hasLength(2));
    for (final file in fixtureFiles) {
      final fixture = loadPotFixture(file.uri.pathSegments.last);
      expect(fixture.scenarioId, isNotEmpty, reason: file.path);
      expect(fixture.commitments, isNotEmpty, reason: file.path);
    }
  });

  test('pot fixtures preserve deterministic slices and settlement', () {
    final allIn = loadPotFixture('all_in_side_pot_three_way.json');
    final slices = const SidePotBuilder().build(allIn.commitments);
    expect(
      _sliceTriples(slices),
      allIn.expectedSlices!
          .map(
            (slice) =>
                '${slice.sliceIndex}:${slice.amount}:${slice.contestedBySeatIds.join(',')}',
          )
          .toList(growable: false),
    );

    final uncontested = loadPotFixture('uncontested_folded_dead_money.json');
    final uncontestedSlices = const SidePotBuilder().build(
      uncontested.commitments,
    );
    final expectedWinner = uncontested.expectedWinner!;
    final result = const PotEngine().settle(
      commitments: uncontested.commitments,
      winningSeatIdsBySliceIndex: {
        for (final slice in uncontestedSlices)
          slice.sliceIndex: <String>[expectedWinner],
      },
    );
    expect(result.isBalanced, isTrue);
    expect(result.totalPotAmount, uncontested.expectedTotalPot);
    expect(result.awards, hasLength(1));
    expect(result.awards.single.seatId, expectedWinner);
  });
}

Directory _potFixtureDirectory() {
  final packageLocal = Directory('fixtures/pots');
  if (packageLocal.existsSync()) return packageLocal;
  return Directory('packages/peerdeal_core/fixtures/pots');
}

List<String> _sliceTriples(List<PotSlice> slices) {
  return slices
      .map(
        (slice) =>
            '${slice.sliceIndex}:${slice.amount}:${slice.contestedBySeatIds.join(',')}',
      )
      .toList(growable: false);
}
