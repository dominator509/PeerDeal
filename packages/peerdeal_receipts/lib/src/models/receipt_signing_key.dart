import 'receipt_key_ring_input_limits.dart';

class ReceiptSigningKey {
  const ReceiptSigningKey({
    required this.keyId,
    required this.secret,
    this.algorithm = 'hmac-sha256',
  });

  final String keyId;
  final String secret;
  final String algorithm;

  bool get isUsable =>
      ReceiptKeyRingInputLimits.isSafeKeyId(keyId) &&
      secret.trim().isNotEmpty &&
      algorithm == 'hmac-sha256';
}
