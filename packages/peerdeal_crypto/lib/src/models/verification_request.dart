import 'deal_proof_bundle.dart';
import 'verification_scope.dart';

class VerificationRequest {
  const VerificationRequest({
    required this.tableId,
    required this.sessionId,
    required this.scope,
    required this.protocolVersion,
    this.handId,
    this.eventSeqStart,
    this.eventSeqEnd,
    this.expectedReplayAnchor,
    this.expectedFairDealAnchor,
    this.expectedSettlementAnchor,
    this.dealProofBundle,
    this.isWiped = false,
  });

  final String tableId;
  final String sessionId;
  final String? handId;
  final VerificationScope scope;
  final String protocolVersion;
  final int? eventSeqStart;
  final int? eventSeqEnd;
  final String? expectedReplayAnchor;
  final String? expectedFairDealAnchor;
  final String? expectedSettlementAnchor;
  final DealProofBundle? dealProofBundle;
  final bool isWiped;
}
