import 'package:peerdeal_network/peerdeal_network.dart';
import 'package:test/test.dart';

void main() {
  test('round trips bounded query and advertisement packets', () {
    final query = LanDiscoveryProtocol.decode(
      LanDiscoveryProtocol.encodeQuery(),
    );
    expect(query?.kind, LanDiscoveryPacketKind.query);
    expect(query?.peerId, isNull);
    expect(query?.port, isNull);

    final encoded = LanDiscoveryProtocol.encodeAdvertisement(
      peerId: 'peer-a',
      port: 40442,
    );
    expect(encoded, isNotNull);
    final advertisement = LanDiscoveryProtocol.decode(encoded!);
    expect(advertisement?.kind, LanDiscoveryPacketKind.advertisement);
    expect(advertisement?.peerId, 'peer-a');
    expect(advertisement?.port, 40442);
  });

  test('rejects malformed, reserved, and oversized advertisements', () {
    expect(LanDiscoveryProtocol.encodeAdvertisement(peerId: 'none'), isNull);
    expect(
      LanDiscoveryProtocol.encodeAdvertisement(peerId: 'peer-a', port: 0),
      isNull,
    );
    expect(
      LanDiscoveryProtocol.encodeAdvertisement(
        peerId: 'a' * (NetworkInputLimits.maxPeerIdentityBytes + 1),
      ),
      isNull,
    );

    final query = LanDiscoveryProtocol.encodeQuery();
    expect(LanDiscoveryProtocol.decode(<int>[...query, 0]), isNull);

    final encodedAdvertisement = LanDiscoveryProtocol.encodeAdvertisement(
      peerId: 'peer-a',
    )!;
    final malformedAdvertisement = <int>[...encodedAdvertisement];
    malformedAdvertisement[0] = 0;
    expect(LanDiscoveryProtocol.decode(malformedAdvertisement), isNull);
  });

  test('does not mutate encoded packets through returned collections', () {
    final query = LanDiscoveryProtocol.encodeQuery();
    expect(() => query[0] = 0, throwsUnsupportedError);
  });
}
