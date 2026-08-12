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

  test('fails closed for malformed request identity and sequence window', () {
    final result = engine.verify(
      const VerificationRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        scope: VerificationScope.session,
        protocolVersion: '1.0',
        eventSeqStart: 4,
        eventSeqEnd: 3,
        expectedReplayAnchor: 'replay_anchor',
        expectedSettlementAnchor: 'settle_anchor',
      ),
    );

    expect(result.state, VerificationState.failed);
    expect(
      result.reasonCode,
      VerificationReasonCode.errVerificationDataIncomplete,
    );
    expect(result.payload.verificationLayersPassed, isEmpty);
    expect(result.payload.verificationLayersFailed, hasLength(3));
    expect(result.payload.replayAnchor, isNull);
  });

  test('fails closed for control-bearing proof metadata', () {
    final result = engine.verify(
      VerificationRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        handId: 'hand_1',
        scope: VerificationScope.hand,
        protocolVersion: '1.0',
        expectedReplayAnchor: 'replay_anchor',
        expectedSettlementAnchor: 'settle_anchor',
        dealProofBundle: DealProofBundle(
          providerId: 'provider\u0085',
          providerVersion: '1.0.0',
          proofReference: 'proof_1',
          normalizedFields: const <String, Object?>{},
        ),
      ),
    );

    expect(result.state, VerificationState.failed);
    expect(
      result.reasonCode,
      VerificationReasonCode.errVerificationDataIncomplete,
    );
    expect(result.payload.warnings, isEmpty);
  });

  test('fails closed when hand scope has no hand identity', () {
    final result = engine.verify(
      const VerificationRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        scope: VerificationScope.hand,
        protocolVersion: '1.0',
        expectedReplayAnchor: 'replay_anchor',
        expectedSettlementAnchor: 'settle_anchor',
      ),
    );

    expect(result.state, VerificationState.failed);
    expect(
      result.reasonCode,
      VerificationReasonCode.errVerificationDataIncomplete,
    );
  });

  test('fails closed for proof payloads outside configured bounds', () {
    const boundedEngine = DefaultVerificationEngine(
      proofLimits: DealProofLimits(maxMapEntries: 1),
    );
    final result = boundedEngine.verify(
      VerificationRequest(
        tableId: 'table_1',
        sessionId: 'session_1',
        handId: 'hand_1',
        scope: VerificationScope.hand,
        protocolVersion: '1.0',
        expectedReplayAnchor: 'replay_anchor',
        expectedSettlementAnchor: 'settle_anchor',
        dealProofBundle: DealProofBundle(
          providerId: 'provider',
          providerVersion: '1.0.0',
          proofReference: 'proof_1',
          normalizedFields: const <String, Object?>{'one': true, 'two': true},
        ),
      ),
    );

    expect(result.state, VerificationState.failed);
    expect(
      result.reasonCode,
      VerificationReasonCode.errVerificationDataIncomplete,
    );
  });
}
