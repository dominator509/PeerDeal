import 'package:peerdeal_network/peerdeal_network.dart';
import 'package:test/test.dart';

void main() {
  test('selects LAN path when preferLan and LAN candidate exists', () {
    const selector = BasicSessionPathSelector();
    final result = selector.selectPath(
      candidates: const [
        BootstrapCandidate(
          peerId: 'peer_a',
          routeClass: NetworkRouteClass.lanDirect,
          reachable: true,
          priority: 10,
        ),
        BootstrapCandidate(
          peerId: 'peer_b',
          routeClass: NetworkRouteClass.p2pRemote,
          reachable: true,
          priority: 8,
        ),
      ],
      preferLan: true,
      relayAllowed: true,
      electedPrimaryPeerId: 'peer_a',
    );

    expect(result.routeClass, NetworkRouteClass.lanDirect);
    expect(result.usesRelay, isFalse);
  });
}
