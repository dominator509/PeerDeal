class HoldemHandEvaluation {
  HoldemHandEvaluation({
    required this.category,
    required this.categoryRank,
    required List<int> tiebreakers,
  }) : tiebreakers = List<int>.unmodifiable(tiebreakers);

  final String category;
  final int categoryRank;
  final List<int> tiebreakers;

  int compareTo(HoldemHandEvaluation other) {
    final categoryComparison = categoryRank.compareTo(other.categoryRank);
    if (categoryComparison != 0) {
      return categoryComparison;
    }

    for (
      var i = 0;
      i < tiebreakers.length && i < other.tiebreakers.length;
      i++
    ) {
      final comparison = tiebreakers[i].compareTo(other.tiebreakers[i]);
      if (comparison != 0) {
        return comparison;
      }
    }

    return tiebreakers.length.compareTo(other.tiebreakers.length);
  }

  String get summary {
    return '$category: ${tiebreakers.map(_rankLabel).join('-')}';
  }
}

class HoldemHandEvaluator {
  const HoldemHandEvaluator();

  HoldemHandEvaluation evaluateBest(List<String> cards) {
    if (cards.length != 7) {
      throw ArgumentError.value(cards.length, 'cards.length', 'must be 7');
    }

    final parsedCards = cards.map(_ParsedCard.parse).toList(growable: false);
    HoldemHandEvaluation? best;

    for (var a = 0; a < parsedCards.length - 4; a++) {
      for (var b = a + 1; b < parsedCards.length - 3; b++) {
        for (var c = b + 1; c < parsedCards.length - 2; c++) {
          for (var d = c + 1; d < parsedCards.length - 1; d++) {
            for (var e = d + 1; e < parsedCards.length; e++) {
              final candidate = _evaluateFive(<_ParsedCard>[
                parsedCards[a],
                parsedCards[b],
                parsedCards[c],
                parsedCards[d],
                parsedCards[e],
              ]);
              if (best == null || candidate.compareTo(best) > 0) {
                best = candidate;
              }
            }
          }
        }
      }
    }

    return best!;
  }

  HoldemHandEvaluation _evaluateFive(List<_ParsedCard> cards) {
    final ranksDescending = cards.map((card) => card.rank).toList()
      ..sort((a, b) => b.compareTo(a));
    final rankCounts = <int, int>{};
    for (final rank in ranksDescending) {
      rankCounts[rank] = (rankCounts[rank] ?? 0) + 1;
    }

    final isFlush = cards.every((card) => card.suit == cards.first.suit);
    final straightHigh = _straightHigh(rankCounts.keys.toList());
    final groups = rankCounts.entries.toList()
      ..sort((a, b) {
        final countComparison = b.value.compareTo(a.value);
        if (countComparison != 0) {
          return countComparison;
        }
        return b.key.compareTo(a.key);
      });

    if (isFlush && straightHigh != null) {
      return HoldemHandEvaluation(
        category: 'Straight flush',
        categoryRank: 8,
        tiebreakers: <int>[straightHigh],
      );
    }

    if (groups.first.value == 4) {
      final kicker = groups.firstWhere((entry) => entry.value == 1).key;
      return HoldemHandEvaluation(
        category: 'Four of a kind',
        categoryRank: 7,
        tiebreakers: <int>[groups.first.key, kicker],
      );
    }

    if (groups.first.value == 3 && groups.length == 2) {
      return HoldemHandEvaluation(
        category: 'Full house',
        categoryRank: 6,
        tiebreakers: <int>[groups.first.key, groups[1].key],
      );
    }

    if (isFlush) {
      return HoldemHandEvaluation(
        category: 'Flush',
        categoryRank: 5,
        tiebreakers: ranksDescending,
      );
    }

    if (straightHigh != null) {
      return HoldemHandEvaluation(
        category: 'Straight',
        categoryRank: 4,
        tiebreakers: <int>[straightHigh],
      );
    }

    if (groups.first.value == 3) {
      final kickers = groups
          .where((entry) => entry.value == 1)
          .map((entry) => entry.key)
          .toList();
      return HoldemHandEvaluation(
        category: 'Three of a kind',
        categoryRank: 3,
        tiebreakers: <int>[groups.first.key, ...kickers],
      );
    }

    if (groups.first.value == 2 && groups[1].value == 2) {
      final pairs = groups
          .where((entry) => entry.value == 2)
          .map((entry) => entry.key)
          .toList();
      final kicker = groups.firstWhere((entry) => entry.value == 1).key;
      return HoldemHandEvaluation(
        category: 'Two pair',
        categoryRank: 2,
        tiebreakers: <int>[...pairs, kicker],
      );
    }

    if (groups.first.value == 2) {
      final kickers = groups
          .where((entry) => entry.value == 1)
          .map((entry) => entry.key)
          .toList();
      return HoldemHandEvaluation(
        category: 'Pair',
        categoryRank: 1,
        tiebreakers: <int>[groups.first.key, ...kickers],
      );
    }

    return HoldemHandEvaluation(
      category: 'High card',
      categoryRank: 0,
      tiebreakers: ranksDescending,
    );
  }
}

class _ParsedCard {
  const _ParsedCard({required this.rank, required this.suit});

  final int rank;
  final String suit;

  factory _ParsedCard.parse(String value) {
    if (value.length != 2) {
      throw ArgumentError.value(value, 'card', 'must use two-character form');
    }

    final rank = switch (value[0]) {
      '2' => 2,
      '3' => 3,
      '4' => 4,
      '5' => 5,
      '6' => 6,
      '7' => 7,
      '8' => 8,
      '9' => 9,
      'T' => 10,
      'J' => 11,
      'Q' => 12,
      'K' => 13,
      'A' => 14,
      _ => throw ArgumentError.value(value, 'card', 'unknown rank'),
    };

    final suit = value[1];
    if (suit != 'c' && suit != 'd' && suit != 'h' && suit != 's') {
      throw ArgumentError.value(value, 'card', 'unknown suit');
    }

    return _ParsedCard(rank: rank, suit: suit);
  }
}

int? _straightHigh(List<int> ranks) {
  final unique = ranks.toSet().toList()..sort();
  if (unique.contains(14)) {
    unique.insert(0, 1);
  }

  var runLength = 1;
  int? high;
  for (var i = 1; i < unique.length; i++) {
    if (unique[i] == unique[i - 1] + 1) {
      runLength++;
      if (runLength >= 5) {
        high = unique[i] == 1 ? 5 : unique[i];
      }
    } else {
      runLength = 1;
    }
  }

  return high;
}

String _rankLabel(int rank) {
  return switch (rank) {
    14 => 'A',
    13 => 'K',
    12 => 'Q',
    11 => 'J',
    10 => 'T',
    _ => rank.toString(),
  };
}
