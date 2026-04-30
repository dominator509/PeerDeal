import '../contracts/mode_adapter.dart';
import '../models/mode_capabilities.dart';
import '../models/mode_identity.dart';
import '../models/mode_policy_models.dart';

class OpenTableModeAdapter implements ModeAdapter {
  const OpenTableModeAdapter();

  @override
  ModeIdentity getIdentity() => const ModeIdentity(
        modeId: 'open_table',
        modeFamily: 'open_table',
        displayName: 'Open Table Mode',
        adapterVersion: '0.1.0',
        protocolVersionRange: '1.x',
        gameFileVersionRange: '1.x',
      );

  @override
  ModeCapabilities getCapabilities() => const ModeCapabilities(
        supportsLiveJoin: true,
        supportsLiveLeave: true,
        supportsMidSessionReturn: true,
        supportsPersonalLedger: true,
        supportsReceipts: true,
        supportsSpectators: true,
        supportsCohosts: true,
        supportsReloadPolicy: true,
        supportsWaitlist: true,
        supportsSeatAssignment: true,
        supportsLateRegistration: false,
        supportsReentry: false,
        supportsPauseForRecovery: true,
      );

  @override
  ValidationResult validateConfig(ModeConfig config) {
    final errors = <String>[];
    if (config.modeType != 'open_table') {
      errors.add('OpenTableModeAdapter requires modeType=open_table.');
    }
    if (config.reloadPolicy == 'tournament_reentry') {
      errors.add('Open Table Mode cannot use tournament reentry reload policy.');
    }
    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  @override
  SessionPlan buildSessionPlan(ModeConfig config) => const SessionPlan(
        sessionOwnershipModel: 'table_owned',
        openCondition: 'host_opens_table',
        closeCondition: 'table_closed_or_broken',
        receiptFinalizationTiming: 'session_close',
        wipeExpectation: 'retention_policy_driven',
      );

  @override
  JoinPolicy getJoinPolicy(ModeConfig config) => JoinPolicy(
        allowPreStartJoin: true,
        allowLiveJoin: true,
        allowReturn: true,
        allowSpectators: config.allowSpectators,
        lateRegistrationEnabled: false,
      );

  @override
  SeatPolicy getSeatPolicy(ModeConfig config) => const SeatPolicy(
        waitlistEnabled: true,
        allowMidSessionSeatClaim: true,
        betweenHandsOnlySeatChanges: true,
        protectRecoveryHeldSeats: true,
      );

  @override
  LedgerPolicy getLedgerPolicy(ModeConfig config) => const LedgerPolicy(
        ledgerEnabled: true,
        allowSimulatedReloads: true,
        allowCloseout: true,
        exportAtClose: true,
        summaryLabel: 'open_table_private_ledger',
      );

  @override
  ReloadPolicy getReloadPolicy(ModeConfig config) => ReloadPolicy(
        policyType: config.reloadPolicy,
        allowed: config.reloadPolicy != 'disabled',
      );

  @override
  ClosePolicy getClosePolicy(ModeConfig config) => const ClosePolicy(
        triggerType: 'host_closes_table',
        finishCurrentHand: true,
        sessionSummaryOutput: 'open_table_session_summary',
      );

  @override
  ReceiptPolicy getReceiptPolicy(ModeConfig config) => const ReceiptPolicy(
        receiptsRequired: true,
        sessionReceiptsEnabled: true,
        seatReceiptsEnabled: false,
        privateLedgerExportEnabled: true,
        sharedViewMode: 'private_plus_shared_view',
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
        cohostCanApproveReload: true,
      );

  @override
  ModeSummaryFacts deriveSummaryFacts(ModeConfig config) => const ModeSummaryFacts(
        modeLabel: 'Open Table Mode',
        sessionSummaryKind: 'open_table',
      );
}
