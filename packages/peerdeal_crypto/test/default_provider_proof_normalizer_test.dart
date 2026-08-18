import 'package:peerdeal_crypto/peerdeal_crypto.dart';
import 'package:test/test.dart';

void main() {
  test('normalizer preserves proof reference and payload', () {
    const normalizer = DefaultProviderProofNormalizer();
    final result = normalizer.normalize(
      providerId: 'mental_poker_toolkit',
      providerVersion: '1.0.0',
      rawProof: {'proof_ref': 'proof_123', 'deck_commitment': 'abc'},
    );

    expect(result.providerId, 'mental_poker_toolkit');
    expect(result.proofReference, 'proof_123');
    expect(result.normalizedFields['deck_commitment'], 'abc');
    expect(result.rawPayload, same(result.normalizedFields));
  });

  test('normalizer rejects oversized proof objects', () {
    const normalizer = DefaultProviderProofNormalizer(
      limits: DealProofLimits(maxMapEntries: 1),
    );

    expect(
      () => normalizer.normalize(
        providerId: 'provider',
        providerVersion: '1.0.0',
        rawProof: {'proof_ref': 'proof_123', 'extra': true},
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('normalizer rejects oversized text, arrays, and node budgets', () {
    const textNormalizer = DefaultProviderProofNormalizer(
      limits: DealProofLimits(maxTextBytes: 3),
    );
    expect(
      () => textNormalizer.normalize(
        providerId: 'id',
        providerVersion: 'v',
        rawProof: {'proof_ref': 'long'},
      ),
      throwsA(isA<FormatException>()),
    );

    const listNormalizer = DefaultProviderProofNormalizer(
      limits: DealProofLimits(maxListItems: 1),
    );
    expect(
      () => listNormalizer.normalize(
        providerId: 'id',
        providerVersion: 'v',
        rawProof: {
          'items': [1, 2],
        },
      ),
      throwsA(isA<FormatException>()),
    );

    const nodeNormalizer = DefaultProviderProofNormalizer(
      limits: DealProofLimits(maxNodes: 1),
    );
    expect(
      () => nodeNormalizer.normalize(
        providerId: 'id',
        providerVersion: 'v',
        rawProof: {'proof_ref': 'proof'},
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('normalizer rejects deep, oversized, and unsupported proofs', () {
    const depthNormalizer = DefaultProviderProofNormalizer(
      limits: DealProofLimits(maxDepth: 1),
    );
    expect(
      () => depthNormalizer.normalize(
        providerId: 'id',
        providerVersion: 'v',
        rawProof: {
          'nested': {'value': true},
        },
      ),
      throwsA(isA<FormatException>()),
    );

    const bytesNormalizer = DefaultProviderProofNormalizer(
      limits: DealProofLimits(maxProofBytes: 4),
    );
    expect(
      () => bytesNormalizer.normalize(
        providerId: 'id',
        providerVersion: 'v',
        rawProof: {'a': 1},
      ),
      throwsA(isA<FormatException>()),
    );

    const unsupportedNormalizer = DefaultProviderProofNormalizer();
    expect(
      () => unsupportedNormalizer.normalize(
        providerId: 'id',
        providerVersion: 'v',
        rawProof: {'value': Object()},
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('normalizer bounds provider identity and proof reference', () {
    const normalizer = DefaultProviderProofNormalizer(
      limits: DealProofLimits(
        maxProviderIdBytes: 2,
        maxProviderVersionBytes: 2,
        maxProofReferenceBytes: 2,
      ),
    );

    expect(
      () => normalizer.normalize(
        providerId: 'long',
        providerVersion: 'v',
        rawProof: const {},
      ),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => normalizer.normalize(
        providerId: 'id',
        providerVersion: 'long',
        rawProof: const {},
      ),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => normalizer.normalize(
        providerId: 'id',
        providerVersion: 'v',
        rawProof: {'proof_ref': 'long'},
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('normalizer rejects non-round-tripping provider text', () {
    expect(
      () => const DefaultProviderProofNormalizer().normalize(
        providerId: String.fromCharCode(0xd800),
        providerVersion: '1.0.0',
        rawProof: const <String, Object?>{},
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('normalizer rejects unsafe provider metadata', () {
    const normalizer = DefaultProviderProofNormalizer();

    expect(
      () => normalizer.normalize(
        providerId: ' provider',
        providerVersion: '1.0.0',
        rawProof: const {},
      ),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => normalizer.normalize(
        providerId: 'provider',
        providerVersion: '1.0.0',
        rawProof: {'proof_ref': 'proof\u0085'},
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('normalizer rejects coerced or ambiguous proof references', () {
    const normalizer = DefaultProviderProofNormalizer();

    for (final value in <Object?>[null, 7, true, <String, Object?>{}]) {
      expect(
        () => normalizer.normalize(
          providerId: 'provider',
          providerVersion: '1.0.0',
          rawProof: <String, Object?>{'proof_ref': value},
        ),
        throwsA(isA<FormatException>()),
      );
    }

    expect(
      () => normalizer.normalize(
        providerId: 'provider',
        providerVersion: '1.0.0',
        rawProof: const <String, Object?>{
          'proof_ref': 'proof_1',
          'proofReference': 'proof_1',
        },
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('limits reject invalid configuration', () {
    expect(
      () => const DealProofLimits(maxNodes: 0).validate(),
      throwsArgumentError,
    );
  });
}
