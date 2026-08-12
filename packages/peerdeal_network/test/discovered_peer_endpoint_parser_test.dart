import 'package:peerdeal_network/peerdeal_network.dart';
import 'package:test/test.dart';

void main() {
  test('parses peer-only discovery values without inventing a host', () {
    final endpoint = DiscoveredPeerEndpointParser.parse(' peer-a ');

    expect(endpoint, isNotNull);
    expect(endpoint!.peerId, 'peer-a');
    expect(endpoint.host, isEmpty);
    expect(endpoint.port, isNull);
  });

  test('parses IPv4, DNS, and bracketed IPv6 endpoint metadata', () {
    expect(
      DiscoveredPeerEndpointParser.parse('peer-a@192.168.1.10:40442'),
      allOf([
        isA<DiscoveredPeerEndpoint>(),
        predicate<DiscoveredPeerEndpoint>(
          (endpoint) =>
              endpoint.peerId == 'peer-a' &&
              endpoint.host == '192.168.1.10' &&
              endpoint.port == 40442,
        ),
      ]),
    );
    expect(
      DiscoveredPeerEndpointParser.parse('peer-b@host.example'),
      allOf([
        isA<DiscoveredPeerEndpoint>(),
        predicate<DiscoveredPeerEndpoint>(
          (endpoint) =>
              endpoint.host == 'host.example' && endpoint.port == null,
        ),
      ]),
    );
    expect(
      DiscoveredPeerEndpointParser.parse('peer-c@[2001:db8::1]:40442')!.host,
      '2001:db8::1',
    );
  });

  test('drops malformed, sensitive, duplicate, and over-limit values', () {
    final endpoints = DiscoveredPeerEndpointParser.parseAll(<String>[
      'peer-a@192.168.1.10:40442',
      'peer-a@192.168.1.11:40442',
      'peer-b@bad host:40442',
      r'peer-c@C:\secret\endpoint',
      'peer-d@host:0',
      'peer-e',
    ], maxValues: 2);

    expect(endpoints.map((endpoint) => endpoint.peerId), ['peer-a', 'peer-e']);
  });

  test('bounds direct caller traversal while finding valid endpoints', () {
    final values = <String>[
      ...List<String>.filled(NetworkInputLimits.defaultMaxCandidates, ''),
      'peer-after-boundary',
    ];

    expect(DiscoveredPeerEndpointParser.parseAll(values), isEmpty);
  });

  test(
    'projects discovered host and port without overriding provider values',
    () {
      final endpoints = DiscoveredPeerEndpointParser.parseAll(<String>[
        'peer-a@192.168.1.10:40442',
        'peer-b@host.example:40443',
      ]);
      final candidates =
          DiscoveredPeerEndpointParser.projectCandidates(<BootstrapCandidate>[
            const BootstrapCandidate(
              peerId: 'peer-a',
              routeClass: NetworkRouteClass.lanDirect,
              reachable: true,
              priority: 2,
            ),
            const BootstrapCandidate(
              peerId: 'peer-b',
              routeClass: NetworkRouteClass.p2pRemote,
              reachable: true,
              priority: 1,
              host: 'provider.example',
              port: 40444,
            ),
          ], endpoints);

      expect(candidates[0].host, '192.168.1.10');
      expect(candidates[0].port, 40442);
      expect(candidates[1].host, 'provider.example');
      expect(candidates[1].port, 40444);
    },
  );

  test('bounds endpoint traversal during candidate projection', () {
    final endpoints = <DiscoveredPeerEndpoint>[
      ...List<DiscoveredPeerEndpoint>.generate(
        NetworkInputLimits.defaultMaxCandidates,
        (index) => DiscoveredPeerEndpoint(
          peerId: 'peer-$index',
          host: 'host-$index.example',
        ),
      ),
      const DiscoveredPeerEndpoint(
        peerId: 'peer-after-boundary',
        host: 'after-boundary.example',
      ),
    ];

    final projected =
        DiscoveredPeerEndpointParser.projectCandidates(<BootstrapCandidate>[
          const BootstrapCandidate(
            peerId: 'peer-after-boundary',
            routeClass: NetworkRouteClass.lanDirect,
            reachable: true,
            priority: 1,
          ),
        ], endpoints);

    expect(projected.single.host, isNull);
  });
}
