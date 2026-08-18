import 'network_route_class.dart';

class PeerMetricSnapshot {
  const PeerMetricSnapshot({
    required this.peerId,
    required this.routeClass,
    required this.avgLatencyMs,
    required this.ackLagMs,
    required this.disconnectsInWindow,
    required this.reachabilityCount,
    required this.eventIndexLag,
    required this.anchorAligned,
    this.backgroundRisk = false,
    this.snapshotServeMs = 0,
  });

  final String peerId;
  final NetworkRouteClass routeClass;
  final int avgLatencyMs;
  final int ackLagMs;
  final int disconnectsInWindow;
  final int reachabilityCount;
  final int eventIndexLag;
  final bool anchorAligned;
  final bool backgroundRisk;
  final int snapshotServeMs;

  /// Whether every measured duration and counter is physically meaningful.
  ///
  /// Negative values are not an "unknown" sentinel in this model. Treating
  /// them as valid would let malformed input improve a peer's score.
  bool get hasValidMeasurements =>
      avgLatencyMs >= 0 &&
      ackLagMs >= 0 &&
      disconnectsInWindow >= 0 &&
      reachabilityCount >= 0 &&
      eventIndexLag >= 0 &&
      snapshotServeMs >= 0;
}
