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
    final result = await _channel.invokeMapMethod<String, Object?>(
      'getCapability',
    );

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
}
