import 'package:peerdeal_receipts/peerdeal_receipts.dart';
import 'package:test/test.dart';

void main() {
  const activeKey = ReceiptEncryptionKey(
    keyId: 'receipt_encryption_1',
    secret: 'encryption_secret_1',
  );
  const rotatedKey = ReceiptEncryptionKey(
    keyId: 'receipt_encryption_0',
    secret: 'encryption_secret_0',
  );
  final keyRing = ReceiptKeyRingSnapshot(
    activeEncryption: activeKey,
    decryptionKeys: <ReceiptEncryptionKey>[rotatedKey],
  );

  test('encrypts and decrypts receipt payloads with active key id', () {
    final cipher = HmacSha256ReceiptCipher(
      keyProvider: keyRing,
      nonceFactory: () => List<int>.filled(32, 7),
    );

    final ciphertext = cipher.encrypt('receipt-payload');

    expect(
      ciphertext,
      startsWith(
        '${HmacSha256ReceiptCipher.formatVersion}:'
        '${HmacSha256ReceiptCipher.algorithm}:receipt_encryption_1:',
      ),
    );
    expect(cipher.decrypt(ciphertext), 'receipt-payload');
  });

  test('decrypts payloads from retained rotated keys', () {
    final rotatedCipher = HmacSha256ReceiptCipher(
      keyProvider: ReceiptKeyRingSnapshot(activeEncryption: rotatedKey),
      nonceFactory: () => List<int>.filled(32, 9),
    );
    final currentCipher = HmacSha256ReceiptCipher(keyProvider: keyRing);
    final ciphertext = rotatedCipher.encrypt('rotated-payload');

    expect(currentCipher.decrypt(ciphertext), 'rotated-payload');
  });

  test('rejects tampered ciphertext', () {
    final cipher = HmacSha256ReceiptCipher(
      keyProvider: keyRing,
      nonceFactory: () => List<int>.filled(32, 7),
    );
    final ciphertext = cipher.encrypt('receipt-payload');
    final parts = ciphertext.split(':');
    parts[4] = '${parts[4]}tampered';

    expect(
      () => cipher.decrypt(parts.join(':')),
      throwsA(isA<FormatException>()),
    );
  });

  test('fails closed when key material is unavailable', () {
    final cipher = HmacSha256ReceiptCipher(
      keyProvider: ReceiptKeyRingSnapshot(),
      nonceFactory: () => List<int>.filled(32, 7),
    );

    expect(() => cipher.encrypt('receipt-payload'), throwsA(isA<StateError>()));
    expect(
      () => cipher.decrypt(
        '${HmacSha256ReceiptCipher.formatVersion}:'
        '${HmacSha256ReceiptCipher.algorithm}:missing:a:b:c',
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects malformed cipher payloads', () {
    final cipher = HmacSha256ReceiptCipher(keyProvider: keyRing);

    expect(
      () => cipher.decrypt('unsupported'),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects oversized plaintext before keystream generation', () {
    final cipher = HmacSha256ReceiptCipher(
      keyProvider: keyRing,
      limits: const ReceiptExportLimits(maxPayloadBytes: 4),
    );

    expect(() => cipher.encrypt('too-large'), throwsA(isA<StateError>()));
  });

  test('rejects oversized ciphertext before key lookup', () {
    final cipher = HmacSha256ReceiptCipher(
      keyProvider: keyRing,
      limits: const ReceiptExportLimits(maxCiphertextLength: 8),
    );

    expect(() => cipher.decrypt('x' * 9), throwsA(isA<FormatException>()));
  });

  test('rejects oversized nonces after authentication', () {
    final source = HmacSha256ReceiptCipher(
      keyProvider: keyRing,
      nonceFactory: () => List<int>.filled(32, 7),
    );
    final ciphertext = source.encrypt('receipt-payload');
    final limitedCipher = HmacSha256ReceiptCipher(
      keyProvider: keyRing,
      limits: const ReceiptExportLimits(maxNonceBytes: 8),
    );

    expect(
      () => limitedCipher.decrypt(ciphertext),
      throwsA(isA<FormatException>()),
    );
  });
}
