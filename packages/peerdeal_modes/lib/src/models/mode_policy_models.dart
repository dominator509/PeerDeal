class ValidationResult {
  ValidationResult({
    required this.isValid,
    List<String> warnings = const <String>[],
    List<String> errors = const <String>[],
  }) : warnings = List<String>.unmodifiable(warnings),
       errors = List<String>.unmodifiable(errors);

  final bool isValid;
  final List<String> warnings;
  final List<String> errors;
}

class SessionPlan {
  const SessionPlan({
    required this.sessionOwnershipModel,
    required this.openCondition,
    required this.closeCondition,
    required this.receiptFinalizationTiming,
    required this.wipeExpectation,
  });

  final String sessionOwnershipModel;
  final String openCondition;
  final String closeCondition;
  final String receiptFinalizationTiming;
  final String wipeExpectation;
}

class JoinPolicy {
  const JoinPolicy({
    required this.allowPreStartJoin,
    required this.allowLiveJoin,
    required this.allowReturn,
    required this.allowSpectators,
    required this.lateRegistrationEnabled,
  });

  final bool allowPreStartJoin;
  final bool allowLiveJoin;
  final bool allowReturn;
  final bool allowSpectators;
  final bool lateRegistrationEnabled;
}

class SeatPolicy {
  const SeatPolicy({
    required this.waitlistEnabled,
    required this.allowMidSessionSeatClaim,
    required this.betweenHandsOnlySeatChanges,
    required this.protectRecoveryHeldSeats,
  });

  final bool waitlistEnabled;
  final bool allowMidSessionSeatClaim;
  final bool betweenHandsOnlySeatChanges;
  final bool protectRecoveryHeldSeats;
}

class LedgerPolicy {
  const LedgerPolicy({
    required this.ledgerEnabled,
    required this.allowSimulatedReloads,
    required this.allowCloseout,
    required this.exportAtClose,
    required this.summaryLabel,
  });

  final bool ledgerEnabled;
  final bool allowSimulatedReloads;
  final bool allowCloseout;
  final bool exportAtClose;
  final String summaryLabel;
}

class ReloadPolicy {
  const ReloadPolicy({required this.policyType, required this.allowed});

  final String policyType;
  final bool allowed;
}

class ClosePolicy {
  const ClosePolicy({
    required this.triggerType,
    required this.finishCurrentHand,
    required this.sessionSummaryOutput,
  });

  final String triggerType;
  final bool finishCurrentHand;
  final String sessionSummaryOutput;
}

class ReceiptPolicy {
  const ReceiptPolicy({
    required this.receiptsRequired,
    required this.sessionReceiptsEnabled,
    required this.seatReceiptsEnabled,
    required this.privateLedgerExportEnabled,
    required this.sharedViewMode,
  });

  final bool receiptsRequired;
  final bool sessionReceiptsEnabled;
  final bool seatReceiptsEnabled;
  final bool privateLedgerExportEnabled;
  final String sharedViewMode;
}

class CaptureRequirements {
  const CaptureRequirements({
    required this.strictSensitiveViews,
    required this.configurableTableCapture,
    required this.noticeHonestyRequired,
  });

  final bool strictSensitiveViews;
  final bool configurableTableCapture;
  final bool noticeHonestyRequired;
}

class GovernancePolicy {
  const GovernancePolicy({
    required this.allowSpectators,
    required this.allowCohosts,
    required this.cohostCanManageWaitlist,
    required this.cohostCanApproveReload,
  });

  final bool allowSpectators;
  final bool allowCohosts;
  final bool cohostCanManageWaitlist;
  final bool cohostCanApproveReload;
}

class ModeSummaryFacts {
  const ModeSummaryFacts({
    required this.modeLabel,
    required this.sessionSummaryKind,
  });

  final String modeLabel;
  final String sessionSummaryKind;
}

class ModeConfig {
  const ModeConfig({
    required this.modeType,
    this.allowSpectators = true,
    this.allowCohosts = true,
    this.lateRegistrationEnabled = false,
    this.reentryEnabled = false,
    this.reloadPolicy = 'disabled',
  });

  final String modeType;
  final bool allowSpectators;
  final bool allowCohosts;
  final bool lateRegistrationEnabled;
  final bool reentryEnabled;
  final String reloadPolicy;
}
