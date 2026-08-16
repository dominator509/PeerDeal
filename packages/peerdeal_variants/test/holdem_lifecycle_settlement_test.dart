import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';
import 'package:test/test.dart';

void main() {
  const streetCoordinator = HoldemActionStreetCoordinator();
  const showdownCoordinator = HoldemShowdownCoordinator();
  const emitter = HoldemSettlementEventEmitter();

  test('runs checked Holdem lifecycle through settlement event emission', () {
    var state = _preflopState();

    final preflop = streetCoordinator.applyAndAdvanceIfComplete(
      state: state,
      action: const HoldemTableAction(
        actorSeat: 1,
        type: HoldemTableActionType.call,
      ),
      dealtBoardCards: const <String>['Ah', 'Kd', '2c'],
      openNextBettingRound: true,
    );
    expect(preflop.warnings, isEmpty);
    expect(preflop.state.phase, HoldemHandPhase.bettingFlop);
    state = preflop.state;

    final flop = _checkAround(
      coordinator: streetCoordinator,
      state: state,
      dealtBoardCards: const <String>['Jc'],
      openNextBettingRound: true,
    );
    expect(flop.warnings, isEmpty);
    expect(flop.state.phase, HoldemHandPhase.bettingTurn);
    state = flop.state;

    final turn = _checkAround(
      coordinator: streetCoordinator,
      state: state,
      dealtBoardCards: const <String>['7s'],
      openNextBettingRound: true,
    );
    expect(turn.warnings, isEmpty);
    expect(turn.state.phase, HoldemHandPhase.bettingRiver);
    state = turn.state;

    final river = _checkAround(coordinator: streetCoordinator, state: state);
    expect(river.warnings, isEmpty);
    expect(river.state.phase, HoldemHandPhase.showdownPrep);

    final reveal = showdownCoordinator.reveal(
      state: river.state,
      input: ShowdownEvaluationInput(
        boardCards: <String>['Ah', 'Kd', '2c', 'Jc', '7s'],
        seats: <ShowdownSeatInput>[
          ShowdownSeatInput(
            seat: 1,
            holeCards: <String>['Th', '9d'],
            isFolded: false,
          ),
          ShowdownSeatInput(
            seat: 2,
            holeCards: <String>['Ac', '3c'],
            isFolded: false,
          ),
          ShowdownSeatInput(
            seat: 3,
            holeCards: <String>['Qh', 'Qs'],
            isFolded: false,
          ),
        ],
      ),
    );
    expect(reveal.isRevealed, isTrue);
    expect(reveal.evaluation.results.first.seat, 2);

    final prep = showdownCoordinator.prepareSettlement(
      state: reveal.state,
      evaluation: reveal.evaluation,
    );
    final settlement = showdownCoordinator.projectSettlement(
      state: prep.state,
      evaluation: prep.evaluation,
      commitments: _commitmentsFrom(prep.state),
      seatForId: _seatFromSeatId,
    );
    final completion = showdownCoordinator.completeHand(
      state: prep.state,
      settlement: settlement,
    );
    final emission = emitter.emit(
      settlement: settlement,
      completion: completion,
      plan: _emissionPlan(),
    );

    expect(prep.isPrepared, isTrue);
    expect(settlement.isProjected, isTrue);
    expect(settlement.projection!.settlement!.isBalanced, isTrue);
    expect(completion.isCompleted, isTrue);
    expect(completion.state.phase, HoldemHandPhase.handComplete);
    expect(emission.events.map((event) => event.eventType), <String>[
      'SettlementProjected',
      'HandSettled',
    ]);
    expect(
      emission.settlementProjected!.payload['awards'],
      <Map<String, Object?>>[
        <String, Object?>{'seat_id': 'seat-2', 'amount': 300},
      ],
    );
  });

  test('routes uncontested lifecycle through settlement event emission', () {
    final routed = streetCoordinator.applyAndAdvanceIfComplete(
      state: _preflopState(
        currentActorSeat: 2,
        seats: const <HoldemSeatState>[
          HoldemSeatState(
            seat: 1,
            stack: 900,
            inHand: true,
            folded: false,
            allIn: false,
            committedThisRound: 100,
            committedThisHand: 100,
          ),
          HoldemSeatState(
            seat: 2,
            stack: 900,
            inHand: true,
            folded: false,
            allIn: false,
            committedThisRound: 100,
            committedThisHand: 100,
          ),
          HoldemSeatState(
            seat: 3,
            stack: 900,
            inHand: false,
            folded: true,
            allIn: false,
            committedThisRound: 100,
            committedThisHand: 100,
          ),
        ],
      ),
      action: const HoldemTableAction(
        actorSeat: 2,
        type: HoldemTableActionType.fold,
      ),
    );

    expect(routed.isUncontestedSettlementReady, isTrue);
    expect(routed.uncontestedSettlement!.winningSeat, 1);
    expect(routed.state.phase, HoldemHandPhase.settling);

    final settlement = showdownCoordinator.projectUncontestedSettlement(
      state: routed.state,
      winningSeat: routed.uncontestedSettlement!.winningSeat,
      commitments: _commitmentsFrom(routed.state),
      seatForId: _seatFromSeatId,
    );
    final completion = showdownCoordinator.completeHand(
      state: routed.state,
      settlement: settlement,
    );
    final emission = emitter.emit(
      settlement: settlement,
      completion: completion,
      plan: _emissionPlan(),
    );

    expect(settlement.isProjected, isTrue);
    expect(settlement.projection!.settlement!.isBalanced, isTrue);
    expect(completion.isCompleted, isTrue);
    expect(emission.isProjected, isTrue);
    expect(
      emission.settlementProjected!.payload['awards'],
      <Map<String, Object?>>[
        <String, Object?>{'seat_id': 'seat-1', 'amount': 300},
      ],
    );
  });
}

