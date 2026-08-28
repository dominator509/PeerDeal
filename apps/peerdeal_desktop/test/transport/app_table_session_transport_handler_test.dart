import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_desktop/recovery/app_recovery_retention_coordinator.dart';
import 'package:peerdeal_desktop/recovery/app_recovery_session_close_coordinator.dart';
import 'package:peerdeal_desktop/recovery/app_recovery_session_close_event_adapter.dart';
import 'package:peerdeal_desktop/session/app_holdem_table_session_runtime.dart';
import 'package:peerdeal_desktop/session/app_table_session_runtime.dart';
import 'package:peerdeal_desktop/transport/app_table_session_transport_handler.dart';
import 'package:peerdeal_network/peerdeal_network.dart';
import 'package:peerdeal_privacy/peerdeal_privacy.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';
import 'package:test/test.dart';

void main() {
  test('rejects frames outside the configured peer identities', () async {
    final runtime = _runtime();
    final handler = AppTableSessionTransportHandler(
      runtime: runtime,
      expectedRemotePeerId: 'peer_a',
      expectedLocalPeerId: 'peer_b',
    );
    final receiver = ValidatingTransportFrameReceiver(handler: handler);

    final result = await receiver.receive(
      _frame(_event(), fromPeerId: 'peer_attacker'),
    );

    expect(result.accepted, isFalse);
    expect(runtime.state.eventSequence, 0);
  });

  test('decodes a canonical event frame into the session runtime', () async {
    final runtime = _runtime();
    final handler = AppTableSessionTransportHandler(runtime: runtime);
    final receiver = ValidatingTransportFrameReceiver(handler: handler);
    final event = _event();

    final result = await receiver.receive(_frame(event));

    expect(result.accepted, isTrue);
    expect(handler.lastResult!.isApplied, isTrue);
    expect(handler.lastResult!.acceptedEvent!.eventId, event.eventId);
    expect(handler.lastResult!.acceptedEvent!.eventSeq, event.eventSeq);
    expect(runtime.state.eventSequence, 1);
    expect(runtime.state.phase, TablePhase.openReady);
  });

  test('routes canonical Holdem frames through the variant runtime', () async {
    final runtime = _runtime();
    final holdemRuntime = AppHoldemTableSessionRuntime(
      sessionRuntime: runtime,
      initialHandState: _holdemState(),
      initialCursor: _holdemCursor(),
    );
    final started = const HoldemCoreProjectionAdapter().startHand(
      coreState: runtime.state,
      handState: holdemRuntime.handState,
      cursor: _holdemCursor(),
    );
    final handler = AppTableSessionTransportHandler(
      runtime: runtime,
      holdemRuntime: holdemRuntime,
    );
    final receiver = ValidatingTransportFrameReceiver(handler: handler);

    final result = await receiver.receive(_frame(started.events.single));

    expect(result.accepted, isTrue);
    expect(handler.lastHoldemResult?.isApplied, isTrue);
    expect(holdemRuntime.handState.handId, 'hand_001');
    expect(runtime.state.activeHandId, 'hand_001');
  });

  test(
    'rejects a frame outside the runtime session before projection',
    () async {
      final runtime = _runtime();
      final handler = AppTableSessionTransportHandler(runtime: runtime);
      final receiver = ValidatingTransportFrameReceiver(handler: handler);

      final result = await receiver.receive(
        _frame(_event(sessionId: 'session_2'), sessionId: 'session_2'),
      );

      expect(result.accepted, isFalse);
      expect(result.reasonCode, 'ERR_TRANSPORT_FRAME_RECEIVE_FAILED');
      expect(runtime.state.eventSequence, 0);
    },
  );

  test('rejects malformed event bytes before projection', () async {
    final runtime = _runtime();
    final handler = AppTableSessionTransportHandler(runtime: runtime);
    final receiver = ValidatingTransportFrameReceiver(handler: handler);

    final result = await receiver.receive(
      TransportFrame(
        sessionId: 'session_1',
        fromPeerId: 'peer_a',
        toPeerId: 'peer_b',
        sequence: 1,
        payload: <int>[123],
      ),
    );

    expect(result.accepted, isFalse);
    expect(runtime.state.eventSequence, 0);
  });

  test(
    'rejects core event failures without mutating projected state',
    () async {
      final runtime = _runtime();
      final handler = AppTableSessionTransportHandler(runtime: runtime);
      final receiver = ValidatingTransportFrameReceiver(handler: handler);

      expect((await receiver.receive(_frame(_event()))).accepted, isTrue);
      final result = await receiver.receive(
        _frame(
          _event(seq: 3, prevEventHash: _event().eventHash),
          sequence: 2,
        ),
      );

      expect(result.accepted, isFalse);
      expect(handler.lastResult!.reasonCode, 'ERR_EVENT_SEQUENCE_GAP');
      expect(runtime.state.eventSequence, 1);
    },
  );
}

AppTableSessionRuntime _runtime() {
  const scope = RecoveryPersistenceScope(
    tableId: 'table_1',
    sessionId: 'session_1',
    protocolVersion: '1.0.0',
  );
  return AppTableSessionRuntime(
    initialState: TableState.initial(
      tableId: scope.tableId,
      sessionId: scope.sessionId,
      protocolVersion: scope.protocolVersion,
    ),
    closeEventAdapter: AppRecoverySessionCloseEventAdapter(
      sessionCloseCoordinator: AppRecoverySessionCloseCoordinator(
        retentionCoordinator: AppRecoveryRetentionCoordinator(
          store: _FakeRecoveryStore(),
        ),
        scope: scope,
        policy: _policy(),
      ),
    ),
  );
}

TransportFrame _frame(
  EventEnvelope event, {
  String sessionId = 'session_1',
  String fromPeerId = 'peer_a',
  String toPeerId = 'peer_b',
  int sequence = 1,
}) {
  return TransportFrame(
    sessionId: sessionId,
    fromPeerId: fromPeerId,
    toPeerId: toPeerId,
    sequence: sequence,
    payload: const EventEnvelopeCodec().encode(event),
  );
}

EventEnvelope _event({
  int seq = 1,
  String sessionId = 'session_1',
  String prevEventHash = genesisEventHash,
}) {
  final event = EventEnvelope(
    eventId: 'evt_$seq',
    eventType: 'OpenTableSessionOpened',
    eventVersion: '1.0',
    protocolVersion: '1.0.0',
    eventSeq: seq,
    tableId: 'table_1',
    sessionId: sessionId,
    handId: null,
    emittedAt: '2026-08-09T12:00:00.000Z',
    actorRef: 'actor_1',
    payload: const <String, Object?>{'mode_type': 'cash'},
    prevEventHash: prevEventHash,
    eventHash: '',
  );
  return EventEnvelope.fromJson(<String, Object?>{
    ...event.toJson(),
    'event_hash': computeCanonicalEventHash(event),
  });
}

HoldemEventCursor _holdemCursor() {
  return HoldemEventCursor(
    protocolVersion: '1.0.0',
    tableId: 'table_1',
    sessionId: 'session_1',
    nextEventSeq: 1,
    previousEventHash: genesisEventHash,
    actorRef: 'actor_1',
    eventIdFactory: (eventType, eventSeq) => 'holdem_${eventType}_$eventSeq',
    emittedAtFactory: () => '2026-08-09T12:00:00.000Z',
  );
}

HoldemHandState _holdemState() {
  return HoldemHandState(
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

RetentionPolicy _policy() {
  return RetentionPolicy(
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
      allowPseudonymousAliases: false,
      allowDeviceIdentifiers: false,
      allowIpAddressCapture: false,
    ),
  );
}

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
