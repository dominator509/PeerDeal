import '../models/network_confidence.dart';
import '../models/network_input_limits.dart';
import '../models/peer_metric_snapshot.dart';
import 'confidence_classifier.dart';

class DefaultConfidenceClassifier implements ConfidenceClassifier {
  const DefaultConfidenceClassifier({
    this.maxSnapshots = NetworkInputLimits.defaultMaxPeerMetrics,
  });

  final int maxSnapshots;

  @override
  NetworkConfidence classify(Iterable<PeerMetricSnapshot> snapshots) {
    _validatePositiveLimit(maxSnapshots, 'maxSnapshots');
    final items = <PeerMetricSnapshot>[];
    for (final snapshot in snapshots) {
      if (items.length >= maxSnapshots) {
        return NetworkConfidence.unsafe;
      }
      if (!snapshot.hasValidMeasurements) {
        return NetworkConfidence.unsafe;
      }
      items.add(snapshot);
    }
    if (items.isEmpty) return NetworkConfidence.unsafe;

    final anyAnchorMismatch = items.any((s) => !s.anchorAligned);
    if (anyAnchorMismatch) return NetworkConfidence.recoveryRequired;

    final anySevereEventLag = items.any((s) => s.eventIndexLag >= 3);
    if (anySevereEventLag) return NetworkConfidence.recoveryRequired;

    final anyEventLag = items.any((s) => s.eventIndexLag > 0);
    if (anyEventLag) return NetworkConfidence.degraded;

    final highLag = items.any(
      (s) => s.avgLatencyMs >= 800 || s.ackLagMs >= 1000,
    );
    if (highLag) return NetworkConfidence.degraded;

    final anyDisconnectHeavy = items.any((s) => s.disconnectsInWindow >= 3);
    if (anyDisconnectHeavy) return NetworkConfidence.degraded;

    final allFast = items.every(
      (s) => s.avgLatencyMs < 150 && s.ackLagMs < 250,
    );
    if (allFast) return NetworkConfidence.high;

    return NetworkConfidence.stable;
  }
}

void _validatePositiveLimit(int value, String name) {
  if (value <= 0) {
    throw ArgumentError.value(value, name, 'must be positive');
  }
}
