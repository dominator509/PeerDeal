import '../models/mode_capabilities.dart';
import '../models/mode_identity.dart';
import '../models/mode_policy_models.dart';

abstract class ModeAdapter {
  ModeIdentity getIdentity();
  ModeCapabilities getCapabilities();
  ValidationResult validateConfig(ModeConfig config);
  SessionPlan buildSessionPlan(ModeConfig config);
  JoinPolicy getJoinPolicy(ModeConfig config);
  SeatPolicy getSeatPolicy(ModeConfig config);
  LedgerPolicy getLedgerPolicy(ModeConfig config);
  ReloadPolicy getReloadPolicy(ModeConfig config);
  ClosePolicy getClosePolicy(ModeConfig config);
  ReceiptPolicy getReceiptPolicy(ModeConfig config);
  CaptureRequirements getCapturePolicyRequirements(ModeConfig config);
  GovernancePolicy getGovernancePolicy(ModeConfig config);
  ModeSummaryFacts deriveSummaryFacts(ModeConfig config);
}
