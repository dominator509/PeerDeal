import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_mobile/recovery/app_recovery_retention_coordinator.dart';
import 'package:peerdeal_mobile/recovery/app_recovery_session_close_coordinator.dart';
import 'package:peerdeal_mobile/recovery/app_recovery_session_close_event_adapter.dart';
import 'package:peerdeal_mobile/session/app_holdem_table_session_route.dart';
import 'package:peerdeal_mobile/session/app_holdem_table_session_runtime.dart';
import 'package:peerdeal_mobile/session/app_table_session_runtime.dart';
import 'package:peerdeal_mobile/transport/native_transport_session_factory.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_privacy/peerdeal_privacy.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';

void main() {
  testWidgets('provisions transport and refreshes after an inbound event', (
    tester,
  ) async {
    final runtime = _runtime();
    final projection = const HoldemCoreProjectionAdapter().startHand(
      coreState: runtime.coreState,
      handState: runtime.handState,
      cursor: runtime.cursor,
    );
    final bridge = _FakeNativeTransportBridge(
      receiveFrame: NativeTransportFrame(
        sessionId: 'sess_001',
        senderPeerId: 'peer_remote',
        recipientPeerId: 'peer_local',
        sequence: projection.events.single.eventSeq,
        payloadBytes: const EventEnvelopeCodec().encode(
          projection.events.single,
        ),
      ),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: AppHoldemTableSessionRoute(
          runtime: runtime,
          peerId: 'peer_remote',
          nativeSessionFactory: NativeTransportSessionFactory(bridge: bridge),
          timerFactory: (interval, callback) =>
              Timer(const Duration(hours: 1), () {}),
          surfaceBuilder: (context, routeContext) => Text(
            'seq:${routeContext.runtime.coreState.eventSequence}:'
            "${routeContext.transport.available ? 'available' : 'unavailable'}",
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('seq:2:available'), findsOneWidget);
    expect(runtime.coreState.eventSequence, 2);
    expect(bridge.receiveCalls, 1);
  });

  testWidgets('keeps the production surface mounted when transport is absent', (
    tester,
  ) async {
    final runtime = _runtime();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: AppHoldemTableSessionRoute(
          runtime: runtime,
          peerId: ' peer_remote',
          surfaceBuilder: (context, routeContext) => Text(
            routeContext.transport.available ? 'available' : 'unavailable',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('unavailable'), findsOneWidget);
    expect(runtime.coreState.eventSequence, 1);
  });
}

AppHoldemTableSessionRuntime _runtime() {
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
    initialHandState: _preflopState(),
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
  }) => const RecoveryPersistenceResult.success();

  @override
  RecoveryPersistenceResult appendEvents({
    required RecoveryPersistenceScope scope,
    required List<EventEnvelope> events,
  }) => const RecoveryPersistenceResult.success();

  @override
  RecoveryPersistenceResult wipe({required RecoveryPersistenceScope scope}) =>
      const RecoveryPersistenceResult.success();

  @override
  PersistedRecoveryWindow loadWindow(RecoveryPersistenceScope scope) =>
      const PersistedRecoveryWindow(events: <EventEnvelope>[]);
}

class _FakeNativeTransportBridge implements NativeTransportBridge {
  _FakeNativeTransportBridge({required this.receiveFrame});

  final NativeTransportFrame receiveFrame;
  int receiveCalls = 0;
  bool _served = false;

  @override
  Future<NativeTransportCapability> getCapability() async {
    return const NativeTransportCapability(
      available: true,
      sendSupported: true,
      receiveSupported: true,
      maxPayloadBytes: 4096,
      notes: 'test transport',
    );
  }

  @override
  Future<NativeTransportReceiveSnapshot> receiveFrames({
    required String sessionId,
    required String peerId,
  }) async {
    receiveCalls++;
    if (_served) {
      return const NativeTransportReceiveSnapshot(
        available: true,
        frames: <NativeTransportFrame>[],
      );
    }
    _served = true;
    return NativeTransportReceiveSnapshot(
      available: true,
      frames: <NativeTransportFrame>[receiveFrame],
    );
  }

  @override
  Future<NativeTransportSendResult> sendFrame(
    NativeTransportFrame frame,
  ) async {
    return const NativeTransportSendResult(isSuccess: true);
  }
}
