import 'package:meta/meta.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import 'holdem_showdown_coordinator.dart';

@immutable
class HoldemHandSettledEventDraft {
  const HoldemHandSettledEventDraft({required this.payload});

  final Map<String, Object?> payload;
}

class HoldemHandSettledEventBuilder {
  const HoldemHandSettledEventBuilder();

  static const String eventType = 'HandSettled';
  static const String eventVersion = '1.0';
  static const String variantId = 'holdem_nlhe';

  HoldemHandSettledEventDraft buildDraft({
    required HoldemHandCompletionGateResult completion,
    required String settlementId,
    required String projectionId,
  }) {
    if (!completion.isCompleted ||
        completion.projection == null ||
        completion.projection!.isBlocked ||
        completion.projection!.settlement == null) {
      throw ArgumentError.value(
        completion.isCompleted,
        'completion.isCompleted',
        'Only completed hands with successful settlement can emit HandSettled.',
      );
    }

    return HoldemHandSettledEventDraft(
      payload: <String, Object?>{
        'variant_id': variantId,
        'settlement_id': settlementId,
        'projection_id': projectionId,
      },
    );
  }

  EventEnvelope buildEvent({
    required HoldemHandCompletionGateResult completion,
    required String eventId,
    required String protocolVersion,
    required int eventSeq,
    required String tableId,
    required String sessionId,
    required String handId,
    required String emittedAt,
    required String actorRef,
    required String settlementId,
    required String projectionId,
    required String prevEventHash,
    required String eventHash,
  }) {
    final draft = buildDraft(
      completion: completion,
      settlementId: settlementId,
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
}
