import '../models/primary_peer_decision.dart';
import '../models/primary_peer_transfer_plan.dart';

abstract class TransferPolicy {
  PrimaryPeerTransferPlan? buildPlan({
    required String currentPrimaryPeerId,
    required PrimaryPeerDecision decision,
  });
}
