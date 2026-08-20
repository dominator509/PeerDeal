import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import '../contracts/verification_engine.dart';
import '../contracts/deal_proof_verifier.dart';
import '../models/deal_proof_limits.dart';
import '../models/deal_proof_bundle.dart';
import '../models/verification_layer_result.dart';
import '../models/verification_payload.dart';
import '../models/verification_reason_code.dart';
import '../models/verification_request.dart';
import '../models/verification_result.dart';
import '../models/verification_scope.dart';
import '../models/verification_state.dart';
import '../models/verification_summary.dart';

class DefaultVerificationEngine implements VerificationEngine {
  const DefaultVerificationEngine({
    this.proofLimits = const DealProofLimits(),
    this.proofVerifier,
  });

  final DealProofLimits proofLimits;
  final DealProofVerifier? proofVerifier;

  @override
  VerificationResult verify(VerificationRequest request) {
    if (request.isWiped) {
      return VerificationResult(
        state: VerificationState.wiped,
        reasonCode: VerificationReasonCode.errVerificationWiped,
        layers: <VerificationLayerResult>[],
        summary: VerificationSummary(
          headline: 'Wiped',
          detail:
              'Verification detail is no longer viewable in supported clients.',
        ),
        payload: VerificationPayload(
          verificationLayersPassed: <String>[],
          verificationLayersFailed: <String>[],
        ),
      );
    }

    if (!_isValidRequest(request)) {
      return _malformedRequestResult();
    }

    final replayOk =
        request.expectedReplayAnchor != null &&
        request.expectedReplayAnchor!.isNotEmpty;
    final proofBundle = request.dealProofBundle;
    final proofPresent = proofBundle != null;
    final proofOk = proofPresent && _verifyProof(proofBundle);
    final settlementOk =
        request.expectedSettlementAnchor != null &&
        request.expectedSettlementAnchor!.isNotEmpty;

    final layers = <VerificationLayerResult>[
      VerificationLayerResult(
        layerId: 'replay_integrity',
        passed: replayOk,
        reason: replayOk ? null : 'Missing replay anchor.',
      ),
      VerificationLayerResult(
        layerId: 'deal_provider_integrity',
        passed: proofOk,
        reason: proofOk
            ? null
            : proofPresent
            ? 'Provider proof verification failed.'
            : 'Missing deal proof bundle.',
      ),
      VerificationLayerResult(
        layerId: 'settlement_integrity',
        passed: settlementOk,
        reason: settlementOk ? null : 'Missing settlement anchor.',
      ),
    ];

    final passed = layers
        .where((l) => l.passed)
        .map((l) => l.layerId)
        .toList(growable: false);
    final failed = layers
        .where((l) => !l.passed)
        .map((l) => l.layerId)
        .toList(growable: false);

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

    if (replayOk && settlementOk && !proofPresent) {
      return VerificationResult(
        state: VerificationState.partial,
        reasonCode: VerificationReasonCode.okVerificationPartial,
        layers: layers,
        summary: const VerificationSummary(
          headline: 'Partial',
          detail:
              'Replay and settlement passed, but provider proof was unavailable.',
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

    if (replayOk && settlementOk && proofPresent && !proofOk) {
      return VerificationResult(
        state: VerificationState.failed,
        reasonCode: VerificationReasonCode.errVerificationDealProofFailed,
        layers: layers,
        summary: const VerificationSummary(
          headline: 'Failed',
          detail: 'Provider proof could not be cryptographically verified.',
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

  bool _isValidRequest(VerificationRequest request) {
    if (!_isSafeRequiredText(request.tableId) ||
        !_isSafeRequiredText(request.sessionId) ||
        !_isSafeRequiredText(request.protocolVersion) ||
        (request.handId != null && !_isSafeRequiredText(request.handId!))) {
      return false;
    }

    if (request.scope == VerificationScope.hand && request.handId == null) {
      return false;
    }

    final hasStart = request.eventSeqStart != null;
    final hasEnd = request.eventSeqEnd != null;
    if (hasStart != hasEnd ||
        (hasStart &&
            (request.eventSeqStart! < 1 ||
                request.eventSeqEnd! < request.eventSeqStart!))) {
      return false;
    }

    for (final anchor in <String?>[
      request.expectedReplayAnchor,
      request.expectedFairDealAnchor,
      request.expectedSettlementAnchor,
    ]) {
      if (anchor != null && !_isSafeRequiredText(anchor)) {
        return false;
      }
    }

    final bundle = request.dealProofBundle;
    if (bundle == null) {
      return true;
    }
    if (!_isSafeBoundedText(
          bundle.providerId,
          proofLimits.maxProviderIdBytes,
        ) ||
        !_isSafeBoundedText(
          bundle.providerVersion,
          proofLimits.maxProviderVersionBytes,
        ) ||
        !_isSafeBoundedText(
          bundle.proofReference,
          proofLimits.maxProofReferenceBytes,
        )) {
      return false;
    }

    final limits = CanonicalJsonLimits(
      maxMapEntries: proofLimits.maxMapEntries,
      maxListItems: proofLimits.maxListItems,
      maxDepth: proofLimits.maxDepth,
      maxTextBytes: proofLimits.maxTextBytes,
      maxNodes: proofLimits.maxNodes,
      maxEncodedBytes: proofLimits.maxProofBytes,
    );
    try {
      canonicalJsonEncode(bundle.normalizedFields, limits: limits);
      if (bundle.rawPayload != null) {
        canonicalJsonEncode(bundle.rawPayload, limits: limits);
      }
    } on Object {
      return false;
    }
    return true;
  }

  bool _verifyProof(DealProofBundle? proofBundle) {
    final verifier = proofVerifier;
    if (proofBundle == null || verifier == null) return false;
    try {
      return verifier.verify(proofBundle);
    } on Object {
      return false;
    }
  }

  bool _isSafeRequiredText(String value) => _isSafeBoundedText(value, 256);

  bool _isSafeBoundedText(String value, int maxBytes) {
    if (value.trim().isEmpty || value.trim() != value) {
      return false;
    }
    if (!CanonicalJsonLimits(
      maxTextBytes: maxBytes,
    ).isWithinUtf8TextLimit(value)) {
      return false;
    }
    return value.codeUnits.every(
      (codeUnit) => codeUnit >= 0x20 && !(codeUnit >= 0x7f && codeUnit <= 0x9f),
    );
  }

  VerificationResult _malformedRequestResult() {
    const failedLayers = <String>[
      'replay_integrity',
      'deal_provider_integrity',
      'settlement_integrity',
    ];
    return VerificationResult(
      state: VerificationState.failed,
      reasonCode: VerificationReasonCode.errVerificationDataIncomplete,
      layers: const <VerificationLayerResult>[
        VerificationLayerResult(
          layerId: 'replay_integrity',
          passed: false,
          reason: 'Verification request is malformed.',
        ),
        VerificationLayerResult(
          layerId: 'deal_provider_integrity',
          passed: false,
          reason: 'Verification request is malformed.',
        ),
        VerificationLayerResult(
          layerId: 'settlement_integrity',
          passed: false,
          reason: 'Verification request is malformed.',
        ),
      ],
      summary: const VerificationSummary(
        headline: 'Failed',
        detail: 'Verification request data was malformed.',
      ),
      payload: VerificationPayload(
        verificationLayersPassed: const <String>[],
        verificationLayersFailed: failedLayers,
      ),
    );
  }
}
