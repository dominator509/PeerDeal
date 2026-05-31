import 'package:flutter/services.dart';

import 'capture_protection_bridge.dart';
import 'capture_protection_bridge_models.dart';

class MethodChannelCaptureProtectionBridge implements CaptureProtectionBridge {
  MethodChannelCaptureProtectionBridge({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const _channelName = 'peerdeal/native_bridges/capture_protection';

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
    }

    if (result == null) {
      return const CaptureProtectionCapability.unavailable(
        warning: 'Capture protection capability is unavailable.',
      );
    }

    return CaptureProtectionCapability(
      blockingSupported: (result['blockingSupported'] as bool?) ?? false,
      obscuringSupported: (result['obscuringSupported'] as bool?) ?? false,
      notes: (result['notes'] as String?) ?? 'unavailable',
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
