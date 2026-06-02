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
      keyId.trim().isNotEmpty &&
      !keyId.contains(':') &&
      secret.trim().isNotEmpty &&
      algorithm == 'external';
}
