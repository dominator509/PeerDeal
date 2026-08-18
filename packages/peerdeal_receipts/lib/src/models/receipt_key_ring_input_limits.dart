import 'dart:convert';

abstract final class ReceiptKeyRingInputLimits {
  static const defaultMaxVerificationKeys = 128;
  static const defaultMaxDecryptionKeys = 128;
  static const defaultMaxKeyIdBytes = 256;

  static bool isSafeKeyId(String value) {
    if (value.isEmpty || value.trim() != value || value.contains(':')) {
      return false;
    }
    final bytes = utf8.encode(value);
    if (bytes.length > defaultMaxKeyIdBytes) return false;
    try {
      if (utf8.decode(bytes) != value) return false;
    } on FormatException {
      return false;
    }
    return !value.codeUnits.any(
      (unit) => unit < 0x20 || (unit >= 0x7f && unit <= 0x9f),
    );
  }
}
