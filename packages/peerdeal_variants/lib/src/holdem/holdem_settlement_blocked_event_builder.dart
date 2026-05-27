import 'package:meta/meta.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import 'holdem_showdown_coordinator.dart';

@immutable
class HoldemSettlementBlockedEventDraft {
  const HoldemSettlementBlockedEventDraft({
    required this.payload,
    required this.reasonCodes,
    required this.warnings,
  });

  final Map<String, Object?> payload;
  final List<String> reasonCodes;
  final List<String> warnings;
}

class HoldemSettlementBlockedEventBuilder {
  const HoldemSettlementBlockedEventBuilder();

  static const String eventType = 'SettlementBlocked';
  static const String eventVersion = '1.0';
  static const String variantId = 'holdem_nlhe';

  HoldemSettlementBlockedEventDraft buildDraft({
    required HoldemSettlementProjectionGateResult settlement,
    required String projectionId,
  }) {
    if (settlement.isProjected) {
      throw ArgumentError.value(
        settlement.isProjected,
        'settlement.isProjected',
        'A projected settlement cannot emit SettlementBlocked.',
      );
    }

    final warnings = List<String>.unmodifiable(settlement.warnings);
    final reasonCodes = _reasonCodesFromWarnings(warnings);

    return HoldemSettlementBlockedEventDraft(
      reasonCodes: reasonCodes,
      warnings: warnings,
      payload: <String, Object?>{
        'variant_id': variantId,
        'projection_id': projectionId,
        'reason_codes': reasonCodes,
        'warnings': warnings,
      },
    );
  }

  EventEnvelope buildEvent({
    required HoldemSettlementProjectionGateResult settlement,
    required String eventId,
    required String protocolVersion,
    required int eventSeq,
    required String tableId,
    required String sessionId,
    required String handId,
    required String emittedAt,
    required String actorRef,
    required String projectionId,
    required String prevEventHash,
    required String eventHash,
  }) {
    final draft = buildDraft(
      settlement: settlement,
      projectionId: projectionId,
    );

    return EventEnvelope(
      eventId: eventId,
      eventType: eventType,
      eventVersion: eventVersion,
      protocolVersion: protocolVersion,
      eventSeq: eventSeq,
      tableId: tableId,
      sessionId: sessionId,
      handId: handId,
      emittedAt: emittedAt,
      actorRef: actorRef,
      payload: draft.payload,
      prevEventHash: prevEventHash,
      eventHash: eventHash,
    );
  }

  List<String> _reasonCodesFromWarnings(List<String> warnings) {
    final reasonCodes = <String>[];

    void addReasonCode(String reasonCode) {
      if (!reasonCodes.contains(reasonCode)) {
        reasonCodes.add(reasonCode);
      }
    }

    if (warnings.contains('ERR_HOLDEM_SETTLEMENT_PROJECT_EMPTY_POT') ||
        warnings.contains('ERR_HOLDEM_SETTLEMENT_PROJECT_EMPTY_COMMITMENTS')) {
      addReasonCode('ERR_HOLDEM_SETTLEMENT_PROJECT_EMPTY_POT');
    }

    if (warnings.contains('ERR_HOLDEM_SETTLEMENT_PROJECT_INVALID_SHOWDOWN') ||
        warnings.contains('ERR_HOLDEM_SETTLEMENT_PROJECT_EMPTY_EVALUATION') ||
        warnings.any((warning) => warning.startsWith('ERR_HOLDEM_SHOWDOWN_'))) {
      addReasonCode('ERR_HOLDEM_SETTLEMENT_PROJECT_INVALID_SHOWDOWN');
    }

    if (warnings.contains('ERR_HOLDEM_SETTLEMENT_PROJECT_UNAWARDABLE')) {
      addReasonCode('ERR_HOLDEM_SETTLEMENT_PROJECT_UNAWARDABLE');
    }

    if (reasonCodes.isEmpty && warnings.isNotEmpty) {
      return const <String>['ERR_HOLDEM_SETTLEMENT_PROJECT_INVALID_SHOWDOWN'];
    }

    return List<String>.unmodifiable(reasonCodes);
  }
}
