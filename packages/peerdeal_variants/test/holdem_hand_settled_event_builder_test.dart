import 'dart:convert';
import 'dart:io';

import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';
import 'package:test/test.dart';

void main() {
  const coordinator = HoldemShowdownCoordinator();
  const builder = HoldemHandSettledEventBuilder();

  group('HoldemHandSettledEventBuilder', () {
    test('builds canonical HandSettled event payload', () {
      final completion = _successfulCompletion(coordinator);

      final event = builder.buildEvent(
        completion: completion,
        eventId: 'evt_holdem_005',
        protocolVersion: '1.0.0',
        eventSeq: 5,
        tableId: 'tbl_holdem_001',
        sessionId: 'sess_holdem_001',
        handId: 'hand_holdem_001',
        emittedAt: '2026-04-25T12:10:05Z',
        actorRef: 'system',
        settlementId: 'settlement_holdem_001',
        projectionId: 'settlement_projection_holdem_001',
        prevEventHash: 'hash_holdem_004',
        eventHash: 'hash_holdem_005',
      );

      expect(event.eventType, 'HandSettled');
      expect(event.eventVersion, '1.0');
      expect(
        event.payload,
        _protocolFixturePayload('holdem_hand_settled_event_v1.json'),
      );
    });

    test('rejects blocked settlement completion misuse', () {
      final blockedCompletion = _blockedCompletion(coordinator);

      expect(
        () => builder.buildDraft(
          completion: blockedCompletion,
          settlementId: 'settlement_holdem_001',
          projectionId: 'settlement_projection_holdem_blocked_001',
        ),
        throwsArgumentError,
      );
    });

    test('rejects uncompleted hand misuse', () {
      final completion = _successfulCompletion(coordinator);
      final uncompleted = HoldemHandCompletionGateResult(
        isCompleted: false,
        state: completion.state,
        projection: completion.projection,
        warnings: const <String>['ERR_TEST_INCOMPLETE'],
      );

      expect(
        () => builder.buildDraft(
          completion: uncompleted,
          settlementId: 'settlement_holdem_001',
          projectionId: 'settlement_projection_holdem_001',
        ),
        throwsArgumentError,
      );
    });
  });
}

HoldemHandCompletionGateResult _successfulCompletion(
  HoldemShowdownCoordinator coordinator,
) {
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

  return coordinator.completeHand(state: prep.state, settlement: settlement);
}

HoldemHandCompletionGateResult _blockedCompletion(
  HoldemShowdownCoordinator coordinator,
) {
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

  return coordinator.completeHand(state: prep.state, settlement: settlement);
}

HoldemHandState _buildState() {
  return const HoldemHandState(
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

const _validInput = ShowdownEvaluationInput(
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
