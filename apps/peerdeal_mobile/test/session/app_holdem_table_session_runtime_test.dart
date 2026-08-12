import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_mobile/recovery/app_recovery_retention_coordinator.dart';
import 'package:peerdeal_mobile/recovery/app_recovery_session_close_coordinator.dart';
import 'package:peerdeal_mobile/recovery/app_recovery_session_close_event_adapter.dart';
import 'package:peerdeal_mobile/session/app_holdem_table_session_runtime.dart';
import 'package:peerdeal_mobile/session/app_holdem_table_session_transport_publisher.dart';
import 'package:peerdeal_mobile/session/app_table_session_runtime.dart';
import 'package:peerdeal_network/peerdeal_network.dart';
import 'package:peerdeal_privacy/peerdeal_privacy.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';
import 'package:test/test.dart';

void main() {
  test('copies and freezes inbound warning diagnostics', () {
    final runtime = _runtime(_preflopState());
    final warnings = <String>['warning_1'];
    final result = AppHoldemInboundEventResult.rejected(
      handState: runtime.handState,
      cursor: runtime.cursor,
      reasonCode: 'ERR_TEST',
      warnings: warnings,
    );

    warnings.add('warning_2');
    expect(result.warnings, ['warning_1']);
    expect(() => result.warnings.add('warning_3'), throwsUnsupportedError);
  });

  test('commits start and action projections through the app session', () {
    final runtime = _runtime(_preflopState());

    final started = runtime.startHand();
    expect(started.isApplied, isTrue);
    expect(started.events.single.eventType, 'HandStarted');
    expect(runtime.coreState.eventSequence, 2);

    final acted = runtime.applyAction(
      action: const HoldemTableAction(
        actorSeat: 1,
        type: HoldemTableActionType.call,
      ),
      dealtBoardCards: const <String>['Ah', 'Kd', '2c'],
      openNextBettingRound: true,
    );

    expect(acted.isApplied, isTrue);
    expect(acted.events.single.eventType, 'PlayerCalled');
    expect(runtime.handState.phase, HoldemHandPhase.bettingFlop);
    expect(runtime.coreState.eventSequence, 3);
    expect(runtime.sessionRuntime.acceptedEventCount, 2);
    expect(runtime.cursor.nextEventSeq, 4);
  });

  test(
    'publishes accepted projections as canonical transport frames',
    () async {
      final runtime = _runtime(_preflopState());
      final projection = runtime.startHand();
      final sender = _RecordingTransportSender();
      final publisher = AppHoldemProjectionTransportPublisher(
        sender: sender,
        localPeerId: 'peer_local',
        remotePeerId: 'peer_remote',
      );

      final result = await publisher.publish(projection);

      expect(result.isComplete, isTrue);
      expect(result.sentEventCount, 1);
      expect(sender.frames.single.fromPeerId, 'peer_local');
      expect(sender.frames.single.toPeerId, 'peer_remote');
      expect(sender.frames.single.sequence, projection.events.single.eventSeq);
      expect(
        const EventEnvelopeCodec().decode(sender.frames.single.payload).eventId,
        projection.events.single.eventId,
      );
    },
  );

  test(
    'rejects unsafe peer identities before sending projection frames',
    () async {
      final projection = _runtime(_preflopState()).startHand();
      for (final peers in <List<String>>[
        <String>['peer_${String.fromCharCode(0x85)}', 'peer_remote'],
        <String>['peer_local', 'x' * 257],
      ]) {
        final sender = _RecordingTransportSender();
        final publisher = AppHoldemProjectionTransportPublisher(
          sender: sender,
          localPeerId: peers[0],
          remotePeerId: peers[1],
        );

        final result = await publisher.publish(projection);

        expect(result.isComplete, isFalse);
        expect(result.reasonCode, 'ERR_HOLDEM_PROJECTION_PEER_ID_INVALID');
        expect(sender.frames, isEmpty);
      }
    },
  );

  test('reports partial publication without replaying variant rules', () async {
    final runtime = _runtime(_showdownState());
    expect(runtime.startHand().isApplied, isTrue);
    final projection = runtime.revealShowdown(input: _showdownInput);
    final sender = _RecordingTransportSender(failAtSend: 2);
    final publisher = AppHoldemProjectionTransportPublisher(
      sender: sender,
      localPeerId: 'peer_local',
      remotePeerId: 'peer_remote',
    );

    final result = await publisher.publish(projection);

    expect(result.isComplete, isFalse);
    expect(result.isPartial, isTrue);
    expect(result.sentEventCount, 1);
    expect(result.totalEventCount, 2);
    expect(sender.frames, hasLength(2));
    expect(runtime.handState.phase, HoldemHandPhase.showdownReveal);
  });

  test('resumes partial publication from the sent event offset', () async {
    final runtime = _runtime(_showdownState());
    expect(runtime.startHand().isApplied, isTrue);
    final projection = runtime.revealShowdown(input: _showdownInput);
    final firstSender = _RecordingTransportSender(failAtSend: 2);
    final publisher = AppHoldemProjectionTransportPublisher(
      sender: firstSender,
      localPeerId: 'peer_local',
      remotePeerId: 'peer_remote',
    );

    final partial = await publisher.publish(projection);
    final retrySender = _RecordingTransportSender();
    final retryPublisher = AppHoldemProjectionTransportPublisher(
      sender: retrySender,
      localPeerId: 'peer_local',
      remotePeerId: 'peer_remote',
    );
    final resumed = await retryPublisher.publish(
      projection,
      startEventIndex: partial.sentEventCount,
    );

    expect(resumed.isComplete, isTrue);
    expect(resumed.sentEventCount, projection.events.length);
    expect(retrySender.frames, hasLength(1));
    expect(
      const EventEnvelopeCodec()
          .decode(retrySender.frames.single.payload)
          .eventId,
      projection.events[1].eventId,
    );
  });

  test('reconstructs adapter events through the inbound app boundary', () {
    const adapter = HoldemCoreProjectionAdapter();
    final initial = _preflopState();
    final started = adapter.startHand(
      coreState: _openCoreState(),
      handState: initial,
      cursor: _cursor(),
    );
    final acted = adapter.applyAction(
      coreState: started.coreState,
      handState: started.handState,
      cursor: started.cursor,
      action: const HoldemTableAction(
        actorSeat: 1,
        type: HoldemTableActionType.call,
      ),
      dealtBoardCards: const <String>['Ah', 'Kd', '2c'],
      openNextBettingRound: true,
    );
    final runtime = _runtime(initial);

    expect(runtime.applyRemoteEvent(started.events.single).isApplied, isTrue);
    final applied = runtime.applyRemoteEvent(acted.events.single);

    expect(applied.isApplied, isTrue);
    expect(runtime.handState.phase, HoldemHandPhase.bettingFlop);
    expect(runtime.handState.boardCards, <String>['Ah', 'Kd', '2c']);
    expect(runtime.coreState.eventSequence, 3);
    expect(runtime.cursor.nextEventSeq, 4);
  });

  test(
    'keeps variant and cursor state unchanged when core rejects inbound event',
    () {
      const adapter = HoldemCoreProjectionAdapter();
      final initial = _preflopState();
      final started = adapter.startHand(
        coreState: _openCoreState(),
        handState: initial,
        cursor: _cursor(),
      );
      final action = adapter.applyAction(
        coreState: started.coreState,
        handState: started.handState,
        cursor: started.cursor,
        action: const HoldemTableAction(
          actorSeat: 1,
          type: HoldemTableActionType.call,
        ),
        dealtBoardCards: const <String>['Ah', 'Kd', '2c'],
        openNextBettingRound: true,
      );
      final event = _cursor()
          .issue(
            eventType: action.events.single.eventType,
            handId: initial.handId,
            payload: action.events.single.payload,
          )
          .event;
      final runtime = _runtime(initial);
      final handBefore = runtime.handState;
      final cursorBefore = runtime.cursor;

      final result = runtime.applyRemoteEvent(event);

      expect(result.isRejected, isTrue);
      expect(result.reasonCode, 'ERR_HAND_EVENT_WITHOUT_ACTIVE_HAND');
      expect(runtime.handState, same(handBefore));
      expect(runtime.cursor, same(cursorBefore));
      expect(runtime.coreState.eventSequence, 1);
    },
  );

  test('rejects invalid actions without advancing app or variant state', () {
    final runtime = _runtime(_preflopState());
    expect(runtime.startHand().isApplied, isTrue);
    final handBefore = runtime.handState;
    final cursorBefore = runtime.cursor;

    final rejected = runtime.applyAction(
      action: const HoldemTableAction(
        actorSeat: 2,
        type: HoldemTableActionType.check,
      ),
    );

    expect(rejected.isRejected, isTrue);
    expect(rejected.reasonCode, 'ERR_OUT_OF_TURN');
    expect(rejected.events, isEmpty);
    expect(runtime.handState, same(handBefore));
    expect(runtime.cursor, same(cursorBefore));
    expect(runtime.coreState.eventSequence, 2);
    expect(runtime.sessionRuntime.acceptedEventCount, 1);
  });

  test('commits showdown and settlement as one app-owned lifecycle', () {
    final runtime = _runtime(_showdownState());
    expect(runtime.startHand().isApplied, isTrue);

    final revealed = runtime.revealShowdown(input: _showdownInput);
    expect(revealed.isApplied, isTrue);
    expect(revealed.events.map((event) => event.eventType), <String>[
      'ShowdownStarted',
      'ShowdownRevealed',
    ]);

    const coordinator = HoldemShowdownCoordinator();
    final revealResult = revealed.projection.showdownResult!;
    final prepared = coordinator.prepareSettlement(
      state: revealed.projection.handState,
      evaluation: revealResult.evaluation,
    );
    final settlement = coordinator.projectSettlement(
      state: prepared.state,
      evaluation: prepared.evaluation,
      commitments: const <PotCommitment>[
        PotCommitment(
          seatId: 'seat-1',
          committed: 100,
          isEligibleForShowdown: true,
        ),
        PotCommitment(
          seatId: 'seat-2',
          committed: 100,
          isEligibleForShowdown: true,
        ),
      ],
      seatForId: _seatFromSeatId,
    );
    final completion = coordinator.completeHand(
      state: prepared.state,
      settlement: settlement,
    );

    final settled = runtime.projectSettlement(
      settlement: settlement,
      completion: completion,
      projectionId: 'projection_001',
      settlementId: 'settlement_001',
    );

    expect(settled.isApplied, isTrue);
    expect(settled.events.map((event) => event.eventType), <String>[
      'SettlementProjected',
      'HandSettled',
    ]);
    expect(runtime.handState.phase, HoldemHandPhase.handComplete);
    expect(runtime.coreState.activeHandId, isNull);
    expect(runtime.coreState.eventSequence, 6);
    expect(runtime.sessionRuntime.acceptedEventCount, 5);
  });
}

