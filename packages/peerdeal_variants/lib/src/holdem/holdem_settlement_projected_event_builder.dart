import 'package:meta/meta.dart';
import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import 'holdem_showdown_coordinator.dart';

@immutable
class HoldemSettlementProjectedEventDraft {
  const HoldemSettlementProjectedEventDraft({
    required this.payload,
    required this.awards,
  });

  final Map<String, Object?> payload;
  final List<Map<String, Object?>> awards;
}

class HoldemSettlementProjectedEventBuilder {
  const HoldemSettlementProjectedEventBuilder();

  static const String eventType = 'SettlementProjected';
  static const String eventVersion = '1.0';
  static const String variantId = 'holdem_nlhe';

  HoldemSettlementProjectedEventDraft buildDraft({
    required HoldemSettlementProjectionGateResult settlement,
    required String projectionId,
  }) {
    if (!settlement.isProjected ||
        settlement.projection == null ||
        settlement.projection!.isBlocked ||
        settlement.projection!.settlement == null) {
      throw ArgumentError.value(
        settlement.isProjected,
        'settlement.isProjected',
        'Only successful settlement projections can emit SettlementProjected.',
      );
    }

    final awards = _aggregateAwardsBySeat(
      settlement.projection!.settlement!.awards,
    );

    return HoldemSettlementProjectedEventDraft(
      awards: awards,
      payload: <String, Object?>{
        'variant_id': variantId,
        'projection_id': projectionId,
        'awards': awards,
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

  List<Map<String, Object?>> _aggregateAwardsBySeat(Iterable<PotAward> awards) {
    final totals = <String, int>{};
    for (final award in awards) {
      totals.update(
        award.seatId,
        (current) => current + award.amount,
        ifAbsent: () => award.amount,
      );
    }

    final seatIds = totals.keys.toList()..sort();
    return List<Map<String, Object?>>.unmodifiable(
      seatIds.map(
        (seatId) => <String, Object?>{
          'seat_id': seatId,
          'amount': totals[seatId]!,
        },
      ),
    );
  }
}
