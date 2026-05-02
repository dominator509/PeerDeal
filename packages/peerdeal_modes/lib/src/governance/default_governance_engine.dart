import 'governance_action.dart';
import 'governance_context.dart';
import 'governance_decision.dart';
import 'governance_engine.dart';
import 'governance_result.dart';
import 'participant_state.dart';
import 'role_kind.dart';
import 'seat_state.dart';

class DefaultGovernanceEngine implements GovernanceEngine {
  const DefaultGovernanceEngine();

  @override
  GovernanceDecision evaluate({
    required GovernanceContext context,
    required GovernanceAction action,
  }) {
    final actor = context.participantById(action.actorId);
    final subject = context.participantById(action.subjectId);

    if (subject == null) {
      return GovernanceDecision.deny(GovernanceResultCodes.errParticipantMissing);
    }

    switch (action.type) {
      case GovernanceActionType.admitParticipant:
        return GovernanceDecision(
          allowed: true,
          resultCode: GovernanceResultCodes.okAdmit,
          nextParticipantState: ParticipantGovernanceState.admittedUnseated.name,
          notes: const ['Invite-only participant admitted.'],
        );

      case GovernanceActionType.grantCohost:
        if (actor == null || actor.role != RoleKind.host || !context.allowCohosts) {
          return GovernanceDecision.deny(
            GovernanceResultCodes.errPermissionDenied,
            notes: const ['Only the host may grant co-host in the default engine.'],
          );
        }
        return GovernanceDecision(
          allowed: true,
          resultCode: GovernanceResultCodes.okCohostGranted,
          nextParticipantState: subject.state.name,
          notes: const ['Subject role should be updated to cohost by event application.'],
        );

      case GovernanceActionType.offerSeat:
        final seat = context.seats.where((s) => s.seatIndex == action.seatIndex).firstOrNull;
        if (seat == null || seat.state != SeatState.empty) {
          return GovernanceDecision.deny(GovernanceResultCodes.errSeatUnavailable);
        }
        return GovernanceDecision(
          allowed: true,
          resultCode: GovernanceResultCodes.okSeatOffer,
          nextParticipantState: ParticipantGovernanceState.seatOffered.name,
          nextSeatState: SeatState.reservedPending.name,
          notes: const ['Seat offer issued at a deterministic seat index.'],
        );

      case GovernanceActionType.acceptSeatOffer:
        if (subject.state != ParticipantGovernanceState.seatOffered) {
          return GovernanceDecision.deny(GovernanceResultCodes.errSeatOfferMissing);
        }
        return GovernanceDecision(
          allowed: true,
          resultCode: GovernanceResultCodes.okSeatClaimed,
          nextParticipantState: ParticipantGovernanceState.seated.name,
          nextSeatState: SeatState.claimed.name,
          notes: const ['Seat offer accepted. Final active occupancy is a later transition.'],
        );

      case GovernanceActionType.addToWaitlist:
        final ordering = List<String>.from(context.waitlistOrdering);
        if (!ordering.contains(subject.participantId)) {
          ordering.add(subject.participantId);
        }
        return GovernanceDecision(
          allowed: true,
          resultCode: GovernanceResultCodes.okWaitlisted,
          nextParticipantState: ParticipantGovernanceState.waitlisted.name,
          nextWaitlistOrdering: ordering,
          notes: const ['Waitlist ordering must remain deterministic.'],
        );

      case GovernanceActionType.promoteFromWaitlist:
        if (!context.allowMidSessionSeatPromotion) {
          return GovernanceDecision.deny(GovernanceResultCodes.errPermissionDenied);
        }
        return GovernanceDecision(
          allowed: true,
          resultCode: GovernanceResultCodes.okSeatOffer,
          nextParticipantState: ParticipantGovernanceState.seatOffered.name,
          notes: const ['Promotion emits a seat-offer style result.'],
        );

      case GovernanceActionType.markParticipantAway:
        return GovernanceDecision(
          allowed: true,
          resultCode: 'OK_PARTICIPANT_AWAY',
          nextParticipantState: ParticipantGovernanceState.away.name,
        );

      case GovernanceActionType.returnParticipant:
        return GovernanceDecision(
          allowed: true,
          resultCode: 'OK_PARTICIPANT_RETURNED',
          nextParticipantState: ParticipantGovernanceState.admittedUnseated.name,
        );

      case GovernanceActionType.rejectParticipant:
      case GovernanceActionType.revokeCohost:
      case GovernanceActionType.assignSeat:
      case GovernanceActionType.expireSeatOffer:
      case GovernanceActionType.removeParticipant:
      case GovernanceActionType.banParticipantForSession:
        return GovernanceDecision(
          allowed: true,
          resultCode: 'OK_GOVERNANCE_ACTION_ACCEPTED',
          nextParticipantState: subject.state.name,
        );
    }
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
