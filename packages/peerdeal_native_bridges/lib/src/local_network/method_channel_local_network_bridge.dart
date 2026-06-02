import 'package:flutter/services.dart';

import 'local_network_channel_contract.dart';
import 'local_network_bridge.dart';
import 'local_network_bridge_models.dart';

class MethodChannelLocalNetworkBridge implements LocalNetworkBridge {
  MethodChannelLocalNetworkBridge({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const _channelName = LocalNetworkChannelContract.channelName;

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
    } on Object catch (error) {
      return LocalNetworkCapability.unavailable(
        warning: _warning(
          'Local network capability payload decode failed',
          error,
        ),
      );
    }

    return LocalNetworkChannelContract.decodeCapability(result);
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
    } on Object catch (error) {
      return LocalNetworkDiscoverySnapshot.unavailable(
        warning: _warning(
          'Local network discovery payload decode failed',
          error,
        ),
      );
    }

    return LocalNetworkChannelContract.decodeDiscoverySnapshot(result);
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
