import '../models/network_confidence.dart';
import '../models/primary_peer_decision.dart';
import '../models/primary_peer_transfer_plan.dart';
import 'transfer_policy.dart';

class DefaultTransferPolicy implements TransferPolicy {
  const DefaultTransferPolicy();

  @override
  PrimaryPeerTransferPlan? buildPlan({
    required String currentPrimaryPeerId,
    required PrimaryPeerDecision decision,
  }) {
    if (!decision.requiresTransfer || decision.primaryPeerId == currentPrimaryPeerId) {
      return null;
    }

    final requiresPause = decision.confidence == NetworkConfidence.recoveryRequired ||
        decision.confidence == NetworkConfidence.unsafe;

    return PrimaryPeerTransferPlan(
      fromPeerId: currentPrimaryPeerId,
      toPeerId: decision.primaryPeerId,
      reason: decision.reason,
      requiresPause: requiresPause,
      freezeOperationalEvents: true,
    );
  }
}
