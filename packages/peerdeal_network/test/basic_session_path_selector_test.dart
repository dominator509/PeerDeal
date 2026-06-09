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

  test('selects documented remoteDirect route as a direct path', () {
    const selector = BasicSessionPathSelector();
    final result = selector.selectPath(
      candidates: const [
        BootstrapCandidate(
          peerId: 'peer_remote',
          routeClass: NetworkRouteClass.remoteDirect,
          reachable: true,
          priority: 10,
        ),
      ],
      preferLan: false,
      relayAllowed: true,
    );

    expect(result.routeClass, NetworkRouteClass.remoteDirect);
    expect(result.primaryPeerId, 'peer_remote');
    expect(result.usesRelay, isFalse);
  });

  test(
    'orders equal-priority candidates deterministically by route then peer',
    () {
      const selector = BasicSessionPathSelector();
      final result = selector.selectPath(
        candidates: const [
          BootstrapCandidate(
            peerId: 'peer_relay',
            routeClass: NetworkRouteClass.relayFallback,
            reachable: true,
            priority: 10,
          ),
          BootstrapCandidate(
            peerId: 'peer_b',
            routeClass: NetworkRouteClass.remoteDirect,
            reachable: true,
            priority: 10,
          ),
          BootstrapCandidate(
            peerId: 'peer_a',
            routeClass: NetworkRouteClass.remoteDirect,
            reachable: true,
            priority: 10,
          ),
        ],
        preferLan: false,
        relayAllowed: true,
      );

      expect(result.routeClass, NetworkRouteClass.remoteDirect);
      expect(result.primaryPeerId, 'peer_a');
      expect(result.usesRelay, isFalse);
    },
  );

  test('does not claim relay use when no reachable relay candidate exists', () {
    const selector = BasicSessionPathSelector();
    final result = selector.selectPath(
      candidates: const [
        BootstrapCandidate(
          peerId: 'peer_unreachable',
          routeClass: NetworkRouteClass.relayFallback,
          reachable: false,
          priority: 10,
        ),
      ],
      preferLan: false,
      relayAllowed: true,
    );

    expect(result.primaryPeerId, 'unresolved');
    expect(result.usesRelay, isFalse);
    expect(result.reason, 'no_direct_candidate_available');
  });

  test('drops malformed reachable candidates before path selection', () {
    const selector = BasicSessionPathSelector();
    final result = selector.selectPath(
      candidates: const [
        BootstrapCandidate(
          peerId: ' peer_padded',
          routeClass: NetworkRouteClass.lanDirect,
          reachable: true,
          priority: 20,
        ),
        BootstrapCandidate(
          peerId: 'peer_remote',
          routeClass: NetworkRouteClass.remoteDirect,
          reachable: true,
          priority: 10,
        ),
      ],
      preferLan: true,
      relayAllowed: true,
    );

    expect(result.routeClass, NetworkRouteClass.remoteDirect);
    expect(result.primaryPeerId, 'peer_remote');
    expect(result.reason, 'selected_remote_p2p_path');
  });

  test('ignores malformed elected primary peer id', () {
    const selector = BasicSessionPathSelector();
    final result = selector.selectPath(
      candidates: const [
        BootstrapCandidate(
          peerId: 'peer_a',
          routeClass: NetworkRouteClass.remoteDirect,
          reachable: true,
          priority: 10,
        ),
      ],
      preferLan: false,
      relayAllowed: true,
      electedPrimaryPeerId: 'peer_primary\nsecret',
    );

    expect(result.primaryPeerId, 'peer_a');
  });

  test('returns unresolved when only malformed peers are available', () {
    const selector = BasicSessionPathSelector();
    final result = selector.selectPath(
      candidates: const [
        BootstrapCandidate(
          peerId: '',
          routeClass: NetworkRouteClass.relayFallback,
          reachable: true,
          priority: 10,
        ),
      ],
      preferLan: false,
      relayAllowed: true,
      electedPrimaryPeerId: ' peer_padded',
    );

    expect(result.primaryPeerId, 'unresolved');
    expect(result.reason, 'no_direct_candidate_available');
    expect(result.usesRelay, isFalse);
  });
}
