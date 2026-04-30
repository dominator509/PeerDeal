import '../contracts/verification_engine.dart';
import '../models/verification_layer_result.dart';
import '../models/verification_payload.dart';
import '../models/verification_reason_code.dart';
import '../models/verification_request.dart';
import '../models/verification_result.dart';
import '../models/verification_state.dart';
import '../models/verification_summary.dart';

class DefaultVerificationEngine implements VerificationEngine {
  const DefaultVerificationEngine();

  @override
  VerificationResult verify(VerificationRequest request) {
    if (request.isWiped) {
      return const VerificationResult(
        state: VerificationState.wiped,
        reasonCode: VerificationReasonCode.errVerificationWiped,
        layers: <VerificationLayerResult>[],
        summary: VerificationSummary(
          headline: 'Wiped',
          detail: 'Verification detail is no longer viewable in supported clients.',
        ),
        payload: VerificationPayload(
          verificationLayersPassed: <String>[],
          verificationLayersFailed: <String>[],
        ),
      );
    }

    final replayOk = request.expectedReplayAnchor != null && request.expectedReplayAnchor!.isNotEmpty;
    final proofOk = request.dealProofBundle != null;
    final settlementOk = request.expectedSettlementAnchor != null && request.expectedSettlementAnchor!.isNotEmpty;

    final layers = <VerificationLayerResult>[
      VerificationLayerResult(
        layerId: 'replay_integrity',
        passed: replayOk,
        reason: replayOk ? null : 'Missing replay anchor.',
      ),
      VerificationLayerResult(
        layerId: 'deal_provider_integrity',
        passed: proofOk,
        reason: proofOk ? null : 'Missing deal proof bundle.',
      ),
      VerificationLayerResult(
        layerId: 'settlement_integrity',
        passed: settlementOk,
        reason: settlementOk ? null : 'Missing settlement anchor.',
      ),
    ];

    final passed = layers.where((l) => l.passed).map((l) => l.layerId).toList(growable: false);
    final failed = layers.where((l) => !l.passed).map((l) => l.layerId).toList(growable: false);

    if (replayOk && proofOk && settlementOk) {
      return VerificationResult(
        state: VerificationState.verified,
        reasonCode: request.handId == null
            ? VerificationReasonCode.okVerifiedSession
            : VerificationReasonCode.okVerifiedHand,
        layers: layers,
        summary: const VerificationSummary(
          headline: 'Verified',
          detail: 'Replay, proof bundle, and settlement anchors all passed.',
        ),
        payload: VerificationPayload(
          verificationLayersPassed: passed,
          verificationLayersFailed: failed,
          replayAnchor: request.expectedReplayAnchor,
          fairDealAnchor: request.expectedFairDealAnchor,
          settlementAnchor: request.expectedSettlementAnchor,
        ),
      );
    }

    if (replayOk && settlementOk && !proofOk) {
      return VerificationResult(
        state: VerificationState.partial,
        reasonCode: VerificationReasonCode.okVerificationPartial,
        layers: layers,
        summary: const VerificationSummary(
          headline: 'Partial',
          detail: 'Replay and settlement passed, but provider proof was unavailable.',
        ),
        payload: VerificationPayload(
          verificationLayersPassed: passed,
          verificationLayersFailed: failed,
          replayAnchor: request.expectedReplayAnchor,
          fairDealAnchor: request.expectedFairDealAnchor,
          settlementAnchor: request.expectedSettlementAnchor,
          warnings: <String>['Deal proof bundle missing.'],
        ),
      );
    }

    return VerificationResult(
      state: VerificationState.failed,
      reasonCode: !replayOk
          ? VerificationReasonCode.errVerificationReplayMismatch
          : !proofOk
              ? VerificationReasonCode.errVerificationDealProofFailed
              : VerificationReasonCode.errVerificationSettlementMismatch,
      layers: layers,
      summary: const VerificationSummary(
        headline: 'Failed',
        detail: 'One or more required verification layers did not pass.',
      ),
      payload: VerificationPayload(
        verificationLayersPassed: passed,
        verificationLayersFailed: failed,
        replayAnchor: request.expectedReplayAnchor,
        fairDealAnchor: request.expectedFairDealAnchor,
        settlementAnchor: request.expectedSettlementAnchor,
      ),
    );
  }
}
