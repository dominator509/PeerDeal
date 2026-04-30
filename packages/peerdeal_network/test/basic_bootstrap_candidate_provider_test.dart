import 'package:peerdeal_network/peerdeal_network.dart';
import 'package:test/test.dart';

void main() {
  test('creates candidates from peer ids with lan-preferred first candidate', () async {
    const provider = BasicBootstrapCandidateProvider();
    final result = await provider.resolveCandidates(
      const BootstrapResolutionRequest(
        sessionId: 'sess_1',
        tableId: 'table_1',
        preferLan: true,
        relayAllowed: true,
        peerIds: ['peer_a', 'peer_b'],
      ),
    );

    expect(result, hasLength(2));
    expect(result.first.routeClass, NetworkRouteClass.lanDirect);
  });
}
