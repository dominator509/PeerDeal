class DirectRelayTransitionPlan {
  const DirectRelayTransitionPlan({
    required this.transitionNeeded,
    required this.pauseRecommended,
    required this.fromLabel,
    required this.toLabel,
    required this.reason,
  });

  final bool transitionNeeded;
  final bool pauseRecommended;
  final String fromLabel;
  final String toLabel;
  final String reason;
}
