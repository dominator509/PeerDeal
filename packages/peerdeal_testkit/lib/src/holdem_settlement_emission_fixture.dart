import 'package:meta/meta.dart';
import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';

@immutable
class HoldemSettlementEmissionFixtureResult {
  const HoldemSettlementEmissionFixtureResult({
    required this.settlement,
    required this.completion,
    required this.emission,
  });

  final HoldemSettlementProjectionGateResult settlement;
  final HoldemHandCompletionGateResult completion;
  final HoldemSettlementEventEmission emission;
}

class HoldemSettlementEmissionFixture {
  const HoldemSettlementEmissionFixture({
    this.coordinator = const HoldemShowdownCoordinator(),
    this.emitter = const HoldemSettlementEventEmitter(),
  });

  final HoldemShowdownCoordinator coordinator;
  final HoldemSettlementEventEmitter emitter;

  HoldemSettlementEmissionFixtureResult projected() {
    final prepared = _prepareSettlement();
    final settlement = coordinator.projectSettlement(
      state: prepared.state,
      evaluation: prepared.evaluation,
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
    final completion = coordinator.completeHand(
      state: prepared.state,
      settlement: settlement,
    );
    final emission = emitter.emit(
      settlement: settlement,
      completion: completion,
      plan: _projectedPlan,
    );

    return HoldemSettlementEmissionFixtureResult(
      settlement: settlement,
      completion: completion,
      emission: emission,
    );
  }

  HoldemSettlementEmissionFixtureResult blockedUnawardable() {
    final prepared = _prepareSettlement();
    final settlement = coordinator.projectSettlement(
      state: prepared.state,
      evaluation: prepared.evaluation,
      commitments: const <PotCommitment>[
        PotCommitment(
          seatId: 'seat-9',
          committed: 100,
          isEligibleForShowdown: true,
        ),
      ],
      seatForId: _seatFromSeatId,
    );
    final completion = coordinator.completeHand(
      state: prepared.state,
      settlement: settlement,
    );
    final emission = emitter.emit(
      settlement: settlement,
      completion: completion,
      plan: _blockedPlan,
    );

    return HoldemSettlementEmissionFixtureResult(
      settlement: settlement,
      completion: completion,
      emission: emission,
    );
  }

  HoldemSettlementPrepResult _prepareSettlement() {
    final reveal = coordinator.reveal(state: _buildState(), input: _input);
    return coordinator.prepareSettlement(
      state: reveal.state,
      evaluation: reveal.evaluation,
    );
  }
}

const _projectedPlan = HoldemSettlementEventEmissionPlan(
  protocolVersion: '1.0.0',
  tableId: 'tbl_holdem_001',
  sessionId: 'sess_holdem_001',
  handId: 'hand_holdem_001',
  actorRef: 'system',
  projectionId: 'settlement_projection_holdem_001',
  settlementId: 'settlement_holdem_001',
  settlementBlocked: HoldemSettlementEventMetadata(
    eventId: 'unused_blocked',
    eventSeq: 4,
    emittedAt: '2026-04-25T12:10:04Z',
    prevEventHash: 'hash_holdem_003',
    eventHash: 'unused_blocked_hash',
  ),
  settlementProjected: HoldemSettlementEventMetadata(
    eventId: 'evt_holdem_004',
    eventSeq: 4,
    emittedAt: '2026-04-25T12:10:04Z',
    prevEventHash: 'hash_holdem_003',
    eventHash: 'hash_holdem_004',
  ),
  handSettled: HoldemSettlementEventMetadata(
    eventId: 'evt_holdem_005',
    eventSeq: 5,
    emittedAt: '2026-04-25T12:10:05Z',
    prevEventHash: 'hash_holdem_004',
    eventHash: 'hash_holdem_005',
  ),
);

const _blockedPlan = HoldemSettlementEventEmissionPlan(
  protocolVersion: '1.0.0',
  tableId: 'tbl_holdem_001',
  sessionId: 'sess_holdem_001',
  handId: 'hand_holdem_001',
  actorRef: 'system',
  projectionId: 'settlement_projection_holdem_blocked_001',
  settlementId: 'unused_settlement',
  settlementBlocked: HoldemSettlementEventMetadata(
    eventId: 'evt_holdem_blocked_004',
    eventSeq: 4,
    emittedAt: '2026-04-25T12:11:04Z',
    prevEventHash: 'hash_holdem_003',
    eventHash: 'hash_holdem_blocked_004',
  ),
  settlementProjected: HoldemSettlementEventMetadata(
    eventId: 'unused_projected',
    eventSeq: 4,
    emittedAt: '2026-04-25T12:11:04Z',
    prevEventHash: 'hash_holdem_003',
    eventHash: 'unused_projected_hash',
  ),
  handSettled: HoldemSettlementEventMetadata(
    eventId: 'unused_settled',
    eventSeq: 5,
    emittedAt: '2026-04-25T12:11:05Z',
    prevEventHash: 'unused_projected_hash',
    eventHash: 'unused_settled_hash',
  ),
);

HoldemHandState _buildState() {
  return HoldemHandState(
    handId: 'hand_001',
    phase: HoldemHandPhase.showdownPrep,
    bettingRound: HoldemBettingRound.river,
    currentActorSeat: 1,
    buttonSeat: 1,
    smallBlindSeat: 2,
    bigBlindSeat: 3,
    currentBetToCall: 0,
    minimumRaiseAmount: 100,
    boardCards: <String>['Ah', 'Kd', 'Qs', 'Jc', '2h'],
    seats: <HoldemSeatState>[
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

final _input = ShowdownEvaluationInput(
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
