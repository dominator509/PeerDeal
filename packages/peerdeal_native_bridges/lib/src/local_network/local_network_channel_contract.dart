import '../native_bridge_payload_limits.dart';
import 'local_network_bridge_models.dart';

class LocalNetworkChannelContract {
  const LocalNetworkChannelContract._();

  static const channelName = 'peerdeal/native_bridges/local_network';
  static const getCapabilityMethod = 'getCapability';
  static const discoverPeersMethod = 'discoverPeers';
  static const announcePeerMethod = 'announcePeer';
  static const defaultAdvertisedPort = 40442;

  static Map<String, Object?> encodePeerAnnouncement({
    required String peerId,
    required int port,
  }) {
    if (!_isOperationalPeerId(peerId) || port < 1 || port > 65535) {
      return const <String, Object?>{};
    }
    return <String, Object?>{'peerId': peerId, 'port': port};
  }

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

  static LocalNetworkAnnouncementResult decodeAnnouncementResult(
    Map<String, Object?>? payload,
  ) {
    if (payload == null) {
      return const LocalNetworkAnnouncementResult.unavailable(
        warning: 'Local network announcement is unavailable.',
      );
    }
    final published = _boolValue(payload['published']);
    return LocalNetworkAnnouncementResult(
      published: published,
      warning:
          _boundedStringValue(
            payload['warning'],
            NativeBridgePayloadLimits.maxDiagnosticBytes,
          ) ??
          (published ? null : 'Local network announcement failed.'),
    );
  }

  static bool _boolValue(Object? value) => value is bool ? value : false;

  static bool _isOperationalPeerId(String value) {
    return NativeBridgePayloadLimits.isSafeUtf8Text(
          value,
          NativeBridgePayloadLimits.maxTransportIdentityBytes,
        ) &&
        value != 'none' &&
        value != 'unresolved' &&
        !value.contains('::');
  }

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
