import 'participant_state.dart';
import 'role_kind.dart';
import 'seat_state.dart';
import 'waitlist_state.dart';

class ParticipantSnapshot {
  const ParticipantSnapshot({
    required this.participantId,
    required this.role,
    required this.state,
    required this.waitlistState,
    this.seatIndex,
    this.canManageWaitlist = false,
    this.canPauseSession = false,
    this.canCloseSession = false,
  });

  final String participantId;
  final RoleKind role;
  final ParticipantGovernanceState state;
  final WaitlistState waitlistState;
  final int? seatIndex;
  final bool canManageWaitlist;
  final bool canPauseSession;
  final bool canCloseSession;
}

class SeatSnapshot {
  const SeatSnapshot({
    required this.seatIndex,
    required this.state,
    this.occupantId,
  });

  final int seatIndex;
  final SeatState state;
  final String? occupantId;
}

class GovernanceContext {
  const GovernanceContext({
    required this.modeId,
    required this.participants,
    required this.seats,
    this.waitlistOrdering = const <String>[],
    this.allowSpectators = true,
    this.allowCohosts = true,
    this.allowMidSessionSeatPromotion = true,
  });

  final String modeId;
  final List<ParticipantSnapshot> participants;
  final List<SeatSnapshot> seats;
  final List<String> waitlistOrdering;
  final bool allowSpectators;
  final bool allowCohosts;
  final bool allowMidSessionSeatPromotion;

  ParticipantSnapshot? participantById(String id) {
    for (final p in participants) {
      if (p.participantId == id) return p;
    }
    return null;
  }
}
