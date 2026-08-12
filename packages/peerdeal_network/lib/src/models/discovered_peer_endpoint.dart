/// A validated endpoint location discovered for one peer.
///
/// The native bridge transports endpoint locations as opaque strings. This
/// model is the network-owned typed form used before bootstrap candidate
/// selection; it does not imply that the endpoint has been reached.
class DiscoveredPeerEndpoint {
  const DiscoveredPeerEndpoint({
    required this.peerId,
    required this.host,
    this.port,
  });

  final String peerId;
  final String host;
  final int? port;
}