HoldemActionStreetResult _checkAround({
  required HoldemActionStreetCoordinator coordinator,
  required HoldemHandState state,
  List<String> dealtBoardCards = const <String>[],
  bool openNextBettingRound = false,
}) {
  var current = state;
  HoldemActionStreetResult? result;
  for (var i = 0; i < 3; i += 1) {
    result = coordinator.applyAndAdvanceIfComplete(
      state: current,
      action: HoldemTableAction(
        actorSeat: current.currentActorSeat,
        type: HoldemTableActionType.check,
      ),
      dealtBoardCards: i == 2 ? dealtBoardCards : const <String>[],
      openNextBettingRound: i == 2 && openNextBettingRound,
    );
    current = result.state;
  }
  return result!;
}

HoldemHandState _preflopState({
  int currentActorSeat = 1,
  List<HoldemSeatState> seats = const <HoldemSeatState>[
    HoldemSeatState(
      seat: 1,
      stack: 1000,
      inHand: true,
      folded: false,
      allIn: false,
      committedThisRound: 0,
      committedThisHand: 0,
    ),
    HoldemSeatState(
      seat: 2,
      stack: 900,
      inHand: true,
      folded: false,
      allIn: false,
      committedThisRound: 100,
      committedThisHand: 100,
    ),
    HoldemSeatState(
      seat: 3,
      stack: 900,
      inHand: true,
      folded: false,
      allIn: false,
      committedThisRound: 100,
      committedThisHand: 100,
    ),
  ],
}) {
  return HoldemHandState(
    handId: 'hand_001',
    phase: HoldemHandPhase.bettingPreflop,
    bettingRound: HoldemBettingRound.preflop,
    currentActorSeat: currentActorSeat,
    buttonSeat: 1,
    smallBlindSeat: 2,
    bigBlindSeat: 3,
    currentBetToCall: 100,
    minimumRaiseAmount: 100,
    pot: 200,
    actedSeatsThisRound: <int>[2, 3],
    seats: seats,
  );
}

List<PotCommitment> _commitmentsFrom(HoldemHandState state) {
  return [
    for (final seat in state.seats)
      PotCommitment(
        seatId: 'seat-${seat.seat}',
        committed: seat.committedThisHand,
        isEligibleForShowdown: seat.inHand && !seat.folded,
        isFolded: seat.folded,
      ),
  ];
}

HoldemSettlementEventEmissionPlan _emissionPlan() {
  return const HoldemSettlementEventEmissionPlan(
    protocolVersion: '1.0.0',
    tableId: 'tbl_lifecycle_001',
    sessionId: 'sess_lifecycle_001',
    handId: 'hand_001',
    actorRef: 'system',
    projectionId: 'settlement_projection_lifecycle_001',
    settlementId: 'settlement_lifecycle_001',
    settlementBlocked: HoldemSettlementEventMetadata(
      eventId: 'evt_lifecycle_blocked',
      eventSeq: 9,
      emittedAt: '2026-04-25T12:20:09Z',
      prevEventHash: 'hash_lifecycle_008',
      eventHash: 'hash_lifecycle_blocked',
    ),
    settlementProjected: HoldemSettlementEventMetadata(
      eventId: 'evt_lifecycle_projected',
      eventSeq: 9,
      emittedAt: '2026-04-25T12:20:09Z',
      prevEventHash: 'hash_lifecycle_008',
      eventHash: 'hash_lifecycle_009',
    ),
    handSettled: HoldemSettlementEventMetadata(
      eventId: 'evt_lifecycle_settled',
      eventSeq: 10,
      emittedAt: '2026-04-25T12:20:10Z',
      prevEventHash: 'hash_lifecycle_009',
      eventHash: 'hash_lifecycle_010',
    ),
  );
}

int? _seatFromSeatId(String seatId) {
  final marker = seatId.split('-').last;
  return int.tryParse(marker);
}
