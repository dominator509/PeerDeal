import 'dart:convert';

class NativeBridgePayloadLimits {
  const NativeBridgePayloadLimits._();

  static const maxTransportFrames = 64;
  static const maxTransportPayloadBytes = 64 * 1024;
  static const maxTransportIdentityBytes = 256;
  static const maxDiscoveryEntries = 64;
  static const maxDiscoveryValueBytes = 512;
  static const maxAppStoragePathBytes = 4096;
  static const maxSecureKeyRecords = 128;
  static const maxSecureKeyNamespaceBytes = 128;
  static const maxSecureKeyIdBytes = 256;
  static const maxSecureKeyPurposeBytes = 128;
  static const maxSecureKeyAlgorithmBytes = 128;
  static const maxSecureKeySecretBytes = 4096;
  static const maxDiagnosticBytes = 512;

  static bool isWithinUtf8Limit(String value, int maxBytes) =>
      utf8.encode(value).length <= maxBytes;
}
