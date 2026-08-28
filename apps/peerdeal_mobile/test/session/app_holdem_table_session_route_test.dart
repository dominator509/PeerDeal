import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_mobile/main.dart';
import 'package:peerdeal_mobile/native_readiness/app_native_readiness_loader.dart';
import 'package:peerdeal_mobile/recovery/app_recovery_retention_coordinator.dart';
import 'package:peerdeal_mobile/recovery/app_recovery_session_close_coordinator.dart';
import 'package:peerdeal_mobile/recovery/app_recovery_session_close_event_adapter.dart';
import 'package:peerdeal_mobile/session/app_holdem_production_route_registration.dart';
import 'package:peerdeal_mobile/session/app_holdem_production_session_persistence_writer.dart';
import 'package:peerdeal_mobile/session/app_holdem_production_session_snapshot_coordinator.dart';
import 'package:peerdeal_mobile/session/app_holdem_production_table_surface.dart';
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
  testWidgets('typed registration auto-registers route and navigation', (
    tester,
  ) async {
    final registration = _registration();
    var navigation = <PeerDealAppNavigationEntry>[];

    await tester.pumpWidget(
      PeerDealMobileApp(
        runtime: PeerDealMobileRuntime(
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
      PeerDealMobileApp(
        runtime: PeerDealMobileRuntime(
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
      PeerDealMobileApp(
        runtime: PeerDealMobileRuntime(
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
          sessionAuthenticator: _authenticator(),
          localSeat: 1,
        );

    await tester.pumpWidget(
      PeerDealMobileApp(
        runtime: PeerDealMobileRuntime(
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
          sessionAuthenticator: _authenticator(),
          localSeat: 1,
        );

    await tester.pumpWidget(
      PeerDealMobileApp(
        runtime: PeerDealMobileRuntime(
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
        payloadBytes: _authenticatedPayload(
          projection.events.single,
          authenticator: _authenticator(),
        ),
      ),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: AppHoldemTableSessionRoute(
          runtime: runtime,
          peerId: 'peer_remote',
          localPeerId: 'peer_local',
          sessionAuthenticator: _authenticator(),
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
        payloadBytes: _authenticatedPayload(
          projection.events.single,
          authenticator: _authenticator(),
        ),
      ),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: AppHoldemTableSessionRoute(
          runtime: runtime,
          peerId: 'peer_remote',
          localPeerId: 'peer_local',
          sessionAuthenticator: _authenticator(),
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
          .decode(_decodeAuthenticatedPayload(bridge.lastSentFrame!))
          .payload['actor_seat'],
      1,
    );
    expect(find.text('Action synchronized'), findsOneWidget);
  });

  testWidgets('blocks local actions while persistence is pending', (
    tester,
  ) async {
    final runtime = _runtime();
    final coordinator = _snapshotCoordinator(
      _RecordingRecoveryStore(failWrites: true),
    );
    final persistenceResult = await coordinator.persist(
      tableState: runtime.coreState,
      handState: runtime.handState,
      eventCursor: runtime.cursor,
    );
    expect(persistenceResult.isSuccess, isFalse);
    expect(coordinator.hasPending, isTrue);

    await tester.pumpWidget(
      _productionSurfaceRouteWithCoordinator(
        runtime: runtime,
        bridge: _BlockingNativeTransportBridge(blockSends: false),
        snapshotCoordinator: coordinator,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Call'), findsNothing);
    expect(
      find.text('Unavailable until pending synchronization completes'),
      findsOneWidget,
    );
  });

  testWidgets('drops a stale projection completion after runtime replacement', (
    tester,
  ) async {
    final oldRuntime = _runtime();
    final projection = const HoldemCoreProjectionAdapter().startHand(
      coreState: oldRuntime.coreState,
      handState: oldRuntime.handState,
      cursor: oldRuntime.cursor,
    );
    final oldBridge = _BlockingNativeTransportBridge(
      receiveFrame: NativeTransportFrame(
        sessionId: 'sess_001',
        senderPeerId: 'peer_remote',
        recipientPeerId: 'peer_local',
        sequence: projection.events.single.eventSeq,
        payloadBytes: _authenticatedPayload(
          projection.events.single,
          authenticator: _authenticator(),
        ),
      ),
    );
    final newBridge = _BlockingNativeTransportBridge();

    await tester.pumpWidget(
      _productionSurfaceRoute(runtime: oldRuntime, bridge: oldBridge),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Call'));
    await tester.pump();
    await tester.pump();
    expect(oldBridge.sendCalls, 1);
    expect(find.text('Synchronizing'), findsNWidgets(2));

    await tester.pumpWidget(
      _productionSurfaceRoute(runtime: _runtime(), bridge: newBridge),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your turn'), findsNWidgets(2));
    oldBridge.completeSend();
    await tester.pumpAndSettle();

    expect(find.text('Sync pending'), findsNothing);
    expect(find.text('Action synchronized'), findsNothing);
  });

  testWidgets(
    'drops a stale projection completion after transport replacement',
    (tester) async {
      final runtime = _runtime();
      final projection = const HoldemCoreProjectionAdapter().startHand(
        coreState: runtime.coreState,
        handState: runtime.handState,
        cursor: runtime.cursor,
      );
      final oldBridge = _BlockingNativeTransportBridge(
        receiveFrame: NativeTransportFrame(
          sessionId: 'sess_001',
          senderPeerId: 'peer_remote',
          recipientPeerId: 'peer_local',
          sequence: projection.events.single.eventSeq,
          payloadBytes: _authenticatedPayload(
            projection.events.single,
            authenticator: _authenticator(),
          ),
        ),
      );
      final newBridge = _BlockingNativeTransportBridge(blockSends: false);

      await tester.pumpWidget(
        _productionSurfaceRoute(runtime: runtime, bridge: oldBridge),
      );
      await tester.pumpAndSettle();

      expect(find.text('Call'), findsOneWidget);
      await tester.tap(find.text('Call'));
      await tester.pump();
      await tester.pump();
      expect(oldBridge.sendCalls, 1);

      await tester.pumpWidget(
        _productionSurfaceRoute(runtime: runtime, bridge: newBridge),
      );
      await tester.pumpAndSettle();

      oldBridge.completeSend();
      await tester.pumpAndSettle();

      expect(newBridge.sendCalls, 0);
      expect(find.text('Action synchronized'), findsNothing);
      expect(find.text('Sync pending'), findsNothing);
    },
  );

  testWidgets(
    'does not checkpoint a stale projection after runtime replacement',
    (tester) async {
      final oldStore = _RecordingRecoveryStore();
      final newStore = _RecordingRecoveryStore();

      await tester.pumpWidget(
        _productionSurfaceRouteWithCoordinator(
          runtime: _runtime(),
          bridge: _BlockingNativeTransportBridge(blockSends: false),
          snapshotCoordinator: _snapshotCoordinator(oldStore),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Call'));
      await tester.pumpWidget(
        _productionSurfaceRouteWithCoordinator(
          runtime: _runtime(),
          bridge: _BlockingNativeTransportBridge(blockSends: false),
          snapshotCoordinator: _snapshotCoordinator(newStore),
        ),
      );
      await tester.pumpAndSettle();

      expect(oldStore.appendEventsCalls, 0);
      expect(oldStore.saveSnapshotCalls, 0);
      expect(newStore.appendEventsCalls, 0);
      expect(newStore.saveSnapshotCalls, 0);
    },
  );

  testWidgets('drops a stale inbound checkpoint after runtime replacement', (
    tester,
  ) async {
    final oldRuntime = _runtime();
    final projection = const HoldemCoreProjectionAdapter().startHand(
      coreState: oldRuntime.coreState,
      handState: oldRuntime.handState,
      cursor: oldRuntime.cursor,
    );
    final oldBridge = _BlockingReceiveNativeTransportBridge(
      receiveFrame: NativeTransportFrame(
        sessionId: 'sess_001',
        senderPeerId: 'peer_remote',
        recipientPeerId: 'peer_local',
        sequence: projection.events.single.eventSeq,
        payloadBytes: _authenticatedPayload(
          projection.events.single,
          authenticator: _authenticator(),
        ),
      ),
    );
    final oldStore = _RecordingRecoveryStore();
    final newStore = _RecordingRecoveryStore();
    final oldCoordinator = _snapshotCoordinator(oldStore);
    final newCoordinator = _snapshotCoordinator(newStore);

    await tester.pumpWidget(
      _productionSurfaceRouteWithCoordinator(
        runtime: oldRuntime,
        bridge: oldBridge,
        snapshotCoordinator: oldCoordinator,
      ),
    );
    await tester.pumpAndSettle();
    expect(oldBridge.receiveCalls, 1);

    await tester.pumpWidget(
      _productionSurfaceRouteWithCoordinator(
        runtime: _runtime(),
        bridge: _BlockingReceiveNativeTransportBridge(),
        snapshotCoordinator: newCoordinator,
      ),
    );
    await tester.pumpAndSettle();

    oldBridge.completeReceive();
    await tester.pumpAndSettle();

    expect(oldRuntime.coreState.eventSequence, 1);
    expect(oldStore.appendEventsCalls, 0);
    expect(oldStore.saveSnapshotCalls, 0);
    expect(newStore.appendEventsCalls, 0);
    expect(newStore.saveSnapshotCalls, 0);
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
          localPeerId: 'peer_local',
          sessionAuthenticator: _authenticator(),
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

  testWidgets('renders a shared fail-closed surface when the builder throws', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: AppHoldemTableSessionRoute(
          runtime: _runtime(),
          peerId: 'peer_remote',
          localPeerId: 'peer_local',
          sessionAuthenticator: _authenticator(),
          surfaceBuilder: (context, routeContext) {
            throw StateError('do not expose this failure');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Hold'em table"), findsOneWidget);
    expect(find.text('Production table unavailable'), findsOneWidget);
    expect(find.text('Unavailable'), findsNWidgets(2));
    expect(find.text('do not expose this failure'), findsNothing);
  });
}

Widget _productionSurfaceRoute({
  required AppHoldemTableSessionRuntime runtime,
  required NativeTransportBridge bridge,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: AppHoldemTableSessionRoute(
      runtime: runtime,
      peerId: 'peer_remote',
      localPeerId: 'peer_local',
      sessionAuthenticator: _authenticator(),
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
  );
}

Widget _productionSurfaceRouteWithCoordinator({
  required AppHoldemTableSessionRuntime runtime,
  required NativeTransportBridge bridge,
  required AppHoldemProductionSessionSnapshotCoordinator snapshotCoordinator,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: AppHoldemTableSessionRoute(
      runtime: runtime,
      peerId: 'peer_remote',
      localPeerId: 'peer_local',
      sessionAuthenticator: _authenticator(),
      nativeSessionFactory: NativeTransportSessionFactory(bridge: bridge),
      snapshotCoordinator: snapshotCoordinator,
      timerFactory: (interval, callback) =>
          Timer(const Duration(hours: 1), () {}),
      surfaceBuilder: (context, routeContext) =>
          AppHoldemProductionTableSurface(
            routeContext: routeContext,
            localPeerId: 'peer_local',
            localSeat: 1,
          ),
    ),
  );
}

AppHoldemProductionSessionSnapshotCoordinator _snapshotCoordinator(
  RecoveryPersistenceStore store,
) {
  return AppHoldemProductionSessionSnapshotCoordinator(
    persistenceWriter: AppHoldemProductionSessionPersistenceWriter(
      store: store,
    ),
  );
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
    localPeerId: 'peer_local',
    sessionAuthenticator: _authenticator(),
    nativeSessionFactory: NativeTransportSessionFactory(
      bridge: _FakeNativeTransportBridge(
        receiveFrame: NativeTransportFrame(
          sessionId: 'sess_001',
          senderPeerId: 'peer_remote',
          recipientPeerId: 'peer_local',
          sequence: projection.events.single.eventSeq,
          payloadBytes: _authenticatedPayload(
            projection.events.single,
            authenticator: _authenticator(),
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
      receiveFrame: NativeTransportFrame(
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

List<int> _authenticatedPayload(
  EventEnvelope event, {
  required SessionMessageAuthenticator authenticator,
}) {
  return SessionAuthenticatedPayloadCodec.encode(
    input: SessionAuthenticationInput(
      sessionId: event.sessionId,
      senderPeerId: 'peer_remote',
      recipientPeerId: 'peer_local',
      sequence: event.eventSeq,
      payload: const EventEnvelopeCodec().encode(event),
    ),
    authenticator: authenticator,
  );
}

List<int> _decodeAuthenticatedPayload(NativeTransportFrame frame) {
  return SessionAuthenticatedPayloadCodec.decode(
    encoded: frame.payloadBytes,
    sessionId: frame.sessionId,
    senderPeerId: frame.senderPeerId,
    recipientPeerId: frame.recipientPeerId,
    sequence: frame.sequence,
    authenticator: _authenticator(),
  );
}

HmacSha256SessionMessageAuthenticator _authenticator() {
  return HmacSha256SessionMessageAuthenticator(
    key: List<int>.generate(32, (index) => index),
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
  return HoldemHandState(
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
    EventEnvelope(
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
      eventHash:
          '3182affc679d55993257597f317df8b19c7582156e5a90f1d33d728dde51e2e5',
    ),
  );
}

HoldemEventCursor _cursor() {
  return HoldemEventCursor(
    protocolVersion: '1.0.0',
    tableId: 'tbl_001',
    sessionId: 'sess_001',
    nextEventSeq: 2,
    previousEventHash:
        '3182affc679d55993257597f317df8b19c7582156e5a90f1d33d728dde51e2e5',
    actorRef: 'system',
    eventIdFactory: (eventType, eventSeq) => 'evt_${eventType}_$eventSeq',
    emittedAtFactory: () => '2026-08-10T00:00:01Z',
  );
}

HoldemHandState _preflopState() {
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
      return NativeTransportReceiveSnapshot(
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

class _BlockingNativeTransportBridge implements NativeTransportBridge {
  _BlockingNativeTransportBridge({this.receiveFrame, this.blockSends = true});

  final NativeTransportFrame? receiveFrame;
  final bool blockSends;
  final Completer<NativeTransportSendResult> _sendCompletion = Completer();
  int sendCalls = 0;
  bool _served = false;

  void completeSend() {
    if (!_sendCompletion.isCompleted) {
      _sendCompletion.complete(
        const NativeTransportSendResult(isSuccess: true),
      );
    }
  }

  @override
  Future<NativeTransportCapability> getCapability() async {
    return const NativeTransportCapability(
      available: true,
      sendSupported: true,
      receiveSupported: true,
      maxPayloadBytes: 4096,
      notes: 'blocking test transport',
    );
  }

  @override
  Future<NativeTransportReceiveSnapshot> receiveFrames({
    required String sessionId,
    required String peerId,
  }) async {
    final frame = receiveFrame;
    if (frame != null && !_served) {
      _served = true;
      return NativeTransportReceiveSnapshot(
        available: true,
        frames: <NativeTransportFrame>[frame],
      );
    }
    return NativeTransportReceiveSnapshot(
      available: true,
      frames: <NativeTransportFrame>[],
    );
  }

  @override
  Future<NativeTransportSendResult> sendFrame(NativeTransportFrame frame) {
    sendCalls++;
    if (!blockSends) {
      return Future<NativeTransportSendResult>.value(
        const NativeTransportSendResult(isSuccess: true),
      );
    }
    return _sendCompletion.future;
  }
}

class _BlockingReceiveNativeTransportBridge implements NativeTransportBridge {
  _BlockingReceiveNativeTransportBridge({this.receiveFrame});

  final NativeTransportFrame? receiveFrame;
  final Completer<NativeTransportReceiveSnapshot> _receiveCompletion =
      Completer();
  int receiveCalls = 0;

  void completeReceive() {
    if (!_receiveCompletion.isCompleted) {
      _receiveCompletion.complete(
        NativeTransportReceiveSnapshot(
          available: true,
          frames: receiveFrame == null
              ? const <NativeTransportFrame>[]
              : <NativeTransportFrame>[receiveFrame!],
        ),
      );
    }
  }

  @override
  Future<NativeTransportCapability> getCapability() async {
    return const NativeTransportCapability(
      available: true,
      sendSupported: true,
      receiveSupported: true,
      maxPayloadBytes: 4096,
      notes: 'blocking receive test transport',
    );
  }

  @override
  Future<NativeTransportReceiveSnapshot> receiveFrames({
    required String sessionId,
    required String peerId,
  }) {
    receiveCalls++;
    final frame = receiveFrame;
    if (frame == null) {
      return Future<NativeTransportReceiveSnapshot>.value(
        NativeTransportReceiveSnapshot(
          available: true,
          frames: <NativeTransportFrame>[],
        ),
      );
    }
    return _receiveCompletion.future;
  }

  @override
  Future<NativeTransportSendResult> sendFrame(
    NativeTransportFrame frame,
  ) async {
    return const NativeTransportSendResult(isSuccess: true);
  }
}

class _RecordingRecoveryStore implements RecoveryPersistenceStore {
  _RecordingRecoveryStore({this.failWrites = false});

  final bool failWrites;
  int appendEventsCalls = 0;
  int saveSnapshotCalls = 0;

  @override
  RecoveryPersistenceResult saveSnapshot({
    required RecoveryPersistenceScope scope,
    required SnapshotEnvelope snapshot,
  }) {
    saveSnapshotCalls++;
    if (failWrites) {
      return RecoveryPersistenceResult(
        isSuccess: false,
        warnings: <String>['test persistence failure'],
      );
    }
    return RecoveryPersistenceResult.success();
  }

  @override
  RecoveryPersistenceResult appendEvents({
    required RecoveryPersistenceScope scope,
    required List<EventEnvelope> events,
  }) {
    appendEventsCalls++;
    if (failWrites) {
      return RecoveryPersistenceResult(
        isSuccess: false,
        warnings: <String>['test persistence failure'],
      );
    }
    return RecoveryPersistenceResult.success();
  }

  @override
  RecoveryPersistenceResult wipe({required RecoveryPersistenceScope scope}) =>
      RecoveryPersistenceResult.success();

  @override
  PersistedRecoveryWindow loadWindow(RecoveryPersistenceScope scope) =>
      PersistedRecoveryWindow(events: <EventEnvelope>[]);
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
    return LocalNetworkDiscoverySnapshot(
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
    return SecureKeyStorageSnapshot(available: true, keys: []);
  }
}
