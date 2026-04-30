import 'package:test/test.dart';
import 'package:peerdeal_modes/peerdeal_modes.dart';

void main() {
  group('DefaultGovernanceEngine', () {
    const engine = DefaultGovernanceEngine();

    test('offers an empty seat deterministically', () {
      final context = GovernanceContext(
        modeId: 'open_table',
        participants: const [
          ParticipantSnapshot(
            participantId: 'host_1',
            role: RoleKind.host,
            state: ParticipantGovernanceState.seated,
            waitlistState: WaitlistState.notWaitlisted,
          ),
          ParticipantSnapshot(
            participantId: 'player_2',
            role: RoleKind.player,
            state: ParticipantGovernanceState.waitlisted,
            waitlistState: WaitlistState.waitlistActive,
          ),
        ],
        seats: const [
          SeatSnapshot(seatIndex: 1, state: SeatState.empty),
        ],
        waitlistOrdering: const ['player_2'],
      );

      final decision = engine.evaluate(
        context: context,
        action: const GovernanceAction(
          type: GovernanceActionType.offerSeat,
          actorId: 'host_1',
          subjectId: 'player_2',
          seatIndex: 1,
        ),
      );

      expect(decision.allowed, isTrue);
      expect(decision.resultCode, GovernanceResultCodes.okSeatOffer);
      expect(decision.nextSeatState, SeatState.reservedPending.name);
    });

    test('denies missing seat offer acceptance', () {
      final context = GovernanceContext(
        modeId: 'open_table',
        participants: const [
          ParticipantSnapshot(
            participantId: 'player_2',
            role: RoleKind.player,
            state: ParticipantGovernanceState.admittedUnseated,
            waitlistState: WaitlistState.notWaitlisted,
          ),
        ],
        seats: const [],
      );

      final decision = engine.evaluate(
        context: context,
        action: const GovernanceAction(
          type: GovernanceActionType.acceptSeatOffer,
          actorId: 'player_2',
          subjectId: 'player_2',
        ),
      );

      expect(decision.allowed, isFalse);
      expect(decision.resultCode, GovernanceResultCodes.errSeatOfferMissing);
    });
  });
}
