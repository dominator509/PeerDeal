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
      keyId.trim().isNotEmpty &&
      !keyId.contains(':') &&
      secret.trim().isNotEmpty &&
      algorithm == 'hmac-sha256';
}
