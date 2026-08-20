import '../native_bridge_payload_limits.dart';
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
      notes:
          _boundedStringValue(
            payload['notes'],
            NativeBridgePayloadLimits.maxDiagnosticBytes,
          ) ??
          'unavailable',
      warning: _boundedStringValue(
        payload['warning'],
        NativeBridgePayloadLimits.maxDiagnosticBytes,
      ),
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

    final permissionGranted = _boolValue(payload['permissionGranted']);
    final foundEndpoints = permissionGranted
        ? _stringListValue(payload['foundEndpoints'])
        : const <String>[];
    final interfaceHints = _stringListValue(payload['interfaceHints']);
    return LocalNetworkDiscoverySnapshot(
      permissionGranted: permissionGranted,
      foundEndpoints: foundEndpoints,
      interfaceHints: interfaceHints,
      warning: _boundedStringValue(
        payload['warning'],
        NativeBridgePayloadLimits.maxDiagnosticBytes,
      ),
    );
  }

  static bool _boolValue(Object? value) => value is bool ? value : false;

  static String? _boundedStringValue(Object? value, int maxBytes) {
    if (value is! String ||
        !NativeBridgePayloadLimits.isSafeUtf8Text(value, maxBytes)) {
      return null;
    }
    return value;
  }

  static List<String> _stringListValue(Object? value) {
    if (value is! List<dynamic> ||
        value.length > NativeBridgePayloadLimits.maxDiscoveryEntries) {
      return const <String>[];
    }
    return value
        .whereType<String>()
        .where(
          (item) => NativeBridgePayloadLimits.isSafeUtf8Text(
            item,
            NativeBridgePayloadLimits.maxDiscoveryValueBytes,
          ),
        )
        .toList(growable: false);
  }
}
