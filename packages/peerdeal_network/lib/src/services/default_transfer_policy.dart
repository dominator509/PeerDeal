import '../models/network_confidence.dart';
import '../models/network_input_limits.dart';
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
    if (!decision.requiresTransfer ||
        !_isOperationalPeerId(currentPrimaryPeerId) ||
        !_isOperationalPeerId(decision.primaryPeerId) ||
        decision.primaryPeerId == currentPrimaryPeerId) {
      return null;
    }

    final requiresPause =
        decision.confidence == NetworkConfidence.recoveryRequired ||
        decision.confidence == NetworkConfidence.unsafe;

    return PrimaryPeerTransferPlan(
      fromPeerId: currentPrimaryPeerId,
      toPeerId: decision.primaryPeerId,
      reason: decision.reason,
      requiresPause: requiresPause,
      freezeOperationalEvents: true,
    );
  }

  bool _isOperationalPeerId(String peerId) {
    if (!NetworkInputLimits.isSafePeerIdentity(peerId)) return false;
    if (peerId == 'none' || peerId == 'unresolved') return false;
    if (peerId.contains('::')) return false;
    return true;
  }
}
