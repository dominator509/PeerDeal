import 'dart:convert';

abstract final class ModeInputLimits {
  static const defaultMaxParticipants = 256;
  static const defaultMaxSeats = 64;
  static const defaultMaxWaitlistEntries = 256;
  static const maxIdentityBytes = 256;

  static bool isSafeIdentity(String value) {
    if (value.isEmpty || value.trim() != value) return false;
    try {
      final bytes = utf8.encode(value);
      if (bytes.length > maxIdentityBytes) return false;
      if (utf8.decode(bytes, allowMalformed: false) != value) return false;
    } on FormatException {
      return false;
    }
    return value.runes.every(
      (rune) => rune >= 0x20 && !(rune >= 0x7f && rune <= 0x9f),
    );
  }
}
