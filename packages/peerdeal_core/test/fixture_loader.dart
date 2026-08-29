import 'dart:convert';
import 'dart:io';

import 'package:peerdeal_core/peerdeal_core.dart';

Map<String, dynamic> loadJsonFixture(String name) {
  final file = File('test/fixtures/$name');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

class PotFixture {
  const PotFixture({
    required this.scenarioId,
    required this.commitments,
    this.expectedSlices,
    this.expectedTotalPot,
    this.expectedWinner,
  });

  final String scenarioId;
  final List<PotCommitment> commitments;
  final List<PotFixtureSlice>? expectedSlices;
  final int? expectedTotalPot;
  final String? expectedWinner;
}

class PotFixtureSlice {
  const PotFixtureSlice({
    required this.sliceIndex,
    required this.amount,
    required this.contestedBySeatIds,
  });

  final int sliceIndex;
  final int amount;
  final List<String> contestedBySeatIds;
}

PotFixture loadPotFixture(String name) {
  final file = _resolvePotFixture(name);
  final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  final scenarioId = _requiredString(json, 'scenario_id');
  if (scenarioId.trim().isEmpty || scenarioId != scenarioId.trim()) {
    throw const FormatException('scenario_id must be non-empty and unpadded.');
  }

  final rawCommitments = _requiredList(json, 'commitments');
  if (rawCommitments.isEmpty) {
    throw const FormatException('commitments must not be empty.');
  }
  final commitments = <PotCommitment>[];
  for (final rawCommitment in rawCommitments) {
    final commitment = _asObject(rawCommitment, 'commitment');
    final seatId = _requiredString(commitment, 'seat_id');
    if (seatId.trim().isEmpty || seatId != seatId.trim()) {
      throw const FormatException('commitment seat_id must be non-empty.');
    }
    final committed = _requiredInt(commitment, 'committed');
    if (committed < 0) {
      throw const FormatException('committed must be non-negative.');
    }
    commitments.add(
      PotCommitment(
        seatId: seatId,
        committed: committed,
        isEligibleForShowdown: _requiredBool(commitment, 'eligible'),
        isFolded: _optionalBool(commitment, 'folded') ?? false,
      ),
    );
  }

  final hasExpectedSlices = json.containsKey('expected_slices');
  final hasExpectedTotal = json.containsKey('expected_total_pot');
  final hasExpectedWinner = json.containsKey('expected_winner');
  final hasExpectedSettlement = hasExpectedTotal || hasExpectedWinner;
  if (hasExpectedSlices == hasExpectedSettlement) {
    throw const FormatException(
      'Fixture must define exactly one expected pot shape.',
    );
  }

  if (hasExpectedSlices) {
    final expectedSlices = <PotFixtureSlice>[];
    final rawSlices = _requiredList(json, 'expected_slices');
    final seenSliceIndexes = <int>{};
    for (final rawSlice in rawSlices) {
      final slice = _asObject(rawSlice, 'expected slice');
      final sliceIndex = _requiredInt(slice, 'slice_index');
      final amount = _requiredInt(slice, 'amount');
      if (sliceIndex < 0 || amount < 0 || !seenSliceIndexes.add(sliceIndex)) {
        throw const FormatException('Expected pot slices are invalid.');
      }
      expectedSlices.add(
        PotFixtureSlice(
          sliceIndex: sliceIndex,
          amount: amount,
          contestedBySeatIds: List<String>.unmodifiable(
            _requiredStringList(slice, 'contested_by'),
          ),
        ),
      );
    }
    if (expectedSlices.isEmpty) {
      throw const FormatException('expected_slices must not be empty.');
    }
    return PotFixture(
      scenarioId: scenarioId,
      commitments: List<PotCommitment>.unmodifiable(commitments),
      expectedSlices: List<PotFixtureSlice>.unmodifiable(expectedSlices),
    );
  }

  final expectedTotalPot = _requiredInt(json, 'expected_total_pot');
  if (expectedTotalPot < 0) {
    throw const FormatException('expected_total_pot must be non-negative.');
  }
  final expectedWinner = _requiredString(json, 'expected_winner');
  if (expectedWinner.trim().isEmpty ||
      expectedWinner != expectedWinner.trim()) {
    throw const FormatException(
      'expected_winner must be non-empty and unpadded.',
    );
  }
  return PotFixture(
    scenarioId: scenarioId,
    commitments: List<PotCommitment>.unmodifiable(commitments),
    expectedTotalPot: expectedTotalPot,
    expectedWinner: expectedWinner,
  );
}

File _resolvePotFixture(String name) {
  final packageLocal = File('fixtures/pots/$name');
  if (packageLocal.existsSync()) return packageLocal;
  return File('packages/peerdeal_core/fixtures/pots/$name');
}

Map<String, Object?> _asObject(Object? value, String label) {
  if (value is Map) return Map<String, Object?>.from(value);
  throw FormatException('$label must be an object.');
}

List<Object?> _requiredList(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is List) return List<Object?>.from(value);
  throw FormatException('$key must be an array.');
}

String _requiredString(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is String) return value;
  throw FormatException('$key must be a string.');
}

int _requiredInt(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is int) return value;
  throw FormatException('$key must be an integer.');
}

bool _requiredBool(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is bool) return value;
  throw FormatException('$key must be a boolean.');
}

bool? _optionalBool(Map<String, Object?> map, String key) {
  if (!map.containsKey(key)) return null;
  final value = map[key];
  if (value is bool) return value;
  throw FormatException('$key must be a boolean.');
}

List<String> _requiredStringList(Map<String, Object?> map, String key) {
  final values = _requiredList(map, key);
  if (values.any((value) => value is! String)) {
    throw FormatException('$key must contain only strings.');
  }
  return values.cast<String>();
}
