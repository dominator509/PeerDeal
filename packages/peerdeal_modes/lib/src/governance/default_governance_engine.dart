import '../models/mode_input_limits.dart';
import 'governance_action.dart';
import 'governance_context.dart';
import 'governance_decision.dart';
import 'governance_engine.dart';
import 'governance_result.dart';
import 'participant_state.dart';
import 'role_kind.dart';
import 'seat_state.dart';
import 'waitlist_state.dart';

class DefaultGovernanceEngine implements GovernanceEngine {
  const DefaultGovernanceEngine({
    this.maxParticipants = ModeInputLimits.defaultMaxParticipants,
    this.maxSeats = ModeInputLimits.defaultMaxSeats,
    this.maxWaitlistEntries = ModeInputLimits.defaultMaxWaitlistEntries,
  });

  final int maxParticipants;
  final int maxSeats;
  final int maxWaitlistEntries;

  @override
  GovernanceDecision evaluate({
    required GovernanceContext context,
    required GovernanceAction action,
  }) {
    _validateConfiguration();
    final inputError = _inputLimitError(context);
    if (inputError != null) {
      return GovernanceDecision.deny(inputError);
    }

    final actor = context.participantById(action.actorId);
    final subject = context.participantById(action.subjectId);

    if (subject == null) {
      return GovernanceDecision.deny(
        GovernanceResultCodes.errParticipantMissing,
      );
    }

    switch (action.type) {
      case GovernanceActionType.admitParticipant:
        if (!_canManageParticipants(actor)) {
          return GovernanceDecision.deny(
            GovernanceResultCodes.errPermissionDenied,
          );
        }
        return GovernanceDecision(
          allowed: true,
          resultCode: GovernanceResultCodes.okAdmit,
          nextParticipantState:
              ParticipantGovernanceState.admittedUnseated.name,
          notes: const ['Invite-only participant admitted.'],
        );

      case GovernanceActionType.grantCohost:
        if (actor == null ||
            actor.role != RoleKind.host ||
            !context.allowCohosts) {
          return GovernanceDecision.deny(
            GovernanceResultCodes.errPermissionDenied,
            notes: const [
              'Only the host may grant co-host in the default engine.',
            ],
          );
        }
        return GovernanceDecision(
          allowed: true,
          resultCode: GovernanceResultCodes.okCohostGranted,
          nextParticipantState: subject.state.name,
          nextParticipantRole: RoleKind.cohost.wireValue,
          notes: const ['Subject role should be updated to cohost.'],
        );

      case GovernanceActionType.revokeCohost:
        if (actor == null ||
            actor.role != RoleKind.host ||
            !context.allowCohosts) {
          return GovernanceDecision.deny(
            GovernanceResultCodes.errPermissionDenied,
            notes: const [
              'Only the host may revoke co-host in the default engine.',
            ],
          );
        }
        if (subject.role != RoleKind.cohost) {
          return GovernanceDecision.deny(
            GovernanceResultCodes.errRoleNotAllowed,
          );
        }
        return GovernanceDecision(
          allowed: true,
          resultCode: GovernanceResultCodes.okCohostRevoked,
          nextParticipantState: subject.state.name,
          nextParticipantRole: RoleKind.player.wireValue,
          notes: const ['Subject role should be updated to player.'],
        );

      case GovernanceActionType.offerSeat:
        if (!_canManageSeats(actor)) {
          return GovernanceDecision.deny(
            GovernanceResultCodes.errPermissionDenied,
          );
        }
        final seat = context.seats
            .where((s) => s.seatIndex == action.seatIndex)
            .firstOrNull;
        if (seat == null || seat.state != SeatState.empty) {
          return GovernanceDecision.deny(
            GovernanceResultCodes.errSeatUnavailable,
          );
        }
        return GovernanceDecision(
          allowed: true,
          resultCode: GovernanceResultCodes.okSeatOffer,
          nextParticipantState: ParticipantGovernanceState.seatOffered.name,
          nextSeatState: SeatState.reservedPending.name,
          notes: const ['Seat offer issued at a deterministic seat index.'],
        );

      case GovernanceActionType.assignSeat:
        if (!_canManageSeats(actor)) {
          return GovernanceDecision.deny(
            GovernanceResultCodes.errPermissionDenied,
          );
        }
        final seat = context.seats
            .where((s) => s.seatIndex == action.seatIndex)
            .firstOrNull;
        if (seat == null || seat.state != SeatState.claimed) {
          return GovernanceDecision.deny(
            GovernanceResultCodes.errSeatUnavailable,
          );
        }
        if (subject.state != ParticipantGovernanceState.seated) {
          return GovernanceDecision.deny(
            GovernanceResultCodes.errSeatOfferMissing,
          );
        }
        return GovernanceDecision(
          allowed: true,
          resultCode: GovernanceResultCodes.okSeatAssigned,
          nextParticipantState: ParticipantGovernanceState.seated.name,
          nextSeatState: SeatState.activeOccupied.name,
          notes: const ['Claimed seat assigned to active occupancy.'],
        );

      case GovernanceActionType.acceptSeatOffer:
        if (!_isSelfAction(actor, subject)) {
          return GovernanceDecision.deny(
            GovernanceResultCodes.errPermissionDenied,
          );
        }
        if (subject.state != ParticipantGovernanceState.seatOffered) {
          return GovernanceDecision.deny(
            GovernanceResultCodes.errSeatOfferMissing,
          );
        }
        return GovernanceDecision(
          allowed: true,
          resultCode: GovernanceResultCodes.okSeatClaimed,
          nextParticipantState: ParticipantGovernanceState.seated.name,
          nextSeatState: SeatState.claimed.name,
          notes: const [
            'Seat offer accepted. Final active occupancy is a later transition.',
          ],
        );

      case GovernanceActionType.expireSeatOffer:
        if (!_canManageSeats(actor)) {
          return GovernanceDecision.deny(
            GovernanceResultCodes.errPermissionDenied,
          );
        }
        final seat = context.seats
            .where((s) => s.seatIndex == action.seatIndex)
            .firstOrNull;
        if (subject.state != ParticipantGovernanceState.seatOffered ||
            seat == null ||
            seat.state != SeatState.reservedPending) {
          return GovernanceDecision.deny(
            GovernanceResultCodes.errSeatOfferMissing,
          );
        }
        return GovernanceDecision(
          allowed: true,
          resultCode: GovernanceResultCodes.okSeatOfferExpired,
          nextParticipantState:
              ParticipantGovernanceState.admittedUnseated.name,
          nextSeatState: SeatState.empty.name,
          notes: const ['Seat offer expired and seat returned to empty.'],
        );

      case GovernanceActionType.addToWaitlist:
        if (!_isSelfAction(actor, subject) &&
            !_canManageWaitlist(actor)) {
          return GovernanceDecision.deny(
            GovernanceResultCodes.errPermissionDenied,
          );
        }
        final ordering = List<String>.from(context.waitlistOrdering);
        if (!ordering.contains(subject.participantId)) {
          if (ordering.length >= maxWaitlistEntries) {
            return GovernanceDecision.deny(
              GovernanceResultCodes.errWaitlistCountTooLarge,
            );
          }
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
          return GovernanceDecision.deny(
            GovernanceResultCodes.errPermissionDenied,
          );
        }
        if (!_canManageWaitlist(actor)) {
          return GovernanceDecision.deny(
            GovernanceResultCodes.errPermissionDenied,
          );
        }
        if (subject.state != ParticipantGovernanceState.waitlisted ||
            subject.waitlistState != WaitlistState.waitlistActive ||
            context.waitlistOrdering.isEmpty ||
            context.waitlistOrdering.first != subject.participantId) {
          return GovernanceDecision.deny(
            GovernanceResultCodes.errWaitlistPromotionUnavailable,
          );
        }
        final nextOrdering = List<String>.from(context.waitlistOrdering)
          ..remove(subject.participantId);
        return GovernanceDecision(
          allowed: true,
          resultCode: GovernanceResultCodes.okSeatOffer,
          nextParticipantState: ParticipantGovernanceState.seatOffered.name,
          nextWaitlistOrdering: nextOrdering,
          notes: const ['Promotion emits a seat-offer style result.'],
        );

      case GovernanceActionType.markParticipantAway:
        if (!_isSelfAction(actor, subject) &&
            !_canManageParticipants(actor)) {
          return GovernanceDecision.deny(
            GovernanceResultCodes.errPermissionDenied,
          );
        }
        return GovernanceDecision(
          allowed: true,
          resultCode: 'OK_PARTICIPANT_AWAY',
          nextParticipantState: ParticipantGovernanceState.away.name,
        );

      case GovernanceActionType.returnParticipant:
        if (!_isSelfAction(actor, subject) &&
            !_canManageParticipants(actor)) {
          return GovernanceDecision.deny(
            GovernanceResultCodes.errPermissionDenied,
          );
        }
        return GovernanceDecision(
          allowed: true,
          resultCode: 'OK_PARTICIPANT_RETURNED',
          nextParticipantState:
              ParticipantGovernanceState.admittedUnseated.name,
        );

      case GovernanceActionType.rejectParticipant:
      case GovernanceActionType.removeParticipant:
      case GovernanceActionType.banParticipantForSession:
        if (!_canManageParticipants(actor)) {
          return GovernanceDecision.deny(
            GovernanceResultCodes.errPermissionDenied,
          );
        }
        return GovernanceDecision(
          allowed: true,
          resultCode: 'OK_GOVERNANCE_ACTION_ACCEPTED',
          nextParticipantState: subject.state.name,
        );
    }
  }

