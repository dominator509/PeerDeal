class GovernanceResultCodes {
  static const okAdmit = 'OK_PARTICIPANT_ADMITTED';
  static const okSeatOffer = 'OK_SEAT_OFFERED';
  static const okSeatClaimed = 'OK_SEAT_CLAIMED';
  static const okSeatAssigned = 'OK_SEAT_ASSIGNED';
  static const okSeatOfferExpired = 'OK_SEAT_OFFER_EXPIRED';
  static const okWaitlisted = 'OK_WAITLISTED';
  static const okCohostGranted = 'OK_COHOST_GRANTED';
  static const okCohostRevoked = 'OK_COHOST_REVOKED';
  static const okParticipantRejected = 'OK_PARTICIPANT_REJECTED';
  static const okParticipantRemoved = 'OK_PARTICIPANT_REMOVED';
  static const okParticipantBanned = 'OK_PARTICIPANT_BANNED';

  static const errInviteOnly = 'ERR_INVITE_ONLY_REQUIRED';
  static const errRoleNotAllowed = 'ERR_ROLE_NOT_ALLOWED';
  static const errSeatUnavailable = 'ERR_SEAT_UNAVAILABLE';
  static const errSeatOfferMissing = 'ERR_SEAT_OFFER_MISSING';
  static const errWaitlistDisabled = 'ERR_WAITLIST_DISABLED';
  static const errWaitlistPromotionUnavailable =
      'ERR_WAITLIST_PROMOTION_UNAVAILABLE';
  static const errPermissionDenied = 'ERR_PERMISSION_DENIED';
  static const errParticipantMissing = 'ERR_PARTICIPANT_MISSING';
  static const errParticipantStateInvalid = 'ERR_PARTICIPANT_STATE_INVALID';
  static const errParticipantCountTooLarge = 'ERR_GOVERNANCE_PARTICIPANT_COUNT';
  static const errSeatCountTooLarge = 'ERR_GOVERNANCE_SEAT_COUNT';
  static const errWaitlistCountTooLarge = 'ERR_GOVERNANCE_WAITLIST_COUNT';
  static const errContextInvalid = 'ERR_GOVERNANCE_CONTEXT_INVALID';
  static const errActionIdentityInvalid =
      'ERR_GOVERNANCE_ACTION_IDENTITY_INVALID';
}
