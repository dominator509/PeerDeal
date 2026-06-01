import 'package:flutter/services.dart';

import 'capture_protection_channel_contract.dart';
import 'capture_protection_bridge.dart';
import 'capture_protection_bridge_models.dart';

class MethodChannelCaptureProtectionBridge implements CaptureProtectionBridge {
  MethodChannelCaptureProtectionBridge({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const _channelName = CaptureProtectionChannelContract.channelName;

  final MethodChannel _channel;

  @override
  Future<CaptureProtectionCapability> getCapability() async {
    final Map<String, Object?>? result;
    try {
      result = await _channel.invokeMapMethod<String, Object?>('getCapability');
    } on MissingPluginException catch (error) {
      return CaptureProtectionCapability.unavailable(
        warning: _warning('Capture protection plugin is unavailable', error),
      );
    } on PlatformException catch (error) {
      return CaptureProtectionCapability.unavailable(
        warning: _warning('Capture protection capability lookup failed', error),
      );
    } on Object catch (error) {
      return CaptureProtectionCapability.unavailable(
        warning: _warning('Capture protection payload decode failed', error),
      );
    }

    return CaptureProtectionChannelContract.decodeCapability(result);
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
