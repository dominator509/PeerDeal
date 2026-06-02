import 'dart:convert';
import 'dart:io';

import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';
import 'package:test/test.dart';

void main() {
  const coordinator = HoldemShowdownCoordinator();
  const builder = HoldemSettlementBlockedEventBuilder();

  group('HoldemSettlementBlockedEventBuilder', () {
    test(
      'builds empty-pot SettlementBlocked event payload from gate warnings',
      () {
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
          commitments: const <PotCommitment>[],
          seatForId: _seatFromSeatId,
        );

        final event = builder.buildEvent(
          settlement: settlement,
          eventId: 'evt_holdem_blocked_empty_pot_004',
          protocolVersion: '1.0.0',
          eventSeq: 4,
          tableId: 'tbl_holdem_001',
          sessionId: 'sess_holdem_001',
          handId: 'hand_holdem_001',
          emittedAt: '2026-04-25T12:12:04Z',
          actorRef: 'system',
          projectionId: 'settlement_projection_holdem_blocked_empty_pot_001',
          prevEventHash: 'hash_holdem_003',
          eventHash: 'hash_holdem_blocked_empty_pot_004',
        );

        expect(event.eventType, 'SettlementBlocked');
        expect(event.eventVersion, '1.0');
        expect(event.payload['variant_id'], 'holdem_nlhe');
        expect(
          event.payload['projection_id'],
          'settlement_projection_holdem_blocked_empty_pot_001',
        );
        expect(event.payload['reason_codes'], <String>[
          'ERR_HOLDEM_SETTLEMENT_PROJECT_EMPTY_POT',
        ]);
        expect(event.payload['warnings'], <String>[
          'ERR_HOLDEM_SETTLEMENT_PROJECT_EMPTY_COMMITMENTS',
          'ERR_HOLDEM_SETTLEMENT_PROJECT_EMPTY_POT',
        ]);
        expect(
          event.payload,
          _protocolFixturePayload(
            'holdem_settlement_blocked_empty_pot_event_v1.json',
          ),
        );
      },
    );

    test('builds invalid-showdown reason from showdown warnings', () {
      final settlement = coordinator.projectSettlement(
        state: _buildState(phase: HoldemHandPhase.settling),
        evaluation: const ShowdownEvaluationResult(
          results: <RankedShowdownResult>[],
          warnings: <String>['ERR_HOLDEM_SHOWDOWN_CARD_FORMAT'],
        ),
        commitments: const <PotCommitment>[
          PotCommitment(
            seatId: 'seat-1',
            committed: 100,
            isEligibleForShowdown: true,
          ),
        ],
        seatForId: _seatFromSeatId,
      );

      final draft = builder.buildDraft(
        settlement: settlement,
        projectionId:
            'settlement_projection_holdem_blocked_invalid_showdown_001',
      );

      expect(draft.reasonCodes, <String>[
        'ERR_HOLDEM_SETTLEMENT_PROJECT_INVALID_SHOWDOWN',
      ]);
      expect(draft.payload['reason_codes'], draft.reasonCodes);
      expect(draft.warnings, <String>[
        'ERR_HOLDEM_SHOWDOWN_CARD_FORMAT',
        'ERR_HOLDEM_SETTLEMENT_PROJECT_INVALID_SHOWDOWN',
        'ERR_HOLDEM_SETTLEMENT_PROJECT_EMPTY_EVALUATION',
      ]);
      expect(
        draft.payload,
        _protocolFixturePayload(
          'holdem_settlement_blocked_invalid_showdown_event_v1.json',
        ),
      );
    });

    test('builds unawardable reason from blocked projection warnings', () {
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

      final draft = builder.buildDraft(
        settlement: settlement,
        projectionId: 'settlement_projection_holdem_blocked_001',
      );

      expect(draft.reasonCodes, <String>[
        'ERR_HOLDEM_SETTLEMENT_PROJECT_UNAWARDABLE',
      ]);
      expect(draft.payload['warnings'], <String>[
        'ERR_HOLDEM_SETTLEMENT_PROJECT_UNAWARDABLE',
      ]);
      expect(
        draft.payload,
        _protocolFixturePayload('holdem_settlement_blocked_event_v1.json'),
      );
    });

    test('rejects successful settlement projection misuse', () {
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

      expect(
        () => builder.buildDraft(
          settlement: settlement,
          projectionId: 'settlement_projection_holdem_001',
        ),
        throwsArgumentError,
      );
    });
  });
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

const _validInput = ShowdownEvaluationInput(
  boardCards: <String>['Ah', 'Kd', 'Qs', 'Jc', '2h'],
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
