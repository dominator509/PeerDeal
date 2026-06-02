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
      blockingSupported: _boolValue(payload['blockingSupported']),
      obscuringSupported: _boolValue(payload['obscuringSupported']),
      notes: _stringValue(payload['notes']) ?? 'unavailable',
      warning: _stringValue(payload['warning']),
    );
  }

  static bool _boolValue(Object? value) => value is bool ? value : false;

  static String? _stringValue(Object? value) => value is String ? value : null;
}
