import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';
import 'package:test/test.dart';

void main() {
  group('variant public model ownership', () {
    test('freezes contract and showdown collections at construction', () {
      final warnings = <String>['warning'];
      final errors = <String>['error'];
      final validation = VariantValidationResult(
        isValid: false,
        warnings: warnings,
        errors: errors,
      );
      warnings.add('late-warning');
      errors.add('late-error');

      expect(validation.warnings, <String>['warning']);
      expect(validation.errors, <String>['error']);
      expect(() => validation.warnings.add('mutate'), throwsUnsupportedError);
      expect(() => validation.errors.add('mutate'), throwsUnsupportedError);

      final boardStages = <int>[3, 1, 1];
      final plan = HandPlan(privateCardsPerSeat: 2, boardStages: boardStages);
      boardStages[0] = 5;
      expect(plan.boardStages, <int>[3, 1, 1]);
      expect(() => plan.boardStages.add(1), throwsUnsupportedError);

      final holeCards = <String>['Ah', 'Kd'];
      final seat = ShowdownSeatInput(
        seat: 1,
        holeCards: holeCards,
        isFolded: false,
      );
      holeCards[0] = '2c';
      expect(seat.holeCards, <String>['Ah', 'Kd']);
      expect(() => seat.holeCards.add('Qs'), throwsUnsupportedError);

      final boardCards = <String>['Ah', 'Kd', 'Qs', 'Jc', '2h'];
      final seats = <ShowdownSeatInput>[seat];
      final input = ShowdownEvaluationInput(
        boardCards: boardCards,
        seats: seats,
      );
      boardCards.clear();
      seats.clear();
      expect(input.boardCards, <String>['Ah', 'Kd', 'Qs', 'Jc', '2h']);
      expect(input.seats, <ShowdownSeatInput>[seat]);
      expect(() => input.boardCards.clear(), throwsUnsupportedError);
      expect(() => input.seats.clear(), throwsUnsupportedError);

      final winnerSeats = <int>[1, 2];
      final winnerGroup = ShowdownWinnerGroup(rankIndex: 0, seats: winnerSeats);
      winnerSeats.clear();
      expect(winnerGroup.seats, <int>[1, 2]);
      expect(() => winnerGroup.seats.add(3), throwsUnsupportedError);

      final winnerIds = <int, List<String>>{
        0: <String>['seat-1'],
      };
      final unawardable = <int>[1];
      final projection = ShowdownSliceWinnerProjection(
        winningSeatIdsBySliceIndex: winnerIds,
        unawardableSliceIndexes: unawardable,
        warnings: <String>['projection-warning'],
      );
      winnerIds[0]!.add('seat-2');
      winnerIds[1] = <String>['seat-3'];
      unawardable.clear();
      expect(projection.winningSeatIdsBySliceIndex, <int, List<String>>{
        0: <String>['seat-1'],
      });
      expect(projection.unawardableSliceIndexes, <int>[1]);
      expect(
        () => projection.winningSeatIdsBySliceIndex[0]!.add('mutate'),
        throwsUnsupportedError,
      );
      expect(
        () => projection.winningSeatIdsBySliceIndex[2] = <String>['mutate'],
        throwsUnsupportedError,
      );

      final results = <RankedShowdownResult>[
        const RankedShowdownResult(seat: 1, rankIndex: 0, summary: 'winner'),
      ];
      final evaluation = ShowdownEvaluationResult(
        results: results,
        warnings: <String>['evaluation-warning'],
      );
      results.clear();
      expect(evaluation.results, hasLength(1));
      expect(() => evaluation.results.clear(), throwsUnsupportedError);

      final settlement = ShowdownSettlementProjectionResult.blocked(
        slices: <PotSlice>[],
        projection: projection,
        warnings: <String>['settlement-warning'],
      );
      expect(() => settlement.slices.add(_potSlice()), throwsUnsupportedError);
      expect(() => settlement.warnings.add('mutate'), throwsUnsupportedError);
    });

    test(
      'freezes Holdem state, transition, emission, and diagnostic results',
      () {
        final seats = <HoldemSeatState>[
          const HoldemSeatState(
            seat: 1,
            stack: 1000,
            inHand: true,
            folded: false,
            allIn: false,
          ),
        ];
        final boardCards = <String>['Ah'];
        final actedSeats = <int>[1];
        final state = HoldemHandState(
          handId: 'hand-1',
          phase: HoldemHandPhase.bettingPreflop,
          bettingRound: HoldemBettingRound.preflop,
          seats: seats,
          currentActorSeat: 1,
          buttonSeat: 1,
          smallBlindSeat: 1,
          bigBlindSeat: 1,
          currentBetToCall: 0,
          minimumRaiseAmount: 10,
          boardCards: boardCards,
          actedSeatsThisRound: actedSeats,
        );
        seats.clear();
        boardCards.clear();
        actedSeats.clear();

        expect(state.seats, hasLength(1));
        expect(state.boardCards, <String>['Ah']);
        expect(state.actedSeatsThisRound, <int>[1]);
        expect(() => state.seats.clear(), throwsUnsupportedError);
        expect(() => state.boardCards.clear(), throwsUnsupportedError);
        expect(() => state.actedSeatsThisRound.clear(), throwsUnsupportedError);

        final tiebreakers = <int>[14, 13];
        final evaluation = HoldemHandEvaluation(
          category: 'pair',
          categoryRank: 1,
          tiebreakers: tiebreakers,
        );
        tiebreakers.clear();
        expect(evaluation.tiebreakers, <int>[14, 13]);
        expect(() => evaluation.tiebreakers.clear(), throwsUnsupportedError);

        final warnings = <String>['warning'];
        final street = HoldemStreetAdvanceResult(
          isAdvanced: false,
          state: state,
          warnings: warnings,
        );
        final bettingRound = HoldemBettingRoundOpenResult(
          isOpened: false,
          state: state,
          warnings: warnings,
        );
        final uncontested = HoldemUncontestedSettlementResult(
          isReady: false,
          state: state,
          winningSeat: null,
          warnings: warnings,
        );
        final blind = HoldemBlindPostingResult(
          isPosted: false,
          state: state,
          warnings: warnings,
        );
        final action = HoldemActionApplicationResult(
          isApplied: false,
          state: state,
          validation: const HoldemActionValidationResult(isValid: false),
        );
        final actionStreet = HoldemActionStreetResult(
          action: action,
          state: state,
          street: street,
          bettingRound: bettingRound,
          uncontestedSettlement: uncontested,
        );

        expect(street.warnings, <String>['warning']);
        expect(bettingRound.warnings, <String>['warning']);
        expect(uncontested.warnings, <String>['warning']);
        expect(blind.warnings, <String>['warning']);
        expect(actionStreet.warnings, <String>[
          'warning',
          'warning',
          'warning',
        ]);
        expect(() => street.warnings.add('mutate'), throwsUnsupportedError);
        expect(() => blind.warnings.add('mutate'), throwsUnsupportedError);
        expect(
          () => actionStreet.warnings.add('mutate'),
          throwsUnsupportedError,
        );

        final showdown = ShowdownEvaluationResult(
          results: <RankedShowdownResult>[
            const RankedShowdownResult(
              seat: 1,
              rankIndex: 0,
              summary: 'winner',
            ),
          ],
        );
        final reveal = HoldemShowdownRevealResult(
          isRevealed: false,
          state: state,
          evaluation: showdown,
          warnings: warnings,
        );
        final prep = HoldemSettlementPrepResult(
          isPrepared: false,
          state: state,
          evaluation: showdown,
          warnings: warnings,
        );
        final gate = HoldemSettlementProjectionGateResult(
          isProjected: false,
          state: state,
          evaluation: showdown,
          projection: null,
          warnings: warnings,
        );
        final completion = HoldemHandCompletionGateResult(
          isCompleted: false,
          state: state,
          projection: null,
          warnings: warnings,
        );
        final reduction = HoldemEventReductionResult.rejected(
          state: state,
          reasonCode: 'ERR_TEST',
          warnings: warnings,
        );
        final emission = HoldemSettlementEventEmission(
          events: <EventEnvelope>[],
        );
        final blockedDraft = HoldemSettlementBlockedEventDraft(
          payload: <String, Object?>{},
          reasonCodes: <String>['ERR_TEST'],
          warnings: warnings,
        );
        final projectedDraft = HoldemSettlementProjectedEventDraft(
          payload: <String, Object?>{},
          awards: <Map<String, Object?>>[],
        );
        warnings.clear();

        expect(reveal.warnings, <String>['warning']);
        expect(prep.warnings, <String>['warning']);
        expect(gate.warnings, <String>['warning']);
        expect(completion.warnings, <String>['warning']);
        expect(reduction.warnings, <String>['warning']);
        expect(blockedDraft.warnings, <String>['warning']);
        expect(() => emission.events.add(_event()), throwsUnsupportedError);
        expect(
          () => blockedDraft.reasonCodes.add('mutate'),
          throwsUnsupportedError,
        );
        expect(
          () => projectedDraft.awards.add(<String, Object?>{}),
          throwsUnsupportedError,
        );
      },
    );

    test('freezes settlement event draft payload trees', () {
      final projectedPayload = <String, Object?>{
        'awards': <Object?>[
          <String, Object?>{'seat_id': 'seat-1'},
        ],
      };
      final projectedAwards = <Map<String, Object?>>[
        <String, Object?>{'seat_id': 'seat-1'},
      ];
      final projectedDraft = HoldemSettlementProjectedEventDraft(
        payload: projectedPayload,
        awards: projectedAwards,
      );
      (projectedPayload['awards']! as List<Object?>).clear();
      projectedAwards.single['seat_id'] = 'seat-2';

      expect(projectedDraft.payload['awards'], <Object?>[
        <String, Object?>{'seat_id': 'seat-1'},
      ]);
      expect(projectedDraft.awards, <Map<String, Object?>>[
        <String, Object?>{'seat_id': 'seat-1'},
      ]);
      expect(
        () => (projectedDraft.payload['awards']! as List<Object?>).clear(),
        throwsUnsupportedError,
      );
      expect(
        () => (projectedDraft.awards.single['seat_id'] = 'mutate'),
        throwsUnsupportedError,
      );

      final blockedWarnings = <String>['ERR_TEST'];
      final blockedPayload = <String, Object?>{'warnings': blockedWarnings};
      final blockedDraft = HoldemSettlementBlockedEventDraft(
        payload: blockedPayload,
        reasonCodes: <String>['ERR_TEST'],
        warnings: blockedWarnings,
      );
      blockedWarnings.clear();
      expect(blockedDraft.payload['warnings'], <String>['ERR_TEST']);
      expect(
        () => (blockedDraft.payload['warnings']! as List<Object?>).clear(),
        throwsUnsupportedError,
      );

      final settledPayload = <String, Object?>{'settlement_id': 'settlement-1'};
      final settledDraft = HoldemHandSettledEventDraft(payload: settledPayload);
      settledPayload['settlement_id'] = 'mutate';
      expect(settledDraft.payload['settlement_id'], 'settlement-1');
      expect(
        () => settledDraft.payload['settlement_id'] = 'mutate',
        throwsUnsupportedError,
      );
    });
  });
}

PotSlice _potSlice() {
  return PotSlice(
    sliceIndex: 0,
    amount: 1,
    contestedBySeatIds: <String>['seat-1'],
  );
}

EventEnvelope _event() {
  return EventEnvelope(
    eventId: 'event-1',
    eventType: 'Test',
    eventVersion: '1.0',
    protocolVersion: '1.0',
    eventSeq: 1,
    tableId: 'table-1',
    sessionId: 'session-1',
    handId: 'hand-1',
    emittedAt: '2026-01-01T00:00:00Z',
    actorRef: 'actor-1',
    payload: const <String, Object?>{},
    prevEventHash: 'genesis',
    eventHash: 'hash-1',
  );
}
