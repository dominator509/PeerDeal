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
        if (_pendingProjection != null && publisher != null)
          PeerDealActionButton(label: 'Retry sync', onPressed: _retryPending),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          PeerDealStatusPill(
            label: _statusLabel(hand, transportReady, canAct),
            severity: _statusSeverity(hand, transportReady, canAct),
          ),
          const SizedBox(height: 12),
          PeerDealInfoRow(
            label: 'Session',
            value: _safeValue(
              runtime.coreState.sessionId,
              fallback: 'Session unavailable',
            ),
          ),
          PeerDealInfoRow(
            label: 'Hand',
            value: _safeValue(hand.handId, fallback: 'Hand unavailable'),
          ),
          PeerDealInfoRow(label: 'Phase', value: hand.phase.name),
          PeerDealInfoRow(
            label: 'Betting round',
            value: hand.bettingRound.name,
          ),
          PeerDealInfoRow(label: 'Pot', value: hand.pot.toString()),
          PeerDealInfoRow(
            label: 'Current actor',
            value: 'Seat ${hand.currentActorSeat}',
          ),
          PeerDealInfoRow(
            label: 'Board',
            value: _safeCardList(hand.boardCards),
          ),
          const SizedBox(height: 12),
          const Text('Seats'),
          const SizedBox(height: 4),
          for (final seat in hand.seats) _buildSeatRow(seat),
          const SizedBox(height: 12),
          PeerDealInfoRow(
            label: 'Transport',
            value: transportReady ? 'Connected' : 'Unavailable',
          ),
          if (_statusMessage != null)
            PeerDealInfoRow(label: 'Status', value: _statusMessage!),
          const SizedBox(height: 12),
          _buildActionArea(hand, transportReady, canAct),
        ],
      ),
    );
  }

  Widget _buildSeatRow(HoldemSeatState seat) {
    final flags = <String>[
      if (seat.folded) 'folded',
      if (seat.allIn) 'all-in',
      if (seat.seat == widget.localSeat) 'you',
      if (seat.seat == widget.routeContext.runtime.handState.currentActorSeat)
        'acting',
    ];
    final suffix = flags.isEmpty ? '' : ' (${flags.join(', ')})';
    return PeerDealInfoRow(
      label: 'Seat ${seat.seat}',
      value: 'Stack ${seat.stack}, committed ${seat.committedThisHand}$suffix',
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
            ? 'Unavailable during ${hand.phase.name}'
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
          const HoldemTableAction(
            actorSeat: 0,
            type: HoldemTableActionType.fold,
          ),
        ),
      ),
      if (hand.currentBetToCall > actor.committedThisRound)
        PeerDealActionButton(
          label: 'Call',
          onPressed: () => _submitAction(
            const HoldemTableAction(
              actorSeat: 0,
              type: HoldemTableActionType.call,
            ),
          ),
        )
      else
        PeerDealActionButton(
          label: 'Check',
          onPressed: () => _submitAction(
            const HoldemTableAction(
              actorSeat: 0,
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
            const HoldemTableAction(
              actorSeat: 0,
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
        transportReady &&
        widget.localSeat > 0 &&
        hand.currentActorSeat == widget.localSeat &&
        hand.seats.any((seat) => seat.seat == widget.localSeat) &&
        _isBettingPhase(hand.phase);
  }

  String _statusLabel(HoldemHandState hand, bool transportReady, bool canAct) {
    if (_busy) return 'Synchronizing';
    if (_pendingProjection != null) return 'Sync pending';
    if (!transportReady) return 'Transport unavailable';
    if (canAct) return 'Your turn';
    if (_isBettingPhase(hand.phase)) return 'Waiting';
    return hand.phase.name;
  }

  String _statusSeverity(
    HoldemHandState hand,
    bool transportReady,
    bool canAct,
  ) {
    if (!transportReady || _pendingProjection != null) return 'warning';
    if (canAct) return 'success';
    return _isBettingPhase(hand.phase) ? 'info' : 'neutral';
  }

  Future<void> _startHand() async {
    final publisher = widget.routeContext.createProjectionPublisher(
      localPeerId: widget.localPeerId,
    );
    if (_busy ||
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
      await _finishProjection(result, acceptedLabel: 'Hand start');
    } on Object {
      if (mounted) {
        setState(() {
          _busy = false;
          _statusMessage = 'Hand start was rejected';
        });
      }
    }
  }

  Future<void> _submitAction(HoldemTableAction action) async {
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
      await _finishProjection(result, acceptedLabel: 'Action');
    } on Object {
      if (mounted) {
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
  }) async {
    if (!mounted) return;
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
    if (publisher == null) {
      _setPendingProjection(
        projection,
        nextEventIndex: 0,
        message: '$acceptedLabel accepted locally; synchronization is pending',
      );
      return;
    }

    try {
      final publishResult = await publisher.publish(projection);
      if (!mounted) return;
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
        );
      }
    } on Object {
      if (mounted) {
        _setPendingProjection(
          projection,
          nextEventIndex: 0,
          message:
              '$acceptedLabel accepted locally; synchronization is pending',
        );
      }
    }
    if (!mounted) return;
    widget.routeContext.refresh();
  }

  Future<void> _retryPending() async {
    final projection = _pendingProjection;
    if (projection == null || _busy) return;
    final publisher = widget.routeContext.createProjectionPublisher(
      localPeerId: widget.localPeerId,
    );
    if (publisher == null) {
      setState(() {
        _statusMessage = 'Transport is unavailable; synchronization is pending';
      });
      return;
    }
    setState(() {
      _busy = true;
      _statusMessage = null;
    });
    try {
      final result = await publisher.publish(
        projection,
        startEventIndex: _pendingEventIndex,
      );
      if (!mounted) return;
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
      if (mounted) {
        setState(() {
          _busy = false;
          _statusMessage = 'Synchronization is still pending';
        });
      }
    }
  }

  void _setPendingProjection(
    AppHoldemProjectionResult projection, {
    required int nextEventIndex,
    required String message,
  }) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _pendingProjection = projection;
      _pendingEventIndex = nextEventIndex;
      _statusMessage = message;
    });
  }

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
