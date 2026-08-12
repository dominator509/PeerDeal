import 'package:peerdeal_crypto/peerdeal_crypto.dart';
import 'package:test/test.dart';

void main() {
  const engine = DefaultVerificationEngine();

  test('returns verified when all required evidence exists', () {
    final request = VerificationRequest(
      tableId: 'table_1',
      sessionId: 'session_1',
      handId: 'hand_1',
      scope: VerificationScope.hand,
      protocolVersion: '1.0',
      expectedReplayAnchor: 'replay_anchor',
      expectedFairDealAnchor: 'fair_anchor',
      expectedSettlementAnchor: 'settle_anchor',
      dealProofBundle: DealProofBundle(
        providerId: 'mental_poker_toolkit',
        providerVersion: '1.0.0',
        proofReference: 'proof_1',
        normalizedFields: <String, Object?>{},
      ),
    );

    final result = engine.verify(request);
    expect(result.state, VerificationState.verified);
  });

  test(
    'returns partial when proof bundle is missing but replay and settlement exist',
    () {
      final request = VerificationRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        scope: VerificationScope.session,
        protocolVersion: '1.0',
        expectedReplayAnchor: 'replay_anchor',
        expectedSettlementAnchor: 'settle_anchor',
      );

      final result = engine.verify(request);
      expect(result.state, VerificationState.partial);
    },
  );

  test('returns wiped when request is wiped', () {
    final request = VerificationRequest(
      tableId: 'table_1',
      sessionId: 'session_1',
      scope: VerificationScope.session,
      protocolVersion: '1.0',
      isWiped: true,
    );

    final result = engine.verify(request);
    expect(result.state, VerificationState.wiped);
  });
}
