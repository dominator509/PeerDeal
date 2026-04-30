import '../contracts/mode_adapter.dart';
import '../models/mode_capabilities.dart';
import '../models/mode_identity.dart';
import '../models/mode_policy_models.dart';

class TournamentModeAdapter implements ModeAdapter {
  const TournamentModeAdapter();

  @override
  ModeIdentity getIdentity() => const ModeIdentity(
        modeId: 'tournament',
        modeFamily: 'tournament',
        displayName: 'Tournament Mode',
        adapterVersion: '0.1.0',
        protocolVersionRange: '1.x',
        gameFileVersionRange: '1.x',
      );

  @override
  ModeCapabilities getCapabilities() => const ModeCapabilities(
        supportsLiveJoin: false,
        supportsLiveLeave: true,
        supportsMidSessionReturn: false,
        supportsPersonalLedger: false,
        supportsReceipts: true,
        supportsSpectators: true,
        supportsCohosts: true,
        supportsReloadPolicy: false,
        supportsWaitlist: true,
        supportsSeatAssignment: true,
        supportsLateRegistration: true,
        supportsReentry: true,
        supportsPauseForRecovery: true,
      );

  @override
  ValidationResult validateConfig(ModeConfig config) {
    final errors = <String>[];
    if (config.modeType != 'tournament') {
      errors.add('TournamentModeAdapter requires modeType=tournament.');
    }
    if (config.reloadPolicy == 'unlimited') {
      errors.add('Tournament Mode cannot use unlimited reload policy.');
    }
    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  @override
  SessionPlan buildSessionPlan(ModeConfig config) => const SessionPlan(
        sessionOwnershipModel: 'tournament_owned',
        openCondition: 'tournament_started',
        closeCondition: 'completion_or_manual_close',
        receiptFinalizationTiming: 'tournament_close',
        wipeExpectation: 'retention_policy_driven',
      );

  @override
  JoinPolicy getJoinPolicy(ModeConfig config) => JoinPolicy(
        allowPreStartJoin: true,
        allowLiveJoin: config.lateRegistrationEnabled,
        allowReturn: false,
        allowSpectators: config.allowSpectators,
        lateRegistrationEnabled: config.lateRegistrationEnabled,
      );

  @override
  SeatPolicy getSeatPolicy(ModeConfig config) => const SeatPolicy(
        waitlistEnabled: true,
        allowMidSessionSeatClaim: false,
        betweenHandsOnlySeatChanges: true,
        protectRecoveryHeldSeats: true,
      );

  @override
  LedgerPolicy getLedgerPolicy(ModeConfig config) => const LedgerPolicy(
        ledgerEnabled: false,
        allowSimulatedReloads: false,
        allowCloseout: false,
        exportAtClose: true,
        summaryLabel: 'tournament_results_summary',
      );

  @override
  ReloadPolicy getReloadPolicy(ModeConfig config) => ReloadPolicy(
        policyType: config.reentryEnabled ? 'reentry' : 'disabled',
        allowed: config.reentryEnabled,
      );

  @override
  ClosePolicy getClosePolicy(ModeConfig config) => const ClosePolicy(
        triggerType: 'tournament_completion',
        finishCurrentHand: true,
        sessionSummaryOutput: 'tournament_summary',
      );

  @override
  ReceiptPolicy getReceiptPolicy(ModeConfig config) => const ReceiptPolicy(
        receiptsRequired: true,
        sessionReceiptsEnabled: true,
        seatReceiptsEnabled: true,
        privateLedgerExportEnabled: false,
        sharedViewMode: 'private_only',
      );

  @override
  CaptureRequirements getCapturePolicyRequirements(ModeConfig config) =>
      const CaptureRequirements(
        strictSensitiveViews: true,
        configurableTableCapture: true,
        noticeHonestyRequired: true,
      );

  @override
  GovernancePolicy getGovernancePolicy(ModeConfig config) => GovernancePolicy(
        allowSpectators: config.allowSpectators,
        allowCohosts: config.allowCohosts,
        cohostCanManageWaitlist: true,
        cohostCanApproveReload: false,
      );

  @override
  ModeSummaryFacts deriveSummaryFacts(ModeConfig config) => const ModeSummaryFacts(
        modeLabel: 'Tournament Mode',
        sessionSummaryKind: 'tournament',
      );
}
