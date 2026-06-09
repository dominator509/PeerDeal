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
      discoverySupported: _boolValue(payload['discoverySupported']),
      permissionPromptSupported: _boolValue(
        payload['permissionPromptSupported'],
      ),
      broadcastSupported: _boolValue(payload['broadcastSupported']),
      notes: _stringValue(payload['notes']) ?? 'unavailable',
      warning: _stringValue(payload['warning']),
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
      permissionGranted: _boolValue(payload['permissionGranted']),
      foundEndpoints: _stringListValue(payload['foundEndpoints']),
      interfaceHints: _stringListValue(payload['interfaceHints']),
      warning: _stringValue(payload['warning']),
    );
  }

  static bool _boolValue(Object? value) => value is bool ? value : false;

  static String? _stringValue(Object? value) => value is String ? value : null;

  static List<dynamic> _listValue(Object? value) =>
      value is List<dynamic> ? value : const <dynamic>[];

  static List<String> _stringListValue(Object? value) => _listValue(value)
      .whereType<String>()
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}
