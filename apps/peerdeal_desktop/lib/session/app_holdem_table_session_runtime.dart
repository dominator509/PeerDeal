import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';

import 'app_table_session_runtime.dart';

enum AppHoldemProjectionDisposition { applied, rejected }

class AppHoldemProjectionResult {
  const AppHoldemProjectionResult._({
    required this.disposition,
    required this.projection,
    this.sessionResult,
    this.reasonCode,
  });

  const AppHoldemProjectionResult.applied({
    required HoldemCoreProjectionResult projection,
    required AppTableSessionEventBatchResult sessionResult,
  }) : this._(
         disposition: AppHoldemProjectionDisposition.applied,
         projection: projection,
         sessionResult: sessionResult,
       );

  const AppHoldemProjectionResult.rejected({
    required HoldemCoreProjectionResult projection,
    required String reasonCode,
    AppTableSessionEventBatchResult? sessionResult,
  }) : this._(
         disposition: AppHoldemProjectionDisposition.rejected,
         projection: projection,
         sessionResult: sessionResult,
         reasonCode: reasonCode,
       );

  final AppHoldemProjectionDisposition disposition;
  final HoldemCoreProjectionResult projection;
  final AppTableSessionEventBatchResult? sessionResult;
  final String? reasonCode;

  bool get isApplied => disposition == AppHoldemProjectionDisposition.applied;
  bool get isRejected => disposition == AppHoldemProjectionDisposition.rejected;
  List<EventEnvelope> get events => projection.events;
}

enum AppHoldemInboundEventDisposition { applied, rejected }

class AppHoldemInboundEventResult {
  AppHoldemInboundEventResult._({
    required this.disposition,
    required this.handState,
    required this.cursor,
    this.sessionResult,
    this.reasonCode,
    List<String> warnings = const <String>[],
  }) : warnings = List<String>.unmodifiable(warnings);

  AppHoldemInboundEventResult.applied({
    required HoldemHandState handState,
    required HoldemEventCursor cursor,
    required AppTableSessionEventResult sessionResult,
  }) : this._(
         disposition: AppHoldemInboundEventDisposition.applied,
         handState: handState,
         cursor: cursor,
         sessionResult: sessionResult,
       );

  AppHoldemInboundEventResult.rejected({
    required HoldemHandState handState,
    required HoldemEventCursor cursor,
    required String reasonCode,
    AppTableSessionEventResult? sessionResult,
    List<String> warnings = const <String>[],
  }) : this._(
         disposition: AppHoldemInboundEventDisposition.rejected,
         handState: handState,
         cursor: cursor,
         sessionResult: sessionResult,
         reasonCode: reasonCode,
         warnings: warnings,
       );

  final AppHoldemInboundEventDisposition disposition;
  final HoldemHandState handState;
  final HoldemEventCursor cursor;
  final AppTableSessionEventResult? sessionResult;
  final String? reasonCode;
  final List<String> warnings;

  bool get isApplied => disposition == AppHoldemInboundEventDisposition.applied;
  bool get isRejected => !isApplied;
}

/// App-owned composition of Hold'em rules, protocol events, and session truth.
///
/// Hold'em remains responsible for producing variant-valid events. The app
/// session runtime remains responsible for accepting those events into the
/// app's core projection. Variant state and the event cursor advance only
/// after the app boundary commits the complete event batch.
class AppHoldemTableSessionRuntime {
  AppHoldemTableSessionRuntime({
    required AppTableSessionRuntime sessionRuntime,
    required HoldemHandState initialHandState,
    required HoldemEventCursor initialCursor,
    HoldemCoreProjectionAdapter projectionAdapter =
        const HoldemCoreProjectionAdapter(),
    HoldemEventReducer eventReducer = const HoldemEventReducer(),
  }) : _sessionRuntime = sessionRuntime,
       _handState = initialHandState,
       _cursor = initialCursor,
       _projectionAdapter = projectionAdapter,
       _eventReducer = eventReducer {
    _validateInitialComposition();
  }

  final AppTableSessionRuntime _sessionRuntime;
  final HoldemCoreProjectionAdapter _projectionAdapter;
  final HoldemEventReducer _eventReducer;
  HoldemHandState _handState;
  HoldemEventCursor _cursor;
  HoldemCoreProjectionResult? _lastProjection;

  AppTableSessionRuntime get sessionRuntime => _sessionRuntime;
  TableState get coreState => _sessionRuntime.state;
  HoldemHandState get handState => _handState;
  HoldemEventCursor get cursor => _cursor;
  HoldemCoreProjectionResult? get lastProjection => _lastProjection;

