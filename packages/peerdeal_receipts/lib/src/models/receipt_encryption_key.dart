import 'receipt_key_ring_input_limits.dart';

class ReceiptEncryptionKey {
  const ReceiptEncryptionKey({
    required this.keyId,
    required this.secret,
    this.algorithm = 'external',
  });

  final String keyId;
  final String secret;
  final String algorithm;

  bool get isUsable =>
      ReceiptKeyRingInputLimits.isSafeKeyId(keyId) &&
      secret.trim().isNotEmpty &&
      algorithm == 'external';
}
