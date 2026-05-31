import 'local_network_bridge_models.dart';

class LocalNetworkChannelContract {
  const LocalNetworkChannelContract._();

  static const channelName = 'peerdeal/native_bridges/local_network';
  static const getCapabilityMethod = 'getCapability';
  static const discoverPeersMethod = 'discoverPeers';

  static LocalNetworkCapability decodeCapability(
    Map<String, Object?>? payload,
  ) {
    if (payload == null) {
      return const LocalNetworkCapability.unavailable(
        warning: 'Local network capability is unavailable.',
      );
    }

    return LocalNetworkCapability(
      discoverySupported: (payload['discoverySupported'] as bool?) ?? false,
      permissionPromptSupported:
          (payload['permissionPromptSupported'] as bool?) ?? false,
      broadcastSupported: (payload['broadcastSupported'] as bool?) ?? false,
      notes: (payload['notes'] as String?) ?? 'unavailable',
      warning: payload['warning'] as String?,
    );
  }

  static LocalNetworkDiscoverySnapshot decodeDiscoverySnapshot(
    Map<String, Object?>? payload,
  ) {
    if (payload == null) {
      return const LocalNetworkDiscoverySnapshot.unavailable(
        warning: 'Local network discovery is unavailable.',
      );
    }

    return LocalNetworkDiscoverySnapshot(
      permissionGranted: (payload['permissionGranted'] as bool?) ?? false,
      foundEndpoints: (payload['foundEndpoints'] as List<dynamic>? ?? const [])
          .map((endpoint) => endpoint.toString())
          .toList(growable: false),
      interfaceHints: (payload['interfaceHints'] as List<dynamic>? ?? const [])
          .map((hint) => hint.toString())
          .toList(growable: false),
      warning: payload['warning'] as String?,
    );
  }
}