  /// Accepts one remote event only after both variant and core projections
  /// have passed preflight. State and cursor remain unchanged on rejection.
  AppHoldemInboundEventResult applyRemoteEvent(
    EventEnvelope event, {
    DateTime? now,
  }) {
    final cursorResult = _cursor.accept(event);
    if (cursorResult.isRejected) {
      return AppHoldemInboundEventResult.rejected(
        handState: _handState,
        cursor: _cursor,
        reasonCode:
            cursorResult.reasonCode ?? 'ERR_HOLDEM_EVENT_CURSOR_REJECTED',
      );
    }

    final reduction = _eventReducer.apply(state: _handState, event: event);
    if (reduction.isRejected) {
      return AppHoldemInboundEventResult.rejected(
        handState: _handState,
        cursor: _cursor,
        reasonCode:
            reduction.reasonCode ?? 'ERR_HOLDEM_EVENT_REDUCTION_REJECTED',
        warnings: reduction.warnings,
      );
    }

    final sessionResult = _sessionRuntime.applyEvent(event, now: now);
    if (!sessionResult.isApplied) {
      return AppHoldemInboundEventResult.rejected(
        handState: _handState,
        cursor: _cursor,
        reasonCode:
            sessionResult.reasonCode ?? 'ERR_HOLDEM_SESSION_EVENT_REJECTED',
        sessionResult: sessionResult,
        warnings: sessionResult.warnings,
      );
    }

    _handState = reduction.state;
    _cursor = cursorResult.cursor;
    return AppHoldemInboundEventResult.applied(
      handState: _handState,
      cursor: _cursor,
      sessionResult: sessionResult,
    );
  }

  AppHoldemProjectionResult startHand() {
    return _commit(
      _projectionAdapter.startHand(
        coreState: coreState,
        handState: _handState,
        cursor: _cursor,
      ),
    );
  }

  AppHoldemProjectionResult applyAction({
    required HoldemTableAction action,
    List<String> dealtBoardCards = const <String>[],
    bool openNextBettingRound = false,
  }) {
    return _commit(
      _projectionAdapter.applyAction(
        coreState: coreState,
        handState: _handState,
        cursor: _cursor,
        action: action,
        dealtBoardCards: dealtBoardCards,
        openNextBettingRound: openNextBettingRound,
      ),
    );
  }

  AppHoldemProjectionResult revealShowdown({
    required ShowdownEvaluationInput input,
  }) {
    return _commit(
      _projectionAdapter.revealShowdown(
        coreState: coreState,
        handState: _handState,
        cursor: _cursor,
        input: input,
      ),
    );
  }

  AppHoldemProjectionResult projectSettlement({
    required HoldemSettlementProjectionGateResult settlement,
    required HoldemHandCompletionGateResult completion,
    required String projectionId,
    required String settlementId,
  }) {
    return _commit(
      _projectionAdapter.projectSettlement(
        coreState: coreState,
        handState: _handState,
        settlement: settlement,
        completion: completion,
        cursor: _cursor,
        projectionId: projectionId,
        settlementId: settlementId,
      ),
    );
  }

  AppHoldemProjectionResult _commit(HoldemCoreProjectionResult projection) {
    if (!projection.isApplied) {
      return AppHoldemProjectionResult.rejected(
        projection: projection,
        reasonCode: projection.reasonCode ?? 'ERR_HOLDEM_PROJECTION_REJECTED',
      );
    }
    if (projection.events.isEmpty) {
      return AppHoldemProjectionResult.rejected(
        projection: projection,
        reasonCode: 'ERR_HOLDEM_PROJECTION_EMPTY',
      );
    }

    final lastEventHash = projection.coreState.metadata['last_event_hash'];
    final sessionResult = _sessionRuntime.applyEventBatch(
      projection.events,
      expectedEventSequence: projection.coreState.eventSequence,
      expectedLastEventHash: lastEventHash is String ? lastEventHash : null,
    );
    if (!sessionResult.isApplied) {
      return AppHoldemProjectionResult.rejected(
        projection: projection,
        reasonCode:
            sessionResult.reasonCode ??
            'ERR_HOLDEM_SESSION_PROJECTION_REJECTED',
        sessionResult: sessionResult,
      );
    }

    _handState = projection.handState;
    _cursor = projection.cursor;
    _lastProjection = projection;
    return AppHoldemProjectionResult.applied(
      projection: projection,
      sessionResult: sessionResult,
    );
  }

  void _validateInitialComposition() {
    final state = _sessionRuntime.state;
    if (state.tableId != _cursor.tableId ||
        state.sessionId != _cursor.sessionId ||
        state.protocolVersion != _cursor.protocolVersion) {
      throw ArgumentError(
        'Holdem session and event cursor identities must match.',
      );
    }
    if (_handState.handId.trim().isEmpty ||
        _handState.handId != _handState.handId.trim()) {
      throw ArgumentError.value(
        _handState.handId,
        'initialHandState.handId',
        'Hand identity must be non-empty and unpadded.',
      );
    }
    if (_cursor.nextEventSeq != state.eventSequence + 1) {
      throw ArgumentError(
        'Holdem event cursor must continue the app session sequence.',
      );
    }

    final expectedPreviousHash = state.eventSequence == 0
        ? genesisEventHash
        : state.metadata['last_event_hash'];
    if (expectedPreviousHash is! String ||
        _cursor.previousEventHash != expectedPreviousHash) {
      throw ArgumentError(
        'Holdem event cursor must continue the app session hash chain.',
      );
    }
  }
}
