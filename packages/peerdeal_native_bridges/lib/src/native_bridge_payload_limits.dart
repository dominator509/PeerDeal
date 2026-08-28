import 'dart:convert';

class NativeBridgePayloadLimits {
  const NativeBridgePayloadLimits._();

  static const maxTransportFrames = 64;
  static const maxTransportPayloadBytes = 64 * 1024;
  static const maxTransportIdentityBytes = 256;
  static const maxTransportSequence = 0x7fffffff;
  static const maxDiscoveryEntries = 64;
  static const maxDiscoveryValueBytes = 512;
  static const maxAppStoragePathBytes = 4096;
  static const maxSecureKeyRecords = 128;
  static const maxSecureKeyNamespaceBytes = 128;
  static const maxSecureKeyIdBytes = 256;
  static const maxSecureKeyPurposeBytes = 128;
  static const maxSecureKeyAlgorithmBytes = 128;
  static const maxSecureKeySecretBytes = 4096;
  static const maxSecureKeyRevision = 0x7fffffffffffffff;
  static const maxDiagnosticBytes = 512;

  static bool isWithinUtf8Limit(String value, int maxBytes) {
    final encoded = utf8.encode(value);
    return encoded.length <= maxBytes &&
        utf8.decode(encoded, allowMalformed: false) == value;
  }

  static bool isSafeUtf8Text(String value, int maxBytes) =>
      isWithinUtf8Limit(value, maxBytes) &&
      value.trim().isNotEmpty &&
      value.trim() == value &&
      value.codeUnits.every(
        (codeUnit) =>
            codeUnit >= 0x20 && !(codeUnit >= 0x7F && codeUnit <= 0x9F),
      );
}