AppHoldemTableSessionRuntime _runtime(HoldemHandState handState) {
  const scope = RecoveryPersistenceScope(
    tableId: 'tbl_001',
    sessionId: 'sess_001',
    protocolVersion: '1.0.0',
  );
  final sessionRuntime = AppTableSessionRuntime(
    initialState: _openCoreState(),
    closeEventAdapter: AppRecoverySessionCloseEventAdapter(
      sessionCloseCoordinator: AppRecoverySessionCloseCoordinator(
        retentionCoordinator: AppRecoveryRetentionCoordinator(
          store: _FakeRecoveryStore(),
        ),
        scope: scope,
        policy: _policy,
      ),
    ),
  );
  return AppHoldemTableSessionRuntime(
    sessionRuntime: sessionRuntime,
    initialHandState: handState,
    initialCursor: _cursor(),
  );
}

TableState _openCoreState() {
  return const CoreReducer().apply(
    TableState.initial(
      tableId: 'tbl_001',
      sessionId: 'sess_001',
      protocolVersion: '1.0.0',
    ),
    const EventEnvelope(
      eventId: 'evt_open',
      eventType: 'OpenTableSessionOpened',
      eventVersion: '1.0',
      protocolVersion: '1.0.0',
      eventSeq: 1,
      tableId: 'tbl_001',
      sessionId: 'sess_001',
      handId: null,
      emittedAt: '2026-08-10T00:00:00Z',
      actorRef: 'system',
      payload: <String, Object?>{'mode_type': 'cash'},
      prevEventHash: genesisEventHash,
      eventHash: 'hash_open',
    ),
  );
}

