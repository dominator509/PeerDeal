import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_desktop/main.dart';
import 'package:peerdeal_desktop/native_readiness/app_native_readiness_loader.dart';
import 'package:peerdeal_desktop/recovery/app_recovery_retention_coordinator.dart';
import 'package:peerdeal_desktop/recovery/app_recovery_session_close_coordinator.dart';
import 'package:peerdeal_desktop/recovery/app_recovery_session_close_event_adapter.dart';
import 'package:peerdeal_desktop/session/app_holdem_production_route_registration.dart';
import 'package:peerdeal_desktop/session/app_holdem_production_table_surface.dart';
import 'package:peerdeal_desktop/session/app_holdem_table_session_route.dart';
import 'package:peerdeal_desktop/session/app_holdem_table_session_runtime.dart';
import 'package:peerdeal_desktop/session/app_table_session_runtime.dart';
import 'package:peerdeal_desktop/transport/native_transport_session_factory.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_privacy/peerdeal_privacy.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';

void main() {
  testWidgets('typed registration auto-registers route and navigation', (
    tester,
  ) async {
    final registration = _registration();
    var navigation = <PeerDealAppNavigationEntry>[];

    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          holdemProductionRoute: registration,
          nativeReadinessLoader: _readyReadinessLoader(),
          homeSurfaceBuilder: (_, entries) {
            navigation = entries;
            return const Text('registered home');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('registered home'), findsOneWidget);
    expect(
      navigation.any(
        (entry) => entry.label == 'Live Holdem' && entry.path == '/holdem-live',
      ),
      isTrue,
    );
  });

  testWidgets('typed registration mounts through native readiness gating', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          holdemProductionRoute: _registration(),
          nativeReadinessLoader: _readyReadinessLoader(),
          initialRoute: '/holdem-live',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('registered holdem route'), findsOneWidget);
    expect(find.text('Route unavailable'), findsNothing);
  });

  testWidgets('typed registration fails closed without native readiness', (
    tester,
  ) async {
    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          holdemProductionRoute: _registration(),
          initialRoute: '/holdem-live',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Route unavailable'), findsOneWidget);
    expect(find.text('registered holdem route'), findsNothing);
  });

  testWidgets('default registration mounts the production table surface', (
    tester,
  ) async {
    final registration =
        AppHoldemProductionRouteRegistration.withDefaultSurface(
          path: '/holdem-live',
          navigationLabel: 'Live Holdem',
          runtime: _runtime(),
          peerId: 'peer_remote',
          localPeerId: 'peer_local',
          localSeat: 1,
        );

    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          holdemProductionRoute: registration,
          nativeReadinessLoader: _readyReadinessLoader(),
          initialRoute: '/holdem-live',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Hold'em table"), findsOneWidget);
    expect(find.text('Peer session unavailable'), findsOneWidget);
    expect(find.text('Betting preflop'), findsOneWidget);
    expect(find.text('bettingPreflop'), findsNothing);
    expect(find.text('Fold'), findsNothing);
  });

  testWidgets('production table surface labels an idle actor safely', (
    tester,
  ) async {
    final registration =
        AppHoldemProductionRouteRegistration.withDefaultSurface(
          path: '/holdem-live',
          navigationLabel: 'Live Holdem',
          runtime: _runtime(initialHandState: _idleState()),
          peerId: 'peer_remote',
          localPeerId: 'peer_local',
          localSeat: 1,
        );

    await tester.pumpWidget(
      PeerDealDesktopApp(
        runtime: PeerDealDesktopRuntime(
          holdemProductionRoute: registration,
          nativeReadinessLoader: _readyReadinessLoader(),
          initialRoute: '/holdem-live',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Waiting to start'), findsOneWidget);
    expect(find.text('Seat 0'), findsNothing);
    expect(find.text('handIdle'), findsNothing);
  });

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

  testWidgets('production table surface publishes a local call', (
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
          surfaceBuilder: (context, routeContext) =>
              AppHoldemProductionTableSurface(
                routeContext: routeContext,
                localPeerId: 'peer_local',
                localSeat: 1,
              ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Call'), findsOneWidget);
    await tester.tap(find.text('Call'));
    await tester.pumpAndSettle();

    expect(bridge.sendCalls, 1);
    expect(bridge.lastSentFrame, isNotNull);
    expect(
      const EventEnvelopeCodec()
          .decode(bridge.lastSentFrame!.payloadBytes)
          .payload['actor_seat'],
      1,
    );
    expect(find.text('Action synchronized'), findsOneWidget);
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

AppHoldemProductionRouteRegistration _registration() {
  final runtime = _runtime();
  final projection = const HoldemCoreProjectionAdapter().startHand(
    coreState: runtime.coreState,
    handState: runtime.handState,
    cursor: runtime.cursor,
  );
  return AppHoldemProductionRouteRegistration(
    path: '/holdem-live',
    navigationLabel: 'Live Holdem',
    runtime: runtime,
    peerId: 'peer_remote',
    nativeSessionFactory: NativeTransportSessionFactory(
      bridge: _FakeNativeTransportBridge(
        receiveFrame: NativeTransportFrame(
          sessionId: 'sess_001',
          senderPeerId: 'peer_remote',
          recipientPeerId: 'peer_local',
          sequence: projection.events.single.eventSeq,
          payloadBytes: const EventEnvelopeCodec().encode(
            projection.events.single,
          ),
        ),
      ),
    ),
    timerFactory: (interval, callback) =>
        Timer(const Duration(hours: 1), () {}),
    surfaceBuilder: (context, routeContext) =>
        const Text('registered holdem route'),
  );
}

AppNativeReadinessLoader _readyReadinessLoader() {
  return AppNativeReadinessLoader(
    captureProtectionBridge: const _ReadyCaptureProtectionBridge(),
    localNetworkBridge: const _ReadyLocalNetworkBridge(),
    nativeTransportBridge: _FakeNativeTransportBridge(
      receiveFrame: const NativeTransportFrame(
        sessionId: 'sess_001',
        senderPeerId: 'peer_remote',
        recipientPeerId: 'peer_local',
        sequence: 1,
        payloadBytes: <int>[],
      ),
    ),
    secureKeyStorageBridge: const _ReadySecureKeyStorageBridge(),
  );
}

AppHoldemTableSessionRuntime _runtime({HoldemHandState? initialHandState}) {
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
    initialHandState: initialHandState ?? _preflopState(),
    initialCursor: _cursor(),
  );
}

HoldemHandState _idleState() {
  return const HoldemHandState(
    handId: 'hand_idle',
    phase: HoldemHandPhase.handIdle,
    bettingRound: HoldemBettingRound.none,
    currentActorSeat: 0,
    buttonSeat: 1,
    smallBlindSeat: 2,
    bigBlindSeat: 3,
    currentBetToCall: 0,
    minimumRaiseAmount: 100,
    seats: <HoldemSeatState>[
      HoldemSeatState(
        seat: 1,
        stack: 1000,
        inHand: false,
        folded: false,
        allIn: false,
      ),
      HoldemSeatState(
        seat: 2,
        stack: 900,
        inHand: false,
        folded: false,
        allIn: false,
      ),
      HoldemSeatState(
        seat: 3,
        stack: 900,
        inHand: false,
        folded: false,
        allIn: false,
      ),
    ],
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
  NativeTransportFrame? lastSentFrame;
  int receiveCalls = 0;
  int sendCalls = 0;
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
    lastSentFrame = frame;
    sendCalls++;
    return const NativeTransportSendResult(isSuccess: true);
  }
}

class _ReadyCaptureProtectionBridge implements CaptureProtectionBridge {
  const _ReadyCaptureProtectionBridge();

  @override
  Future<CaptureProtectionCapability> getCapability() async {
    return const CaptureProtectionCapability(
      blockingSupported: true,
      obscuringSupported: true,
      notes: 'ready',
    );
  }
}

class _ReadyLocalNetworkBridge implements LocalNetworkBridge {
  const _ReadyLocalNetworkBridge();

  @override
  Future<LocalNetworkCapability> getCapability() async {
    return const LocalNetworkCapability(
      discoverySupported: true,
      permissionPromptSupported: true,
      broadcastSupported: true,
      notes: 'ready',
    );
  }

  @override
  Future<LocalNetworkDiscoverySnapshot> discoverPeers() async {
    return const LocalNetworkDiscoverySnapshot(
      permissionGranted: true,
      foundEndpoints: <String>[],
      interfaceHints: <String>[],
    );
  }
}

class _ReadySecureKeyStorageBridge implements SecureKeyStorageBridge {
  const _ReadySecureKeyStorageBridge();

  @override
  Future<SecureKeyStorageSnapshot> loadKeyRing({
    required String namespace,
  }) async {
    return const SecureKeyStorageSnapshot(available: true, keys: []);
  }
}
