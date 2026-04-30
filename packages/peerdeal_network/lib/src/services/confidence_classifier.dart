import '../models/network_confidence.dart';
import '../models/peer_metric_snapshot.dart';

abstract class ConfidenceClassifier {
  NetworkConfidence classify(Iterable<PeerMetricSnapshot> snapshots);
}
