import 'package:peerdeal_receipts/peerdeal_receipts.dart';
import 'package:test/test.dart';

void main() {
  const activeKey = ReceiptSigningKey(
    keyId: 'receipt_key_1',
    secret: 'test_secret_1',
  );
  const rotatedKey = ReceiptSigningKey(
    keyId: 'receipt_key_0',
    secret: 'test_secret_0',
  );
  const provider = StaticReceiptSigningKeyProvider(
    activeKey: activeKey,
    verificationKeys: <ReceiptSigningKey>[rotatedKey],
  );
  const signer = HmacSha256ReceiptSigner(keyProvider: provider);

  test('signs receipt payloads deterministically with active key id', () {
    final signature = signer.sign('payload');

    expect(signature, startsWith('hmac-sha256:receipt_key_1:'));
    expect(signature, signer.sign('payload'));
    expect(signer.verify(payload: 'payload', signature: signature), isTrue);
  });

  test('rejects tampered payloads and signatures', () {
    final signature = signer.sign('payload');

    expect(
      signer.verify(payload: 'tampered_payload', signature: signature),
      isFalse,
    );
    expect(
      signer.verify(payload: 'payload', signature: '$signature-tampered'),
      isFalse,
    );
    expect(
      signer.verify(payload: 'payload', signature: 'unsupported:key:digest'),
      isFalse,
    );
  });

  test('verifies signatures from retained rotated keys', () {
    const rotatedSigner = HmacSha256ReceiptSigner(
      keyProvider: StaticReceiptSigningKeyProvider(activeKey: rotatedKey),
    );

    final signature = rotatedSigner.sign('payload');

    expect(signature, startsWith('hmac-sha256:receipt_key_0:'));
    expect(signer.verify(payload: 'payload', signature: signature), isTrue);
  });

  test('does not use malformed signing keys', () {
    const invalidProvider = StaticReceiptSigningKeyProvider(
      activeKey: ReceiptSigningKey(keyId: 'bad:key', secret: 'test_secret'),
    );
    const invalidSigner = HmacSha256ReceiptSigner(keyProvider: invalidProvider);

    expect(() => invalidSigner.sign('payload'), throwsStateError);
    expect(
      invalidSigner.verify(
        payload: 'payload',
        signature: 'hmac-sha256:bad:key:digest',
      ),
      isFalse,
    );
  });

  test(
    'fails closed when retained signing keys exceed the configured limit',
    () {
      const boundedProvider = StaticReceiptSigningKeyProvider(
        activeKey: activeKey,
        verificationKeys: <ReceiptSigningKey>[rotatedKey, rotatedKey],
        maxVerificationKeys: 1,
      );

      expect(boundedProvider.findSigningKey(rotatedKey.keyId), isNull);
      expect(boundedProvider.activeSigningKey(), activeKey);
    },
  );

  test('requires a positive retained signing-key limit', () {
    expect(
      () => StaticReceiptSigningKeyProvider(
        activeKey: activeKey,
        maxVerificationKeys: 0,
      ),
      throwsA(isA<AssertionError>()),
    );
  });

  test('fails closed when verification key lookup throws', () {
    const signer = HmacSha256ReceiptSigner(
      keyProvider: _ThrowingSigningKeyProvider(),
    );

    expect(
      signer.verify(
        payload: 'payload',
        signature: 'hmac-sha256:receipt_key_1:digest',
      ),
      isFalse,
    );
  });
}

class _ThrowingSigningKeyProvider implements ReceiptSigningKeyProvider {
  const _ThrowingSigningKeyProvider();

  @override
  ReceiptSigningKey? activeSigningKey() {
    throw StateError('signing key unavailable');
  }

  @override
  ReceiptSigningKey? findSigningKey(String keyId) {
    throw StateError('verification key unavailable');
  }
}
