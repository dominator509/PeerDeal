import '../models/peer_metric_snapshot.dart';
import '../models/primary_peer_decision.dart';

abstract class PrimaryPeerElectionService {
  PrimaryPeerDecision elect({
    required Iterable<PeerMetricSnapshot> snapshots,
    required int baselineEventIndex,
    required String expectedAnchorHash,
    String? currentPrimaryPeerId,
  });
}
