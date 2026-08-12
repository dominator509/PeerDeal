import 'package:peerdeal_modes/peerdeal_modes.dart';
import 'package:test/test.dart';

void main() {
  test('governance context owns policy input collections', () {
    final participants = <ParticipantSnapshot>[
      const ParticipantSnapshot(
        participantId: 'player_1',
        role: RoleKind.player,
        state: ParticipantGovernanceState.waitlisted,
        waitlistState: WaitlistState.waitlistActive,
      ),
    ];
    final seats = <SeatSnapshot>[
      const SeatSnapshot(seatIndex: 1, state: SeatState.empty),
    ];
    final waitlistOrdering = <String>['player_1'];
    final context = GovernanceContext(
      modeId: 'open_table',
      participants: participants,
      seats: seats,
      waitlistOrdering: waitlistOrdering,
    );

    participants.clear();
    seats.clear();
    waitlistOrdering.clear();

    expect(context.participants, hasLength(1));
    expect(context.seats, hasLength(1));
    expect(context.waitlistOrdering, ['player_1']);
    expect(
      () => context.waitlistOrdering.add('player_2'),
      throwsUnsupportedError,
    );
  });

  test(
    'governance decisions and validation results own output collections',
    () {
      final nextWaitlistOrdering = <String>['player_2'];
      final notes = <String>['promoted'];
      final warnings = <String>['late'];
      final errors = <String>['none'];
      final decision = GovernanceDecision(
        allowed: true,
        resultCode: 'ok',
        nextWaitlistOrdering: nextWaitlistOrdering,
        notes: notes,
      );
      final validation = ValidationResult(
        isValid: false,
        warnings: warnings,
        errors: errors,
      );

      nextWaitlistOrdering.clear();
      notes.clear();
      warnings.clear();
      errors.clear();

      expect(decision.nextWaitlistOrdering, ['player_2']);
      expect(decision.notes, ['promoted']);
      expect(validation.warnings, ['late']);
      expect(validation.errors, ['none']);
      expect(() => decision.notes.add('changed'), throwsUnsupportedError);
      expect(() => validation.errors.add('changed'), throwsUnsupportedError);
    },
  );
}
