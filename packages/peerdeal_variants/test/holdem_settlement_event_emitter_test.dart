import 'dart:convert';
import 'dart:io';

import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';
import 'package:test/test.dart';

void main() {
  const coordinator = HoldemShowdownCoordinator();
  const emitter = HoldemSettlementEventEmitter();

  group('HoldemSettlementEventEmitter', () {
    test('emits projected settlement then hand-settled events', () {
      final chain = _successfulChain(coordinator);

      final emission = emitter.emit(
        settlement: chain.settlement,
        completion: chain.completion,
        plan: _canonicalSuccessPlan,
      );

      expect(emission.isProjected, isTrue);
      expect(emission.isBlocked, isFalse);
      expect(emission.events.map((event) => event.eventType), <String>[
        'SettlementProjected',
        'HandSettled',
      ]);
      expect(
        emission.settlementProjected!.payload,
        _protocolFixturePayload('holdem_settlement_projected_event_v1.json'),
      );
      expect(
        emission.handSettled!.payload,
        _protocolFixturePayload('holdem_hand_settled_event_v1.json'),
      );
    });

    test('emits blocked settlement event when projection fails closed', () {
      final chain = _blockedChain(coordinator);

      final emission = emitter.emit(
        settlement: chain.settlement,
        completion: chain.completion,
        plan: _canonicalBlockedPlan,
      );

      expect(emission.isBlocked, isTrue);
      expect(emission.isProjected, isFalse);
      expect(emission.events.map((event) => event.eventType), <String>[
        'SettlementBlocked',
      ]);
      expect(emission.settlementProjected, isNull);
      expect(emission.handSettled, isNull);
      expect(
        emission.settlementBlocked!.payload,
        _protocolFixturePayload('holdem_settlement_blocked_event_v1.json'),
      );
    });

    test('rejects projected settlement without hand completion', () {
      final chain = _successfulChain(coordinator);
      final incomplete = HoldemHandCompletionGateResult(
        isCompleted: false,
        state: chain.completion.state,
        projection: chain.completion.projection,
        warnings: const <String>['ERR_TEST_INCOMPLETE'],
      );

      expect(
        () => emitter.emit(
          settlement: chain.settlement,
          completion: incomplete,
          plan: _canonicalSuccessPlan,
        ),
        throwsArgumentError,
      );
    });

    test('rejects blocked settlement with completed hand misuse', () {
      final blocked = _blockedChain(coordinator);
      final completed = HoldemHandCompletionGateResult(
        isCompleted: true,
        state: blocked.completion.state,
        projection: blocked.completion.projection,
      );

      expect(
        () => emitter.emit(
          settlement: blocked.settlement,
          completion: completed,
          plan: _canonicalBlockedPlan,
        ),
        throwsArgumentError,
      );
    });
  });
}

class _SettlementChain {
  const _SettlementChain({required this.settlement, required this.completion});

  final HoldemSettlementProjectionGateResult settlement;
  final HoldemHandCompletionGateResult completion;
}

_SettlementChain _successfulChain(HoldemShowdownCoordinator coordinator) {
  final reveal = coordinator.reveal(state: _buildState(), input: _validInput);
  final prep = coordinator.prepareSettlement(
    state: reveal.state,
    evaluation: reveal.evaluation,
  );
  final settlement = coordinator.projectSettlement(
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
  final completion = coordinator.completeHand(
    state: prep.state,
    settlement: settlement,
  );

  return _SettlementChain(settlement: settlement, completion: completion);
}

_SettlementChain _blockedChain(HoldemShowdownCoordinator coordinator) {
  final reveal = coordinator.reveal(state: _buildState(), input: _validInput);
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
  final completion = coordinator.completeHand(
    state: prep.state,
    settlement: settlement,
  );

  return _SettlementChain(settlement: settlement, completion: completion);
}

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

const _canonicalSuccessPlan = HoldemSettlementEventEmissionPlan(
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

const _canonicalBlockedPlan = HoldemSettlementEventEmissionPlan(
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

int? _seatFromSeatId(String seatId) {
  final marker = seatId.split('-').last;
  return int.tryParse(marker);
}

Map<String, Object?> _protocolFixturePayload(String name) {
  final file = File('../peerdeal_protocol/fixtures/events/$name');
  final decoded = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  return decoded['payload']! as Map<String, Object?>;
}
