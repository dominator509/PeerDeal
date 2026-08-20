import 'package:peerdeal_network/peerdeal_network.dart';
import 'package:test/test.dart';

void main() {
  test('fails closed when the peer-id window exceeds its limit', () async {
    const provider = BasicBootstrapCandidateProvider(maxPeerIds: 2);
    final result = await provider.resolveCandidates(
      BootstrapResolutionRequest(
        sessionId: 'sess_1',
        tableId: 'table_1',
        preferLan: true,
        relayAllowed: true,
        peerIds: ['peer_a', 'peer_b', 'peer_c'],
      ),
    );

    expect(result, isEmpty);
  });

  test(
    'creates candidates from peer ids with lan-preferred first candidate',
    () async {
      const provider = BasicBootstrapCandidateProvider();
      final result = await provider.resolveCandidates(
        BootstrapResolutionRequest(
          sessionId: 'sess_1',
          tableId: 'table_1',
          preferLan: true,
          relayAllowed: true,
          peerIds: ['peer_a', 'peer_b'],
        ),
      );

      expect(result, hasLength(2));
      expect(result.first.routeClass, NetworkRouteClass.lanDirect);
    },
  );

  test('drops malformed peer ids before candidate selection', () async {
    const provider = BasicBootstrapCandidateProvider();
    final result = await provider.resolveCandidates(
      BootstrapResolutionRequest(
        sessionId: 'sess_1',
        tableId: 'table_1',
        preferLan: true,
        relayAllowed: true,
        peerIds: ['', ' peer_padded', 'peer_a\nsecret', 'peer_b'],
      ),
    );

    expect(result, hasLength(1));
    expect(result.single.peerId, 'peer_b');
    expect(result.single.routeClass, NetworkRouteClass.lanDirect);
    expect(result.single.priority, 1);
  });

  test('fails closed on malformed session or table scope identities', () async {
    const provider = BasicBootstrapCandidateProvider();
    final invalidSession = await provider.resolveCandidates(
      BootstrapResolutionRequest(
        sessionId: 'session\nsecret',
        tableId: 'table_1',
        preferLan: true,
        relayAllowed: true,
        peerIds: <String>['peer_a'],
      ),
    );
    final invalidTable = await provider.resolveCandidates(
      BootstrapResolutionRequest(
        sessionId: 'session_1',
        tableId: ' table_1',
        preferLan: true,
        relayAllowed: true,
        peerIds: <String>['peer_a'],
      ),
    );

    expect(invalidSession, isEmpty);
    expect(invalidTable, isEmpty);
  });

  test('deduplicates exact peer ids before assigning priorities', () async {
    const provider = BasicBootstrapCandidateProvider();
    final result = await provider.resolveCandidates(
      BootstrapResolutionRequest(
        sessionId: 'sess_1',
        tableId: 'table_1',
        preferLan: false,
        relayAllowed: true,
        peerIds: ['peer_a', 'peer_b', 'peer_a'],
      ),
    );

    expect(result.map((candidate) => candidate.peerId), ['peer_a', 'peer_b']);
    expect(result.map((candidate) => candidate.priority), [2, 1]);
  });
}
