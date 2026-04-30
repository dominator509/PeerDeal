class ModeCapabilities {
  const ModeCapabilities({
    required this.supportsLiveJoin,
    required this.supportsLiveLeave,
    required this.supportsMidSessionReturn,
    required this.supportsPersonalLedger,
    required this.supportsReceipts,
    required this.supportsSpectators,
    required this.supportsCohosts,
    required this.supportsReloadPolicy,
    required this.supportsWaitlist,
    required this.supportsSeatAssignment,
    required this.supportsLateRegistration,
    required this.supportsReentry,
    required this.supportsPauseForRecovery,
  });

  final bool supportsLiveJoin;
  final bool supportsLiveLeave;
  final bool supportsMidSessionReturn;
  final bool supportsPersonalLedger;
  final bool supportsReceipts;
  final bool supportsSpectators;
  final bool supportsCohosts;
  final bool supportsReloadPolicy;
  final bool supportsWaitlist;
  final bool supportsSeatAssignment;
  final bool supportsLateRegistration;
  final bool supportsReentry;
  final bool supportsPauseForRecovery;
}