HoldemEventCursor _cursor() {
  return HoldemEventCursor(
    protocolVersion: '1.0.0',
    tableId: 'tbl_001',
    sessionId: 'sess_001',
    nextEventSeq: 2,
    previousEventHash: 'hash_open',
    actorRef: 'system',
    eventIdFactory: (eventType, eventSeq) => 'evt_${eventType}_$eventSeq',
    emittedAtFactory: () => '2026-08-10T00:00:01Z',
  );
}

HoldemHandState _preflopState() {
  return const HoldemHandState(
    handId: 'hand_001',
    phase: HoldemHandPhase.bettingPreflop,
    bettingRound: HoldemBettingRound.preflop,
    currentActorSeat: 1,
    buttonSeat: 1,
    smallBlindSeat: 2,
    bigBlindSeat: 3,
    currentBetToCall: 100,
    minimumRaiseAmount: 100,
    pot: 200,
    seats: <HoldemSeatState>[
      HoldemSeatState(
        seat: 1,
        stack: 1000,
        inHand: true,
        folded: false,
        allIn: false,
      ),
      HoldemSeatState(
        seat: 2,
        stack: 900,
        inHand: true,
        folded: false,
        allIn: false,
        committedThisRound: 100,
        committedThisHand: 100,
      ),
      HoldemSeatState(
        seat: 3,
        stack: 900,
        inHand: true,
        folded: false,
        allIn: false,
        committedThisRound: 100,
        committedThisHand: 100,
      ),
    ],
  );
}

