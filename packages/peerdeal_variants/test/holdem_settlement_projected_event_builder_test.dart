import 'dart:convert';
import 'dart:io';

import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';
import 'package:test/test.dart';

void main() {
  const coordinator = HoldemShowdownCoordinator();
  const builder = HoldemSettlementProjectedEventBuilder();

  group('HoldemSettlementProjectedEventBuilder', () {
    test('builds canonical SettlementProjected event payload', () {
      final settlement = _successfulSettlement(coordinator);

      final event = builder.buildEvent(
        settlement: settlement,
        eventId: 'evt_holdem_004',
        protocolVersion: '1.0.0',
        eventSeq: 4,
        tableId: 'tbl_holdem_001',
        sessionId: 'sess_holdem_001',
        handId: 'hand_holdem_001',
        emittedAt: '2026-04-25T12:10:04Z',
        actorRef: 'system',
        projectionId: 'settlement_projection_holdem_001',
        prevEventHash: 'hash_holdem_003',
        eventHash: 'hash_holdem_004',
      );

      expect(event.eventType, 'SettlementProjected');
      expect(event.eventVersion, '1.0');
      expect(
        event.payload,
        _protocolFixturePayload('holdem_settlement_projected_event_v1.json'),
      );
    });

    test('aggregates multiple slice awards by seat deterministically', () {
      final settlement = _successfulSplitSettlement(coordinator);

      final draft = builder.buildDraft(
        settlement: settlement,
        projectionId: 'settlement_projection_holdem_split_001',
      );

      expect(draft.payload['awards'], <Map<String, Object?>>[
        <String, Object?>{'seat_id': 'seat-1', 'amount': 100},
        <String, Object?>{'seat_id': 'seat-2', 'amount': 200},
      ]);
    });

    test('rejects blocked settlement projection misuse', () {
      final reveal = coordinator.reveal(
        state: _buildState(),
        input: _validInput,
      );
      final prep = coordinator.prepareSettlement(
        state: reveal.state,
        evaluation: reveal.evaluation,
      );
      final settlement = coordinator.projectSettlement(
        state: prep.state,
        evaluation: prep.evaluation,
        commitments: const <PotCommitment>[
          PotCommitment(
            seatId: 'seat-9',
            committed: 100,
            isEligibleForShowdown: true,
          ),
        ],
        seatForId: _seatFromSeatId,
      );

      expect(
        () => builder.buildDraft(
          settlement: settlement,
          projectionId: 'settlement_projection_holdem_blocked_001',
        ),
        throwsArgumentError,
      );
    });
  });
}

HoldemSettlementProjectionGateResult _successfulSettlement(
  HoldemShowdownCoordinator coordinator,
) {
  final reveal = coordinator.reveal(state: _buildState(), input: _validInput);
  final prep = coordinator.prepareSettlement(
    state: reveal.state,
    evaluation: reveal.evaluation,
  );
  return coordinator.projectSettlement(
    state: prep.state,
    evaluation: prep.evaluation,
    commitments: const <PotCommitment>[
      PotCommitment(
        seatId: 'seat-1',
        committed: 100,
        isEligibleForShowdown: true,
      ),
      PotCommitment(
        seatId: 'seat-2',
        committed: 200,
        isEligibleForShowdown: true,
      ),
    ],
    seatForId: _seatFromSeatId,
  );
}

HoldemSettlementProjectionGateResult _successfulSplitSettlement(
  HoldemShowdownCoordinator coordinator,
) {
  final splitEvaluation = ShowdownEvaluationResult(
    results: <RankedShowdownResult>[
      RankedShowdownResult(seat: 1, rankIndex: 0, summary: 'pair: A-K-Q-J'),
      RankedShowdownResult(seat: 2, rankIndex: 0, summary: 'pair: A-K-Q-J'),
    ],
  );

  return coordinator.projectSettlement(
    state: _buildState(phase: HoldemHandPhase.settling),
    evaluation: splitEvaluation,
    commitments: const <PotCommitment>[
      PotCommitment(
        seatId: 'seat-1',
        committed: 100,
        isEligibleForShowdown: true,
      ),
      PotCommitment(
        seatId: 'seat-2',
        committed: 200,
        isEligibleForShowdown: true,
      ),
    ],
    seatForId: _seatFromSeatId,
  );
}

HoldemHandState _buildState({
  HoldemHandPhase phase = HoldemHandPhase.showdownPrep,
}) {
  return HoldemHandState(
    handId: 'hand_001',
    phase: phase,
    bettingRound: HoldemBettingRound.river,
    currentActorSeat: 1,
    buttonSeat: 1,
    smallBlindSeat: 2,
    bigBlindSeat: 3,
    currentBetToCall: 0,
    minimumRaiseAmount: 100,
    boardCards: const <String>['Ah', 'Kd', 'Qs', 'Jc', '2h'],
    seats: const <HoldemSeatState>[
      HoldemSeatState(
        seat: 1,
        stack: 1000,
        inHand: true,
        folded: false,
        allIn: false,
      ),
      HoldemSeatState(
        seat: 2,
        stack: 900,
        inHand: true,
        folded: false,
        allIn: false,
      ),
    ],
  );
}

final _validInput = ShowdownEvaluationInput(
  boardCards: <String>['Ah', 'Kd', 'Qs', 'Jc', '2h'],
  seats: <ShowdownSeatInput>[
    ShowdownSeatInput(
      seat: 1,
      holeCards: <String>['8h', '9d'],
      isFolded: false,
    ),
    ShowdownSeatInput(
      seat: 2,
      holeCards: <String>['Ac', '3c'],
      isFolded: false,
    ),
  ],
);

int? _seatFromSeatId(String seatId) {
  final marker = seatId.split('-').last;
  return int.tryParse(marker);
}

Map<String, Object?> _protocolFixturePayload(String name) {
  final file = File('../peerdeal_protocol/fixtures/events/$name');
  final decoded = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  return decoded['payload']! as Map<String, Object?>;
}
