import '../models/demo_scenario_snapshot.dart';
import '../models/demo_view_models.dart';

class DemoScenarioSnapshots {
  const DemoScenarioSnapshots._();

  static const snapshots = <String, DemoScenarioSnapshot>{
    'open_table_live_turn': DemoScenarioSnapshot(
      scenarioId: 'open_table_live_turn',
      mode: 'open_table',
      variant: 'holdem_nlhe',
      networkConfidence: 'stable',
      statusBanner: DemoStatusBannerVm(
        visible: false,
        label: '',
        severity: 'none',
      ),
      chat: DemoChatSummaryVm(unreadCount: 3, disappearingEnabled: true),
      receipt: DemoReceiptSummaryVm(
        verificationState: 'verified',
        retentionMode: 'manual_wipe_allowed',
        bindingMode: 'session_bound',
      ),
    ),
    'tournament_break': DemoScenarioSnapshot(
      scenarioId: 'tournament_break',
      mode: 'tournament',
      variant: 'holdem_nlhe',
      networkConfidence: 'high',
      statusBanner: DemoStatusBannerVm(
        visible: true,
        label: 'Break - 08:00 remaining',
        severity: 'info',
      ),
      chat: DemoChatSummaryVm(unreadCount: 0, disappearingEnabled: false),
      receipt: DemoReceiptSummaryVm(
        verificationState: 'verified',
        retentionMode: 'standard',
        bindingMode: 'user_bound',
      ),
    ),
    'recovery_pause_transfer': DemoScenarioSnapshot(
      scenarioId: 'recovery_pause_transfer',
      mode: 'open_table',
      variant: 'holdem_nlhe',
      networkConfidence: 'recovery_required',
      statusBanner: DemoStatusBannerVm(
        visible: true,
        label: 'Recovery pause - primary peer transfer',
        severity: 'warning',
      ),
      chat: DemoChatSummaryVm(unreadCount: 1, disappearingEnabled: true),
      receipt: DemoReceiptSummaryVm(
        verificationState: 'pending',
        retentionMode: 'timed_sandbox',
        bindingMode: 'session_bound',
      ),
    ),
    'verification_receipt_review': DemoScenarioSnapshot(
      scenarioId: 'verification_receipt_review',
      mode: 'open_table',
      variant: 'holdem_nlhe',
      networkConfidence: 'stable',
      statusBanner: DemoStatusBannerVm(
        visible: false,
        label: '',
        severity: 'none',
      ),
      chat: DemoChatSummaryVm(unreadCount: 0, disappearingEnabled: false),
      receipt: DemoReceiptSummaryVm(
        verificationState: 'verified',
        retentionMode: 'strict_ephemeral',
        bindingMode: 'user_bound',
      ),
    ),
    'chat_heavy_table': DemoScenarioSnapshot(
      scenarioId: 'chat_heavy_table',
      mode: 'open_table',
      variant: 'holdem_nlhe',
      networkConfidence: 'stable',
      statusBanner: DemoStatusBannerVm(
        visible: false,
        label: '',
        severity: 'none',
      ),
      chat: DemoChatSummaryVm(unreadCount: 19, disappearingEnabled: true),
      receipt: DemoReceiptSummaryVm(
        verificationState: 'partial',
        retentionMode: 'manual_wipe_allowed',
        bindingMode: 'session_bound',
      ),
    ),
  };

  static DemoScenarioSnapshot byId(String scenarioId) {
    final snapshot = snapshots[scenarioId];
    if (snapshot == null) {
      throw ArgumentError.value(scenarioId, 'scenarioId', 'Unknown scenario');
    }
    return snapshot;
  }
}