HoldemHandState _showdownState() {
  return const HoldemHandState(
    handId: 'hand_001',
    phase: HoldemHandPhase.showdownPrep,
    bettingRound: HoldemBettingRound.river,
    currentActorSeat: 1,
    buttonSeat: 1,
    smallBlindSeat: 2,
    bigBlindSeat: 3,
    currentBetToCall: 0,
    minimumRaiseAmount: 100,
    pot: 200,
    boardCards: <String>['Ah', 'Kd', 'Qs', 'Jc', '2h'],
    seats: <HoldemSeatState>[
      HoldemSeatState(
        seat: 1,
        stack: 900,
        inHand: true,
        folded: false,
        allIn: false,
        committedThisHand: 100,
      ),
      HoldemSeatState(
        seat: 2,
        stack: 900,
        inHand: true,
        folded: false,
        allIn: false,
        committedThisHand: 100,
      ),
    ],
  );
}

const _showdownInput = ShowdownEvaluationInput(
  boardCards: <String>['Ah', 'Kd', 'Qs', 'Jc', '2h'],
  seats: <ShowdownSeatInput>[
    ShowdownSeatInput(
      seat: 1,
      holeCards: <String>['8h', '9d'],
      isFolded: false,
    ),
    ShowdownSeatInput(
      seat: 2,
      holeCards: <String>['Ac', '3c'],
      isFolded: false,
    ),
  ],
);

int? _seatFromSeatId(String seatId) => int.tryParse(seatId.split('-').last);

final _policy = RetentionPolicy(
  mode: RetentionMode.timedSandbox,
  wipeSchedule: const WipeSchedule(
    mode: 'timed_sandbox',
    timedWipeSeconds: 0,
    durableExportAllowed: true,
    ephemeralExportOnly: false,
  ),
  manualWipeConfirmation: const ManualWipeConfirmation(
    requiresSecondConfirmation: true,
    confirmationPhrase: 'WIPE RECEIPT',
  ),
  allowSessionRestore: true,
  allowUserRestore: false,
  disappearingPolicy: const DisappearingPolicy(
    disappearingChatEnabled: false,
    disappearingSessionMode: false,
    messageRetentionPolicy: MessageRetentionPolicy.standard,
  ),
  metadataProfile: const MetadataMinimizationProfile(
    minimizeMetadata: true,
    exportMinimalIdentity: true,
    allowPseudonymousAliases: true,
    allowDeviceIdentifiers: false,
    allowIpAddressCapture: false,
  ),
);

class _FakeRecoveryStore implements RecoveryPersistenceStore {
  @override
  RecoveryPersistenceResult saveSnapshot({
    required RecoveryPersistenceScope scope,
    required SnapshotEnvelope snapshot,
  }) => RecoveryPersistenceResult.success();

  @override
  RecoveryPersistenceResult appendEvents({
    required RecoveryPersistenceScope scope,
    required List<EventEnvelope> events,
  }) => RecoveryPersistenceResult.success();

  @override
  RecoveryPersistenceResult wipe({required RecoveryPersistenceScope scope}) =>
      RecoveryPersistenceResult.success();

  @override
  PersistedRecoveryWindow loadWindow(RecoveryPersistenceScope scope) =>
      PersistedRecoveryWindow(events: <EventEnvelope>[]);
}

class _RecordingTransportSender implements TransportFrameSender {
  _RecordingTransportSender({this.failAtSend});

  final int? failAtSend;
  final frames = <TransportFrame>[];

  @override
  Future<TransportFrameSendResult> send(TransportFrame frame) async {
    frames.add(frame);
    if (failAtSend == frames.length) {
      return TransportFrameSendResult.rejected(
        reasonCode: 'ERR_TEST_TRANSPORT_SEND_FAILED',
      );
    }
    return const TransportFrameSendResult.sent();
  }
}
