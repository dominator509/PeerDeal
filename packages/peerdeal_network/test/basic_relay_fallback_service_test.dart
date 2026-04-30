import 'package:peerdeal_network/peerdeal_network.dart';
import 'package:test/test.dart';

void main() {
  test('recommends pause when transitioning to relay during live hand', () {
    const service = BasicRelayFallbackService();

    const current = SessionPathDescriptor(
      routeClass: NetworkRouteClass.p2pRemote,
      primaryPeerId: 'peer_a',
      usesRelay: false,
      transportAgnostic: true,
      reason: 'remote',
    );

    const fallback = SessionPathDescriptor(
      routeClass: NetworkRouteClass.relay,
      primaryPeerId: 'peer_a',
      usesRelay: true,
      transportAgnostic: true,
      reason: 'relay',
    );

    final plan = service.planTransition(
      currentPath: current,
      fallbackPath: fallback,
      liveHandInProgress: true,
    );

    expect(plan.transitionNeeded, isTrue);
    expect(plan.pauseRecommended, isTrue);
  });
}
