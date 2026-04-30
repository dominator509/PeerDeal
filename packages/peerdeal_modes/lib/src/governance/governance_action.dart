enum GovernanceActionType {
  admitParticipant,
  rejectParticipant,
  grantCohost,
  revokeCohost,
  assignSeat,
  offerSeat,
  acceptSeatOffer,
  expireSeatOffer,
  addToWaitlist,
  promoteFromWaitlist,
  markParticipantAway,
  returnParticipant,
  removeParticipant,
  banParticipantForSession,
}

class GovernanceAction {
  const GovernanceAction({
    required this.type,
    required this.actorId,
    required this.subjectId,
    this.seatIndex,
  });

  final GovernanceActionType type;
  final String actorId;
  final String subjectId;
  final int? seatIndex;
}
