class GovernanceDecision {
  GovernanceDecision({
    required this.allowed,
    required this.resultCode,
    this.nextParticipantState,
    this.nextParticipantRole,
    this.nextSeatState,
    List<String> nextWaitlistOrdering = const <String>[],
    List<String> notes = const <String>[],
  }) : nextWaitlistOrdering = List<String>.unmodifiable(nextWaitlistOrdering),
       notes = List<String>.unmodifiable(notes);

  final bool allowed;
  final String resultCode;
  final String? nextParticipantState;
  final String? nextParticipantRole;
  final String? nextSeatState;
  final List<String> nextWaitlistOrdering;
  final List<String> notes;

  static GovernanceDecision deny(
    String resultCode, {
    List<String> notes = const <String>[],
  }) {
    return GovernanceDecision(
      allowed: false,
      resultCode: resultCode,
      notes: notes,
    );
  }
}
