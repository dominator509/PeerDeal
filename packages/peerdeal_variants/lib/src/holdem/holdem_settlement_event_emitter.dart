import 'package:meta/meta.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import 'holdem_hand_settled_event_builder.dart';
import 'holdem_settlement_blocked_event_builder.dart';
import 'holdem_settlement_projected_event_builder.dart';
import 'holdem_showdown_coordinator.dart';

@immutable
class HoldemSettlementEventMetadata {
  const HoldemSettlementEventMetadata({
    required this.eventId,
    required this.eventSeq,
    required this.emittedAt,
    required this.prevEventHash,
    required this.eventHash,
  });

  final String eventId;
  final int eventSeq;
  final String emittedAt;
  final String prevEventHash;
  final String eventHash;
}

@immutable
class HoldemSettlementEventEmissionPlan {
  const HoldemSettlementEventEmissionPlan({
    required this.protocolVersion,
    required this.tableId,
    required this.sessionId,
    required this.handId,
    required this.actorRef,
    required this.projectionId,
    required this.settlementId,
    required this.settlementBlocked,
    required this.settlementProjected,
    required this.handSettled,
  });

  final String protocolVersion;
  final String tableId;
  final String sessionId;
  final String handId;
  final String actorRef;
  final String projectionId;
  final String settlementId;
  final HoldemSettlementEventMetadata settlementBlocked;
  final HoldemSettlementEventMetadata settlementProjected;
  final HoldemSettlementEventMetadata handSettled;
}

@immutable
class HoldemSettlementEventEmission {
  const HoldemSettlementEventEmission({
    required this.events,
    this.settlementBlocked,
    this.settlementProjected,
    this.handSettled,
  });

  final List<EventEnvelope> events;
  final EventEnvelope? settlementBlocked;
  final EventEnvelope? settlementProjected;
  final EventEnvelope? handSettled;

  bool get isBlocked => settlementBlocked != null;

  bool get isProjected => settlementProjected != null && handSettled != null;
}

class HoldemSettlementEventEmitter {
  const HoldemSettlementEventEmitter({
    this.blockedBuilder = const HoldemSettlementBlockedEventBuilder(),
    this.projectedBuilder = const HoldemSettlementProjectedEventBuilder(),
    this.handSettledBuilder = const HoldemHandSettledEventBuilder(),
  });

  final HoldemSettlementBlockedEventBuilder blockedBuilder;
  final HoldemSettlementProjectedEventBuilder projectedBuilder;
  final HoldemHandSettledEventBuilder handSettledBuilder;

  HoldemSettlementEventEmission emit({
    required HoldemSettlementProjectionGateResult settlement,
    required HoldemHandCompletionGateResult completion,
    required HoldemSettlementEventEmissionPlan plan,
  }) {
    if (!settlement.isProjected) {
      if (completion.isCompleted) {
        throw ArgumentError.value(
          completion.isCompleted,
          'completion.isCompleted',
          'Blocked settlement emissions cannot include a completed hand.',
        );
      }

      final event = blockedBuilder.buildEvent(
        settlement: settlement,
        eventId: plan.settlementBlocked.eventId,
        protocolVersion: plan.protocolVersion,
        eventSeq: plan.settlementBlocked.eventSeq,
        tableId: plan.tableId,
        sessionId: plan.sessionId,
        handId: plan.handId,
        emittedAt: plan.settlementBlocked.emittedAt,
        actorRef: plan.actorRef,
        projectionId: plan.projectionId,
        prevEventHash: plan.settlementBlocked.prevEventHash,
        eventHash: plan.settlementBlocked.eventHash,
      );

      return HoldemSettlementEventEmission(
        settlementBlocked: event,
        events: List<EventEnvelope>.unmodifiable(<EventEnvelope>[event]),
      );
    }

    if (!completion.isCompleted) {
      throw ArgumentError.value(
        completion.isCompleted,
        'completion.isCompleted',
        'Projected settlement emissions require a completed hand.',
      );
    }

    final projected = projectedBuilder.buildEvent(
      settlement: settlement,
      eventId: plan.settlementProjected.eventId,
      protocolVersion: plan.protocolVersion,
      eventSeq: plan.settlementProjected.eventSeq,
      tableId: plan.tableId,
      sessionId: plan.sessionId,
      handId: plan.handId,
      emittedAt: plan.settlementProjected.emittedAt,
      actorRef: plan.actorRef,
      projectionId: plan.projectionId,
      prevEventHash: plan.settlementProjected.prevEventHash,
      eventHash: plan.settlementProjected.eventHash,
    );

    final settled = handSettledBuilder.buildEvent(
      completion: completion,
      eventId: plan.handSettled.eventId,
      protocolVersion: plan.protocolVersion,
      eventSeq: plan.handSettled.eventSeq,
      tableId: plan.tableId,
      sessionId: plan.sessionId,
      handId: plan.handId,
      emittedAt: plan.handSettled.emittedAt,
      actorRef: plan.actorRef,
      settlementId: plan.settlementId,
      projectionId: plan.projectionId,
      prevEventHash: plan.handSettled.prevEventHash,
      eventHash: plan.handSettled.eventHash,
    );

    return HoldemSettlementEventEmission(
      settlementProjected: projected,
      handSettled: settled,
      events: List<EventEnvelope>.unmodifiable(<EventEnvelope>[
        projected,
        settled,
      ]),
    );
  }
}
