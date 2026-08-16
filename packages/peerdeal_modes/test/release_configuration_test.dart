import 'package:peerdeal_modes/peerdeal_modes.dart';
import 'package:test/test.dart';

void main() {
  test('rejects invalid configured limits at runtime', () {
    expect(
      () => const DefaultGovernanceEngine(maxParticipants: 0).evaluate(
        context: GovernanceContext(
          modeId: 'open_table',
          participants: const [],
          seats: const [],
        ),
        action: const GovernanceAction(
          type: GovernanceActionType.admitParticipant,
          actorId: 'host_1',
          subjectId: 'player_1',
        ),
      ),
      throwsArgumentError,
    );
  });
}
