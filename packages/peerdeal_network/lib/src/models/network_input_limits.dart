import 'dart:convert';

abstract final class NetworkInputLimits {
  static const defaultMaxPeerIds = 32;
  static const defaultMaxCandidates = 32;
  static const defaultMaxPeerMetrics = 64;
  static const maxPeerIdentityBytes = 256;
  static const maxTransportSequence = 0x7fffffff;

  static bool isSafePeerIdentity(String value) {
    if (value.isEmpty || value.trim() != value) return false;
    try {
      final bytes = utf8.encode(value);
      if (bytes.length > maxPeerIdentityBytes) return false;
      if (utf8.decode(bytes, allowMalformed: false) != value) return false;
    } on FormatException {
      return false;
    }
    return value.runes.every(
      (rune) => rune >= 0x20 && !(rune >= 0x7f && rune <= 0x9f),
    );
  }

  /// Whether a peer identity is safe to use as an actionable network target.
  ///
  /// `none`, `unresolved`, and `::` are reserved by network route and
  /// persistence sentinels. Scope identities such as session and table ids
  /// should use [isSafePeerIdentity] instead.
  static bool isOperationalPeerIdentity(String value) {
    return isSafePeerIdentity(value) &&
        value != 'none' &&
        value != 'unresolved' &&
        !value.contains('::');
  }
}
