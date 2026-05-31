import 'package:peerdeal_network/peerdeal_network.dart';

import '../models/demo_scenario_snapshot.dart';

class DemoNetworkConfidenceVm {
  const DemoNetworkConfidenceVm({
    required this.confidence,
    required this.recoveryRecommended,
  });

  final NetworkConfidence confidence;
  final bool recoveryRecommended;
}

class DemoNetworkConfidencePresenter {
  const DemoNetworkConfidencePresenter({
    ConfidenceClassifier classifier = const DefaultConfidenceClassifier(),
  }) : _classifier = classifier;

  final ConfidenceClassifier _classifier;

  DemoNetworkConfidenceVm present(DemoScenarioSnapshot snapshot) {
    final confidence = _classifier.classify(_metricsFor(snapshot));
    return DemoNetworkConfidenceVm(
      confidence: confidence,
      recoveryRecommended: confidence == NetworkConfidence.recoveryRequired,
    );
  }

  List<PeerMetricSnapshot> _metricsFor(DemoScenarioSnapshot snapshot) {
    switch (snapshot.networkConfidence) {
      case 'high':
        return const <PeerMetricSnapshot>[
          PeerMetricSnapshot(
            peerId: 'demo_primary',
            routeClass: NetworkRouteClass.lanDirect,
            avgLatencyMs: 20,
            ackLagMs: 40,
            disconnectsInWindow: 0,
            reachabilityCount: 3,
            eventIndexLag: 0,
            anchorAligned: true,
          ),
        ];
      case 'stable':
        return const <PeerMetricSnapshot>[
          PeerMetricSnapshot(
            peerId: 'demo_primary',
            routeClass: NetworkRouteClass.remoteDirect,
            avgLatencyMs: 220,
            ackLagMs: 300,
            disconnectsInWindow: 0,
            reachabilityCount: 2,
            eventIndexLag: 0,
            anchorAligned: true,
          ),
        ];
      case 'recovery_required':
        return const <PeerMetricSnapshot>[
          PeerMetricSnapshot(
            peerId: 'demo_primary',
            routeClass: NetworkRouteClass.remoteDirect,
            avgLatencyMs: 90,
            ackLagMs: 140,
            disconnectsInWindow: 0,
            reachabilityCount: 2,
            eventIndexLag: 3,
            anchorAligned: true,
          ),
        ];
      case 'degraded':
        return const <PeerMetricSnapshot>[
          PeerMetricSnapshot(
            peerId: 'demo_primary',
            routeClass: NetworkRouteClass.remoteDirect,
            avgLatencyMs: 90,
            ackLagMs: 140,
            disconnectsInWindow: 0,
            reachabilityCount: 2,
            eventIndexLag: 1,
            anchorAligned: true,
          ),
        ];
    }

    return const <PeerMetricSnapshot>[];
  }
}
