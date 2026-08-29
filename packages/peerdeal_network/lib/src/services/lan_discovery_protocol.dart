import 'dart:convert';

import '../models/network_input_limits.dart';

enum LanDiscoveryPacketKind { query, advertisement }

class LanDiscoveryPacket {
  const LanDiscoveryPacket({required this.kind, this.peerId, this.port});

  final LanDiscoveryPacketKind kind;
  final String? peerId;
  final int? port;

  bool get isQuery => kind == LanDiscoveryPacketKind.query;
}

/// Canonical bounded wire format for local peer discovery.
///
/// The native hosts mirror this format without importing Dart packages:
/// four-byte magic, one-byte version, one-byte kind, two-byte big-endian
/// identity length, two-byte big-endian transport port, and UTF-8 identity
/// bytes. Queries carry zero identity and port; advertisements carry both.
class LanDiscoveryProtocol {
  const LanDiscoveryProtocol._();

  static const multicastAddress = '239.255.42.100';
  static const multicastPort = 40443;
  static const defaultTransportPort = 40442;
  static const maxPacketBytes =
      _headerBytes + NetworkInputLimits.maxPeerIdentityBytes;

  static const _headerBytes = 10;
  static const _version = 1;
  static const _queryKind = 1;
  static const _advertisementKind = 2;
  static const _magic = <int>[0x50, 0x44, 0x44, 0x31];

  static List<int> encodeQuery() {
    return List<int>.unmodifiable(<int>[
      ..._magic,
      _version,
      _queryKind,
      0,
      0,
      0,
      0,
    ]);
  }

  static List<int>? encodeAdvertisement({
    required String peerId,
    int port = defaultTransportPort,
  }) {
    if (!_isOperationalPeerId(peerId) || port < 1 || port > 65535) {
      return null;
    }
    final identity = utf8.encode(peerId);
    if (identity.length > NetworkInputLimits.maxPeerIdentityBytes) {
      return null;
    }
    return List<int>.unmodifiable(<int>[
      ..._magic,
      _version,
      _advertisementKind,
      (identity.length >> 8) & 0xff,
      identity.length & 0xff,
      (port >> 8) & 0xff,
      port & 0xff,
      ...identity,
    ]);
  }

  static LanDiscoveryPacket? decode(Iterable<int> value) {
    final bytes = List<int>.from(value, growable: false);
    if (bytes.length < _headerBytes || bytes.length > maxPacketBytes) {
      return null;
    }
    if (bytes.any((byte) => byte < 0 || byte > 255)) return null;
    for (var index = 0; index < _magic.length; index += 1) {
      if (bytes[index] != _magic[index]) return null;
    }
    if (bytes[4] != _version) return null;
    final kind = bytes[5];
    final identityLength = (bytes[6] << 8) | bytes[7];
    final port = (bytes[8] << 8) | bytes[9];
    if (identityLength > NetworkInputLimits.maxPeerIdentityBytes ||
        bytes.length != _headerBytes + identityLength) {
      return null;
    }
    if (kind == _queryKind) {
      return identityLength == 0 && port == 0
          ? const LanDiscoveryPacket(kind: LanDiscoveryPacketKind.query)
          : null;
    }
    if (kind != _advertisementKind || port < 1 || port > 65535) return null;

    final peerIdBytes = bytes.sublist(_headerBytes);
    final peerId = tryDecodeUtf8(peerIdBytes);
    if (peerId == null || !_isOperationalPeerId(peerId)) return null;
    return LanDiscoveryPacket(
      kind: LanDiscoveryPacketKind.advertisement,
      peerId: peerId,
      port: port,
    );
  }

  static String? tryDecodeUtf8(List<int> bytes) {
    try {
      return utf8.decode(bytes, allowMalformed: false);
    } on FormatException {
      return null;
    }
  }

  static bool _isOperationalPeerId(String value) {
    return NetworkInputLimits.isOperationalPeerIdentity(value);
  }
}
