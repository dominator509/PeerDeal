import 'package:peerdeal_network/peerdeal_network.dart';
import 'package:test/test.dart';

void main() {
  test('returns unsafe when the peer-metric window exceeds its limit', () {
    const classifier = DefaultConfidenceClassifier(maxSnapshots: 2);
    final result = classifier.classify(
      List<PeerMetricSnapshot>.generate(
        3,
        (index) => PeerMetricSnapshot(
          peerId: 'peer_$index',
          routeClass: NetworkRouteClass.remoteDirect,
          avgLatencyMs: 20,
          ackLagMs: 30,
          disconnectsInWindow: 0,
          reachabilityCount: 2,
          eventIndexLag: 0,
          anchorAligned: true,
        ),
      ),
    );

    expect(result, NetworkConfidence.unsafe);
  });

  test('returns high for fast aligned peers', () {
    const classifier = DefaultConfidenceClassifier();

    final result = classifier.classify(const [
      PeerMetricSnapshot(
        peerId: 'a',
        routeClass: NetworkRouteClass.remoteDirect,
        avgLatencyMs: 90,
        ackLagMs: 140,
        disconnectsInWindow: 0,
        reachabilityCount: 3,
        eventIndexLag: 0,
        anchorAligned: true,
      ),
      PeerMetricSnapshot(
        peerId: 'b',
        routeClass: NetworkRouteClass.lanDirect,
        avgLatencyMs: 20,
        ackLagMs: 40,
        disconnectsInWindow: 0,
        reachabilityCount: 3,
        eventIndexLag: 0,
        anchorAligned: true,
      ),
    ]);

    expect(result, NetworkConfidence.high);
  });

  test('returns recoveryRequired on anchor mismatch', () {
    const classifier = DefaultConfidenceClassifier();

    final result = classifier.classify(const [
      PeerMetricSnapshot(
        peerId: 'a',
        routeClass: NetworkRouteClass.remoteDirect,
        avgLatencyMs: 90,
        ackLagMs: 140,
        disconnectsInWindow: 0,
        reachabilityCount: 3,
        eventIndexLag: 0,
        anchorAligned: false,
      ),
    ]);

    expect(result, NetworkConfidence.recoveryRequired);
  });

  test('returns degraded for shallow event-index lag', () {
    const classifier = DefaultConfidenceClassifier();

    final result = classifier.classify(const [
      PeerMetricSnapshot(
        peerId: 'a',
        routeClass: NetworkRouteClass.remoteDirect,
        avgLatencyMs: 90,
        ackLagMs: 140,
        disconnectsInWindow: 0,
        reachabilityCount: 3,
        eventIndexLag: 1,
        anchorAligned: true,
      ),
    ]);

    expect(result, NetworkConfidence.degraded);
  });

  test('returns recoveryRequired for severe event-index lag', () {
    const classifier = DefaultConfidenceClassifier();

    final result = classifier.classify(const [
      PeerMetricSnapshot(
        peerId: 'a',
        routeClass: NetworkRouteClass.remoteDirect,
        avgLatencyMs: 90,
        ackLagMs: 140,
        disconnectsInWindow: 0,
        reachabilityCount: 3,
        eventIndexLag: 3,
        anchorAligned: true,
      ),
    ]);

    expect(result, NetworkConfidence.recoveryRequired);
  });
}
