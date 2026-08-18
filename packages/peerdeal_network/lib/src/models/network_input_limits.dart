import 'dart:convert';

abstract final class NetworkInputLimits {
  static const defaultMaxPeerIds = 32;
  static const defaultMaxCandidates = 32;
  static const defaultMaxPeerMetrics = 64;
  static const maxPeerIdentityBytes = 256;

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
}
