import 'package:flutter/services.dart';

import 'secure_key_storage_bridge.dart';
import 'secure_key_storage_bridge_models.dart';
import 'secure_key_storage_channel_contract.dart';

class MethodChannelSecureKeyStorageBridge implements SecureKeyStorageBridge {
  MethodChannelSecureKeyStorageBridge({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const _channelName = SecureKeyStorageChannelContract.channelName;

  final MethodChannel _channel;

  @override
  Future<SecureKeyStorageSnapshot> loadKeyRing({
    required String namespace,
  }) async {
    final Map<String, Object?>? result;
    try {
      result = await _channel.invokeMapMethod<String, Object?>(
        SecureKeyStorageChannelContract.loadKeyRingMethod,
        <String, Object?>{'namespace': namespace},
      );
    } on MissingPluginException catch (error) {
      return SecureKeyStorageSnapshot.unavailable(
        warning: _warning('Secure key storage plugin is unavailable', error),
      );
    } on PlatformException catch (error) {
      return SecureKeyStorageSnapshot.unavailable(
        warning: _warning('Secure key storage lookup failed', error),
      );
    } on Object catch (error) {
      return SecureKeyStorageSnapshot.unavailable(
        warning: _warning('Secure key storage payload decode failed', error),
      );
    }

    return SecureKeyStorageChannelContract.decodeSnapshot(result);
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
