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
    final Map<String, Object?>? result;
    try {
      result = await _channel.invokeMapMethod<String, Object?>('getCapability');
    } on MissingPluginException catch (error) {
      return LocalNetworkCapability.unavailable(
        warning: _warning('Local network plugin is unavailable', error),
      );
    } on PlatformException catch (error) {
      return LocalNetworkCapability.unavailable(
        warning: _warning('Local network capability lookup failed', error),
      );
    }

    if (result == null) {
      return const LocalNetworkCapability.unavailable(
        warning: 'Local network capability is unavailable.',
      );
    }

    return LocalNetworkCapability(
      discoverySupported: (result['discoverySupported'] as bool?) ?? false,
      permissionPromptSupported:
          (result['permissionPromptSupported'] as bool?) ?? false,
      broadcastSupported: (result['broadcastSupported'] as bool?) ?? false,
      notes: (result['notes'] as String?) ?? 'unavailable',
      warning: result['warning'] as String?,
    );
  }

  @override
  Future<LocalNetworkDiscoverySnapshot> discoverPeers() async {
    final Map<String, Object?>? result;
    try {
      result = await _channel.invokeMapMethod<String, Object?>('discoverPeers');
    } on MissingPluginException catch (error) {
      return LocalNetworkDiscoverySnapshot.unavailable(
        warning: _warning('Local network plugin is unavailable', error),
      );
    } on PlatformException catch (error) {
      return LocalNetworkDiscoverySnapshot.unavailable(
        warning: _warning('Local network discovery failed', error),
      );
    }

    if (result == null) {
      return const LocalNetworkDiscoverySnapshot.unavailable(
        warning: 'Local network discovery is unavailable.',
      );
    }

    return LocalNetworkDiscoverySnapshot(
      permissionGranted: (result['permissionGranted'] as bool?) ?? false,
      foundEndpoints: (result['foundEndpoints'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
      interfaceHints: (result['interfaceHints'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
      warning: result['warning'] as String?,
    );
  }

  String _warning(String prefix, Object error) {
    if (error is PlatformException) {
      final message = error.message;
      return message == null || message.isEmpty
          ? '$prefix: ${error.code}.'
          : '$prefix: ${error.code} - $message';
    }
    return '$prefix: $error';
  }
}
