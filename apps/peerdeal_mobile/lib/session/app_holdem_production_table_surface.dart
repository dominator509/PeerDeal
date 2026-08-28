import 'package:flutter/widgets.dart';
import 'package:peerdeal_ui_kit/peerdeal_ui_kit.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';

import 'app_holdem_table_session_route.dart';
import 'app_holdem_table_session_runtime.dart';

/// App-owned production Hold'em surface.
///
/// The widget only reads variant state from the injected runtime. It does not
/// evaluate rules or maintain a second copy of table truth. Mutating controls
/// are shown only when a validated transport publisher is available for the
/// configured local seat.
class AppHoldemProductionTableSurface extends StatefulWidget {
  const AppHoldemProductionTableSurface({
    super.key,
    required this.routeContext,
    required this.localPeerId,
    required this.localSeat,
  });

  final AppHoldemTableSessionRouteContext routeContext;
  final String localPeerId;
  final int localSeat;

  @override
  State<AppHoldemProductionTableSurface> createState() =>
      _AppHoldemProductionTableSurfaceState();
}

class _AppHoldemProductionTableSurfaceState
    extends State<AppHoldemProductionTableSurface> {
  AppHoldemProjectionResult? _pendingProjection;
  int _pendingEventIndex = 0;
  String? _statusMessage;
  bool _busy = false;
  int _operationGeneration = 0;

  @override
  void didUpdateWidget(AppHoldemProductionTableSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldContext = oldWidget.routeContext;
    final newContext = widget.routeContext;
    final oldTransport = oldContext.transport;
    final newTransport = newContext.transport;
    final transportUnchanged =
        oldTransport.available == newTransport.available &&
        identical(oldTransport.session, newTransport.session) &&
        identical(oldTransport.source, newTransport.source);
    if (identical(oldContext.runtime, newContext.runtime) &&
        identical(
          oldContext.snapshotCoordinator,
          newContext.snapshotCoordinator,
        ) &&
        oldContext.peerId == newContext.peerId &&
        oldWidget.localPeerId == widget.localPeerId &&
        oldWidget.localSeat == widget.localSeat &&
        transportUnchanged) {
      return;
    }

    _operationGeneration += 1;
    _pendingProjection = null;
    _pendingEventIndex = 0;
    _statusMessage = null;
    _busy = false;
  }

  @override
  void dispose() {
    _operationGeneration += 1;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routeContext = widget.routeContext;
    final runtime = routeContext.runtime;
    final hand = runtime.handState;
    final publisher = routeContext.createProjectionPublisher(
      localPeerId: widget.localPeerId,
    );
    final transportReady =
        routeContext.transport.available && publisher != null;
    final canAct = _canMutate(hand, transportReady);

    return PeerDealAppScaffold(
      title: "Hold'em table",
      subtitle: transportReady
          ? 'Live peer session'
          : 'Peer session unavailable',
      actions: <Widget>[
        if (_pendingProjection != null &&
            publisher != null &&
            !(routeContext.snapshotCoordinator?.hasPending ?? false))
          PeerDealActionButton(label: 'Retry sync', onPressed: _retryPending),
        if (routeContext.snapshotCoordinator?.hasPending ?? false)
          PeerDealActionButton(
            label: 'Retry persistence',
            onPressed: _retryPersistence,
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          PeerDealStatusPill(
            label: _statusLabel(hand, transportReady, canAct),
            severity: _statusSeverity(hand, transportReady, canAct),
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Session',
            children: <Widget>[
              PeerDealInfoRow(
                label: 'Session ID',
                value: _safeValue(
                  runtime.coreState.sessionId,
                  fallback: 'Session unavailable',
                ),
              ),
              PeerDealInfoRow(
                label: 'Hand ID',
                value: _safeValue(hand.handId, fallback: 'Hand unavailable'),
              ),
            ],
          ),
          _buildSection(
            title: 'Table state',
            children: <Widget>[
              PeerDealInfoRow(label: 'Phase', value: _phaseLabel(hand.phase)),
              PeerDealInfoRow(
                label: 'Betting round',
                value: _bettingRoundLabel(hand.bettingRound),
              ),
              PeerDealInfoRow(label: 'Pot', value: hand.pot.toString()),
              PeerDealInfoRow(
                label: 'Current actor',
                value: _actorLabel(hand.currentActorSeat),
              ),
              PeerDealInfoRow(
                label: 'Board',
                value: _safeCardList(hand.boardCards),
              ),
            ],
          ),
          _buildSection(
            title: 'Seats',
            children: <Widget>[
              for (final seat in hand.seats) _buildSeatRow(seat),
            ],
          ),
          _buildSection(
            title: 'Connection',
            children: <Widget>[
              PeerDealInfoRow(
                label: 'Transport',
                value: transportReady ? 'Connected' : 'Unavailable',
              ),
              if (routeContext.snapshotCoordinator?.hasPending ?? false)
                const PeerDealInfoRow(
                  label: 'Persistence',
                  value: 'Checkpoint pending',
                ),
              if (_statusMessage != null)
                PeerDealInfoRow(label: 'Status', value: _statusMessage!),
            ],
          ),
          _buildSection(
            title: 'Controls',
            children: <Widget>[_buildActionArea(hand, transportReady, canAct)],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFFE8F3EF),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 4),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSeatRow(HoldemSeatState seat) {
    final isActing =
        seat.seat == widget.routeContext.runtime.handState.currentActorSeat;
    final isLocal = seat.seat == widget.localSeat;
    final flags = <String>[
      if (seat.folded) 'folded',
      if (seat.allIn) 'all-in',
      if (isLocal) 'you',
      if (isActing) 'acting',
    ];
    final suffix = flags.isEmpty ? '' : ' (${flags.join(', ')})';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isActing
              ? const Color(0xFF332B14)
              : isLocal
              ? const Color(0xFF102C26)
              : const Color(0xFF10201D),
          border: Border.all(
            color: isActing
                ? const Color(0xFFA78932)
                : isLocal
                ? const Color(0xFF2C6B5D)
                : const Color(0xFF1F3A33),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: PeerDealInfoRow(
            label: 'Seat ${seat.seat}',
            value:
                'Stack ${seat.stack}, committed ${seat.committedThisHand}$suffix',
          ),
        ),
      ),
    );
  }

  Widget _buildActionArea(
    HoldemHandState hand,
    bool transportReady,
    bool canAct,
  ) {
    if (_busy) {
      return const PeerDealInfoRow(label: 'Actions', value: 'Synchronizing');
    }
    if (_hasPendingWork) {
      return const PeerDealInfoRow(
        label: 'Actions',
        value: 'Unavailable until pending synchronization completes',
      );
    }
    if (hand.phase == HoldemHandPhase.handIdle && transportReady) {
      return PeerDealActionButton(label: 'Start hand', onPressed: _startHand);
    }
    if (!transportReady) {
      return const PeerDealInfoRow(
        label: 'Actions',
        value: 'Unavailable until peer transport is connected',
      );
    }
    if (!canAct) {
      return PeerDealInfoRow(
        label: 'Actions',
        value: hand.currentActorSeat == widget.localSeat
            ? 'Unavailable during ${_phaseLabel(hand.phase)}'
            : 'Waiting for seat ${hand.currentActorSeat}',
      );
    }

    final actor = _seatFor(hand, widget.localSeat);
    if (actor == null) {
      return const PeerDealInfoRow(
        label: 'Actions',
        value: 'Unavailable for the configured seat',
      );
    }

    final buttons = <Widget>[
      PeerDealActionButton(
        label: 'Fold',
        onPressed: () => _submitAction(
          HoldemTableAction(
            actorSeat: widget.localSeat,
            type: HoldemTableActionType.fold,
          ),
        ),
      ),
      if (hand.currentBetToCall > actor.committedThisRound)
        PeerDealActionButton(
          label: 'Call',
          onPressed: () => _submitAction(
            HoldemTableAction(
              actorSeat: widget.localSeat,
              type: HoldemTableActionType.call,
            ),
          ),
        )
      else
        PeerDealActionButton(
          label: 'Check',
          onPressed: () => _submitAction(
            HoldemTableAction(
              actorSeat: widget.localSeat,
              type: HoldemTableActionType.check,
            ),
          ),
        ),
    ];

    if (actor.stack > 0) {
      buttons.add(
        PeerDealActionButton(
          label: 'All-in',
          onPressed: () => _submitAction(
            HoldemTableAction(
              actorSeat: widget.localSeat,
              type: HoldemTableActionType.allIn,
            ),
          ),
        ),
      );
    }

    final minimumRaiseTotal = hand.currentBetToCall + hand.minimumRaiseAmount;
    final raiseContribution = minimumRaiseTotal - actor.committedThisRound;
    if (raiseContribution > 0 && raiseContribution <= actor.stack) {
      buttons.add(
        PeerDealActionButton(
          label: hand.currentBetToCall > 0 ? 'Raise min' : 'Bet min',
          onPressed: () => _submitAction(
            HoldemTableAction(
              actorSeat: widget.localSeat,
              type: hand.currentBetToCall > 0
                  ? HoldemTableActionType.raise
                  : HoldemTableActionType.bet,
              amount: minimumRaiseTotal,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const PeerDealInfoRow(label: 'Actions', value: 'Your turn'),
        Wrap(spacing: 8, runSpacing: 8, children: buttons),
      ],
    );
  }

  bool _canMutate(HoldemHandState hand, bool transportReady) {
    return !_busy &&
        !_hasPendingWork &&
        transportReady &&
        widget.localSeat > 0 &&
        hand.currentActorSeat == widget.localSeat &&
        hand.seats.any((seat) => seat.seat == widget.localSeat) &&
        _isBettingPhase(hand.phase);
  }

  String _statusLabel(HoldemHandState hand, bool transportReady, bool canAct) {
    if (_busy) return 'Synchronizing';
    if (widget.routeContext.snapshotCoordinator?.hasPending ?? false) {
      return 'Persistence pending';
    }
    if (_pendingProjection != null) return 'Sync pending';
    if (!transportReady) return 'Transport unavailable';
    if (canAct) return 'Your turn';
    if (_isBettingPhase(hand.phase)) return 'Waiting';
    return _phaseLabel(hand.phase);
  }

  String _statusSeverity(
    HoldemHandState hand,
    bool transportReady,
    bool canAct,
  ) {
    if (!transportReady ||
        _pendingProjection != null ||
        (widget.routeContext.snapshotCoordinator?.hasPending ?? false)) {
      return 'warning';
    }
    if (canAct) return 'success';
    return _isBettingPhase(hand.phase) ? 'info' : 'neutral';
  }

  Future<void> _startHand() async {
    final operationGeneration = _operationGeneration;
    final publisher = widget.routeContext.createProjectionPublisher(
      localPeerId: widget.localPeerId,
    );
    if (_busy ||
        _hasPendingWork ||
        publisher == null ||
        !widget.routeContext.transport.available ||
        widget.routeContext.runtime.handState.phase !=
            HoldemHandPhase.handIdle) {
      return;
    }
    setState(() {
      _busy = true;
      _statusMessage = null;
    });
    try {
      final result = widget.routeContext.runtime.startHand();
      await _finishProjection(
        result,
        acceptedLabel: 'Hand start',
        operationGeneration: operationGeneration,
      );
    } on Object {
      if (_isCurrentOperation(operationGeneration)) {
        setState(() {
          _busy = false;
          _statusMessage = 'Hand start was rejected';
        });
      }
    }
  }

  Future<void> _submitAction(HoldemTableAction action) async {
    final operationGeneration = _operationGeneration;
    final publisher = widget.routeContext.createProjectionPublisher(
      localPeerId: widget.localPeerId,
    );
    if (!_canMutate(
      widget.routeContext.runtime.handState,
      widget.routeContext.transport.available && publisher != null,
    )) {
      return;
    }
    final normalizedAction = HoldemTableAction(
      actorSeat: widget.localSeat,
      type: action.type,
      amount: action.amount,
    );
    setState(() {
      _busy = true;
      _statusMessage = null;
    });
    try {
      final result = widget.routeContext.runtime.applyAction(
        action: normalizedAction,
      );
      await _finishProjection(
        result,
        acceptedLabel: 'Action',
        operationGeneration: operationGeneration,
      );
    } on Object {
      if (_isCurrentOperation(operationGeneration)) {
        setState(() {
          _busy = false;
          _statusMessage = 'Action was rejected';
        });
      }
    }
  }

  Future<void> _finishProjection(
    AppHoldemProjectionResult projection, {
    required String acceptedLabel,
    required int operationGeneration,
  }) async {
    if (!_isCurrentOperation(operationGeneration)) return;
    if (projection.isRejected) {
      setState(() {
        _busy = false;
        _statusMessage = '$acceptedLabel was rejected';
      });
      return;
    }

    final publisher = widget.routeContext.createProjectionPublisher(
      localPeerId: widget.localPeerId,
    );

    final coordinator = widget.routeContext.snapshotCoordinator;
    if (coordinator != null) {
      final persistenceResult = await coordinator.persist(
        tableState: widget.routeContext.runtime.coreState,
        handState: widget.routeContext.runtime.handState,
        eventCursor: widget.routeContext.runtime.cursor,
        events: projection.events,
        shouldPersist: () => _isCurrentOperation(operationGeneration),
      );
      if (!_isCurrentOperation(operationGeneration)) return;
      if (!persistenceResult.isSuccess) {
        _setPendingProjection(
          projection,
          nextEventIndex: 0,
          message: '$acceptedLabel accepted locally; persistence is pending',
          operationGeneration: operationGeneration,
        );
        return;
      }
    }

    if (publisher == null) {
      _setPendingProjection(
        projection,
        nextEventIndex: 0,
        message: '$acceptedLabel accepted locally; synchronization is pending',
        operationGeneration: operationGeneration,
      );
      return;
    }

    try {
      final publishResult = await publisher.publish(projection);
      if (!_isCurrentOperation(operationGeneration)) return;
      if (publishResult.isComplete) {
        setState(() {
          _busy = false;
          _pendingProjection = null;
          _pendingEventIndex = 0;
          _statusMessage = '$acceptedLabel synchronized';
        });
      } else {
        _setPendingProjection(
          projection,
          nextEventIndex: publishResult.sentEventCount,
          message:
              '$acceptedLabel accepted locally; synchronization is pending',
          operationGeneration: operationGeneration,
        );
      }
    } on Object {
      if (_isCurrentOperation(operationGeneration)) {
        _setPendingProjection(
          projection,
          nextEventIndex: 0,
          message:
              '$acceptedLabel accepted locally; synchronization is pending',
          operationGeneration: operationGeneration,
        );
      }
    }
    if (!_isCurrentOperation(operationGeneration)) return;
    widget.routeContext.refresh();
  }

  Future<void> _retryPending() async {
    final operationGeneration = _operationGeneration;
    final projection = _pendingProjection;
    if (projection == null || _busy) return;
    setState(() {
      _busy = true;
      _statusMessage = null;
    });
    try {
      final coordinator = widget.routeContext.snapshotCoordinator;
      if (coordinator != null && coordinator.hasPending) {
        final persistenceResult = await coordinator.retryPending();
        if (!_isCurrentOperation(operationGeneration)) return;
        if (!persistenceResult.isSuccess) {
          setState(() {
            _busy = false;
            _statusMessage = 'Persistence is still pending';
          });
          return;
        }
      }

      final publisher = widget.routeContext.createProjectionPublisher(
        localPeerId: widget.localPeerId,
      );
      if (publisher == null) {
        if (_isCurrentOperation(operationGeneration)) {
          setState(() {
            _busy = false;
            _statusMessage =
                'Transport is unavailable; synchronization is pending';
          });
        }
        return;
      }
      final result = await publisher.publish(
        projection,
        startEventIndex: _pendingEventIndex,
      );
      if (!_isCurrentOperation(operationGeneration)) return;
      setState(() {
        _busy = false;
        if (result.isComplete) {
          _pendingProjection = null;
          _pendingEventIndex = 0;
          _statusMessage = 'Synchronization complete';
        } else {
          _pendingEventIndex = result.sentEventCount;
          _statusMessage = 'Synchronization is still pending';
        }
      });
    } on Object {
      if (_isCurrentOperation(operationGeneration)) {
        setState(() {
          _busy = false;
          _statusMessage = 'Synchronization is still pending';
        });
      }
    }
  }

  Future<void> _retryPersistence() async {
    final operationGeneration = _operationGeneration;
    final coordinator = widget.routeContext.snapshotCoordinator;
    if (coordinator == null || !coordinator.hasPending || _busy) return;
    setState(() {
      _busy = true;
      _statusMessage = null;
    });
    final result = await coordinator.retryPending();
    if (!_isCurrentOperation(operationGeneration)) return;
    setState(() {
      _busy = false;
      _statusMessage = result.isSuccess
          ? 'Persistence synchronized'
          : 'Persistence is still pending';
    });
    widget.routeContext.refresh();
  }

  void _setPendingProjection(
    AppHoldemProjectionResult projection, {
    required int nextEventIndex,
    required String message,
    required int operationGeneration,
  }) {
    if (!_isCurrentOperation(operationGeneration)) return;
    setState(() {
      _busy = false;
      _pendingProjection = projection;
      _pendingEventIndex = nextEventIndex;
      _statusMessage = message;
    });
  }

  bool _isCurrentOperation(int operationGeneration) {
    return mounted && operationGeneration == _operationGeneration;
  }

  bool get _hasPendingWork =>
      _pendingProjection != null ||
      (widget.routeContext.snapshotCoordinator?.hasPending ?? false);

  HoldemSeatState? _seatFor(HoldemHandState hand, int seatNumber) {
    for (final seat in hand.seats) {
      if (seat.seat == seatNumber) return seat;
    }
    return null;
  }

  bool _isBettingPhase(HoldemHandPhase phase) {
    return phase == HoldemHandPhase.bettingPreflop ||
        phase == HoldemHandPhase.bettingFlop ||
        phase == HoldemHandPhase.bettingTurn ||
        phase == HoldemHandPhase.bettingRiver;
  }

  String _actorLabel(int seat) => seat > 0 ? 'Seat $seat' : 'None';

  String _bettingRoundLabel(HoldemBettingRound round) {
    return switch (round) {
      HoldemBettingRound.none => 'None',
      HoldemBettingRound.preflop => 'Preflop',
      HoldemBettingRound.flop => 'Flop',
      HoldemBettingRound.turn => 'Turn',
      HoldemBettingRound.river => 'River',
    };
  }

  String _phaseLabel(HoldemHandPhase phase) {
    return switch (phase) {
      HoldemHandPhase.handIdle => 'Waiting to start',
      HoldemHandPhase.handPreparing => 'Preparing hand',
      HoldemHandPhase.blindsPosting => 'Posting blinds',
      HoldemHandPhase.dealingHole => 'Dealing hole cards',
      HoldemHandPhase.bettingPreflop => 'Betting preflop',
      HoldemHandPhase.dealingFlop => 'Dealing flop',
      HoldemHandPhase.bettingFlop => 'Betting flop',
      HoldemHandPhase.dealingTurn => 'Dealing turn',
      HoldemHandPhase.bettingTurn => 'Betting turn',
      HoldemHandPhase.dealingRiver => 'Dealing river',
      HoldemHandPhase.bettingRiver => 'Betting river',
      HoldemHandPhase.showdownPrep => 'Preparing showdown',
      HoldemHandPhase.showdownReveal => 'Revealing showdown',
      HoldemHandPhase.settling => 'Settling hand',
      HoldemHandPhase.handComplete => 'Hand complete',
      HoldemHandPhase.handAbortedSafe => 'Hand stopped safely',
    };
  }

  String _safeCardList(List<String> cards) {
    final safeCards = cards
        .take(5)
        .map((card) => _safeValue(card, fallback: 'hidden'))
        .toList(growable: false);
    return safeCards.isEmpty ? 'None' : safeCards.join(', ');
  }

  String _safeValue(String value, {required String fallback}) {
    if (value.isEmpty || value.length > 64 || value.trim() != value) {
      return fallback;
    }
    if (!RegExp(r'^[A-Za-z0-9._:-]+$').hasMatch(value)) return fallback;
    return value;
  }
}
