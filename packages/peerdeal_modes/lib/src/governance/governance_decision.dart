class GovernanceDecision {
  const GovernanceDecision({
    required this.allowed,
    required this.resultCode,
    this.nextParticipantState,
    this.nextSeatState,
    this.nextWaitlistOrdering = const <String>[],
    this.notes = const <String>[],
  });

  final bool allowed;
  final String resultCode;
  final String? nextParticipantState;
  final String? nextSeatState;
  final List<String> nextWaitlistOrdering;
  final List<String> notes;

  static GovernanceDecision deny(String resultCode, {List<String> notes = const <String>[]}) {
    return GovernanceDecision(
      allowed: false,
      resultCode: resultCode,
      notes: notes,
    );
  }
}
