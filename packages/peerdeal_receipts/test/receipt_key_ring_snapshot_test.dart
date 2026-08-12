import 'package:peerdeal_receipts/peerdeal_receipts.dart';
import 'package:test/test.dart';

void main() {
  test('feeds active and rotated signing keys into signer contract', () {
    const activeSigning = ReceiptSigningKey(
      keyId: 'receipt_signing_1',
      secret: 'signing_secret_1',
    );
    const rotatedSigning = ReceiptSigningKey(
      keyId: 'receipt_signing_0',
      secret: 'signing_secret_0',
    );
    final keyRing = ReceiptKeyRingSnapshot(
      activeSigning: activeSigning,
      verificationSigningKeys: <ReceiptSigningKey>[rotatedSigning],
    );
    final signer = HmacSha256ReceiptSigner(keyProvider: keyRing);

    final signature = signer.sign('payload');

    expect(signature, startsWith('hmac-sha256:receipt_signing_1:'));
    expect(signer.verify(payload: 'payload', signature: signature), isTrue);

    final rotatedSigner = HmacSha256ReceiptSigner(
      keyProvider: StaticReceiptSigningKeyProvider(activeKey: rotatedSigning),
    );
    final rotatedSignature = rotatedSigner.sign('payload');

    expect(
      signer.verify(payload: 'payload', signature: rotatedSignature),
      isTrue,
    );
  });

  test('exposes active and retained encryption keys for cipher adapters', () {
    const activeEncryption = ReceiptEncryptionKey(
      keyId: 'receipt_encryption_1',
      secret: 'encryption_secret_1',
    );
    const retainedEncryption = ReceiptEncryptionKey(
      keyId: 'receipt_encryption_0',
      secret: 'encryption_secret_0',
    );
    final keyRing = ReceiptKeyRingSnapshot(
      activeEncryption: activeEncryption,
      decryptionKeys: <ReceiptEncryptionKey>[retainedEncryption],
    );

    expect(keyRing.activeEncryptionKey(), activeEncryption);
    expect(
      keyRing.findEncryptionKey('receipt_encryption_0'),
      retainedEncryption,
    );
    expect(keyRing.findEncryptionKey('missing'), isNull);
  });

  test('fails closed for malformed key material', () {
    final keyRing = ReceiptKeyRingSnapshot(
      activeSigning: ReceiptSigningKey(
        keyId: 'bad:signing',
        secret: 'signing_secret',
      ),
      activeEncryption: ReceiptEncryptionKey(
        keyId: 'receipt_encryption_1',
        secret: '',
      ),
      verificationSigningKeys: <ReceiptSigningKey>[
        ReceiptSigningKey(keyId: 'rotated', secret: ''),
      ],
      decryptionKeys: <ReceiptEncryptionKey>[
        ReceiptEncryptionKey(
          keyId: 'bad:encryption',
          secret: 'encryption_secret',
        ),
      ],
    );

    expect(keyRing.activeSigningKey(), isNull);
    expect(keyRing.findSigningKey('rotated'), isNull);
    expect(keyRing.activeEncryptionKey(), isNull);
    expect(keyRing.findEncryptionKey('bad:encryption'), isNull);
  });

  test('fails closed before traversing oversized retained key collections', () {
    const activeSigning = ReceiptSigningKey(
      keyId: 'active_signing',
      secret: 'active_secret',
    );
    const retainedSigning = ReceiptSigningKey(
      keyId: 'retained_signing',
      secret: 'retained_secret',
    );
    const activeEncryption = ReceiptEncryptionKey(
      keyId: 'active_encryption',
      secret: 'active_secret',
    );
    const retainedEncryption = ReceiptEncryptionKey(
      keyId: 'retained_encryption',
      secret: 'retained_secret',
    );
    final keyRing = ReceiptKeyRingSnapshot(
      activeSigning: activeSigning,
      verificationSigningKeys: <ReceiptSigningKey>[
        retainedSigning,
        retainedSigning,
      ],
      activeEncryption: activeEncryption,
      decryptionKeys: <ReceiptEncryptionKey>[
        retainedEncryption,
        retainedEncryption,
      ],
      maxVerificationKeys: 1,
      maxDecryptionKeys: 1,
    );

    expect(keyRing.activeSigningKey(), activeSigning);
    expect(keyRing.findSigningKey('retained_signing'), isNull);
    expect(keyRing.activeEncryptionKey(), activeEncryption);
    expect(keyRing.findEncryptionKey('retained_encryption'), isNull);
  });

  test('requires positive retained-key limits', () {
    expect(
      () => ReceiptKeyRingSnapshot(maxVerificationKeys: 0),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => ReceiptKeyRingSnapshot(maxDecryptionKeys: 0),
      throwsA(isA<AssertionError>()),
    );
  });
}