  void _validateConfiguration() {
    _validatePositiveLimit(maxParticipants, 'maxParticipants');
    _validatePositiveLimit(maxSeats, 'maxSeats');
    _validatePositiveLimit(maxWaitlistEntries, 'maxWaitlistEntries');
  }

  bool _canManageWaitlist(ParticipantSnapshot? actor) {
    return actor != null &&
        (actor.canManageWaitlist ||
            actor.role == RoleKind.host ||
            actor.role == RoleKind.cohost);
  }

  bool _canManageSeats(ParticipantSnapshot? actor) {
    return actor != null &&
        (actor.role == RoleKind.host || actor.role == RoleKind.cohost);
  }

  bool _canManageParticipants(ParticipantSnapshot? actor) {
    return _canManageSeats(actor);
  }

  bool _isSelfAction(
    ParticipantSnapshot? actor,
    ParticipantSnapshot subject,
  ) {
    return actor != null && actor.participantId == subject.participantId;
  }

  String? _inputLimitError(GovernanceContext context) {
    if (context.participants.length > maxParticipants) {
      return GovernanceResultCodes.errParticipantCountTooLarge;
    }
    if (context.seats.length > maxSeats) {
      return GovernanceResultCodes.errSeatCountTooLarge;
    }
    if (context.waitlistOrdering.length > maxWaitlistEntries) {
      return GovernanceResultCodes.errWaitlistCountTooLarge;
    }
    return null;
  }
}

void _validatePositiveLimit(int value, String name) {
  if (value <= 0) {
    throw ArgumentError.value(value, name, 'must be positive');
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
