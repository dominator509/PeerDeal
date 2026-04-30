import 'package:peerdeal_crypto/peerdeal_crypto.dart';
import 'package:test/test.dart';

void main() {
  test('normalizer preserves proof reference and payload', () {
    const normalizer = DefaultProviderProofNormalizer();
    final result = normalizer.normalize(
      providerId: 'mental_poker_toolkit',
      providerVersion: '1.0.0',
      rawProof: {
        'proof_ref': 'proof_123',
        'deck_commitment': 'abc',
      },
    );

    expect(result.providerId, 'mental_poker_toolkit');
    expect(result.proofReference, 'proof_123');
    expect(result.normalizedFields['deck_commitment'], 'abc');
  });
}
