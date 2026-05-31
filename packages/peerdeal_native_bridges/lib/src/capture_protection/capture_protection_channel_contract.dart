import 'capture_protection_bridge_models.dart';

class CaptureProtectionChannelContract {
  const CaptureProtectionChannelContract._();

  static const channelName = 'peerdeal/native_bridges/capture_protection';
  static const getCapabilityMethod = 'getCapability';

  static CaptureProtectionCapability decodeCapability(
    Map<String, Object?>? payload,
  ) {
    if (payload == null) {
      return const CaptureProtectionCapability.unavailable(
        warning: 'Capture protection capability is unavailable.',
      );
    }

    return CaptureProtectionCapability(
      blockingSupported: (payload['blockingSupported'] as bool?) ?? false,
      obscuringSupported: (payload['obscuringSupported'] as bool?) ?? false,
      notes: (payload['notes'] as String?) ?? 'unavailable',
      warning: payload['warning'] as String?,
    );
  }
}
