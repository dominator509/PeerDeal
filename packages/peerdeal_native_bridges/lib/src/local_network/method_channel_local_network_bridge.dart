import 'package:flutter/services.dart';

import 'local_network_bridge.dart';
import 'local_network_bridge_models.dart';

class MethodChannelLocalNetworkBridge implements LocalNetworkBridge {
  MethodChannelLocalNetworkBridge({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(_channelName);

  static const _channelName = 'peerdeal/native_bridges/local_network';

  final MethodChannel _channel;

  @override
  Future<LocalNetworkCapability> getCapability() async {
    final result = await _channel.invokeMapMethod<String, Object?>('getCapability');
    return LocalNetworkCapability(
      discoverySupported: (result?['discoverySupported'] as bool?) ?? false,
      permissionPromptSupported: (result?['permissionPromptSupported'] as bool?) ?? false,
      broadcastSupported: (result?['broadcastSupported'] as bool?) ?? false,
      notes: (result?['notes'] as String?) ?? 'unavailable',
    );
  }

  @override
  Future<LocalNetworkDiscoverySnapshot> discoverPeers() async {
    final result = await _channel.invokeMapMethod<String, Object?>('discoverPeers');
    return LocalNetworkDiscoverySnapshot(
      permissionGranted: (result?['permissionGranted'] as bool?) ?? false,
      foundEndpoints: (result?['foundEndpoints'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
      interfaceHints: (result?['interfaceHints'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
      warning: result?['warning'] as String?,
    );
  }
}
