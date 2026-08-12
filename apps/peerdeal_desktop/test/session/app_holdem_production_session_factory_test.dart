import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_desktop/recovery/app_recovery_retention_coordinator.dart';
import 'package:peerdeal_desktop/recovery/app_recovery_session_close_coordinator.dart';
import 'package:peerdeal_desktop/recovery/app_recovery_session_close_event_adapter.dart';
import 'package:peerdeal_desktop/session/app_holdem_production_session_factory.dart';
import 'package:peerdeal_privacy/peerdeal_privacy.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';
import 'package:test/test.dart';

void main() {
  test('composes canonical state into the production route boundary', () {
    final tableState = _initialTableState();
    final handState = _initialHandState();
    final cursor = _initialCursor();

    final composition = _create(
      initialTableState: tableState,
      initialHandState: handState,
      initialCursor: cursor,
    );

    expect(composition.sessionRuntime.state, same(tableState));
    expect(
      composition.holdemRuntime.sessionRuntime,
      same(composition.sessionRuntime),
    );
    expect(composition.holdemRuntime.handState, same(handState));
    expect(composition.holdemRuntime.cursor, same(cursor));
    expect(composition.route.runtime, same(composition.holdemRuntime));
    expect(composition.route.path, '/holdem-live');
    expect(composition.route.navigationLabel, 'Live Holdem');
    expect(composition.route.peerId, 'peer_remote');
    expect(composition.route.pollInterval, const Duration(seconds: 1));
  });

  test('propagates the recovery event limit into the session runtime', () {
    final composition = _create(maxRecoveryEvents: 1);
    final result = composition.sessionRuntime.applyEventBatch(<EventEnvelope>[
      _event(seq: 1),
      _event(seq: 2, prevHash: 'hash_1'),
    ]);

    expect(result.isRejected, isTrue);
    expect(result.reasonCode, 'ERR_APP_SESSION_EVENT_BATCH_TOO_LARGE');
    expect(composition.sessionRuntime.acceptedEventCount, 0);
  });

  test('rejects unsafe identity and runtime composition inputs', () {
    expect(() => _create(peerId: 'peer_local'), throwsArgumentError);
    for (final peerId in <String>[
      'peer_${String.fromCharCode(0x85)}',
      'x' * 257,
    ]) {
      expect(() => _create(peerId: peerId), throwsArgumentError);
      expect(() => _create(localPeerId: peerId), throwsArgumentError);
    }
    expect(() => _create(localSeat: 4), throwsArgumentError);
    expect(
      () => _create(pollInterval: const Duration(milliseconds: 50)),
      throwsArgumentError,
    );
    expect(() => _create(path: '/holdem-live/'), throwsArgumentError);
    expect(
      () => _create(initialCursor: _initialCursor(tableId: 'table_other')),
      throwsArgumentError,
    );
  });
}

AppHoldemProductionSessionComposition _create({
  TableState? initialTableState,
  HoldemHandState? initialHandState,
  HoldemEventCursor? initialCursor,
  String path = '/holdem-live',
  String navigationLabel = 'Live Holdem',
  String peerId = 'peer_remote',
  String localPeerId = 'peer_local',
  int localSeat = 1,
  Duration pollInterval = const Duration(seconds: 1),
  int maxRecoveryEvents = RecoveryEventWindowLimits.defaultMaxEvents,
}) {
  final tableState = initialTableState ?? _initialTableState();
  return const AppHoldemProductionSessionFactory().create(
    initialTableState: tableState,
    initialHandState: initialHandState ?? _initialHandState(),
    initialCursor: initialCursor ?? _initialCursor(),
    closeEventAdapter: _closeAdapter(tableState),
    path: path,
    navigationLabel: navigationLabel,
    peerId: peerId,
    localPeerId: localPeerId,
    localSeat: localSeat,
    pollInterval: pollInterval,
    maxRecoveryEvents: maxRecoveryEvents,
  );
}

EventEnvelope _event({required int seq, String prevHash = ''}) {
  return EventEnvelope(
    eventId: 'event_$seq',
    eventType: 'OpenTableSessionOpened',
    eventVersion: '1.0',
    protocolVersion: '1.0.0',
    eventSeq: seq,
    tableId: 'table_001',
    sessionId: 'session_001',
    handId: 'hand_001',
    emittedAt: '2026-08-11T00:00:00Z',
    actorRef: 'peer_remote',
    payload: const <String, Object?>{},
    prevEventHash: prevHash,
    eventHash: 'hash_$seq',
  );
}

TableState _initialTableState() {
  return TableState.initial(
    tableId: 'table_001',
    sessionId: 'session_001',
    protocolVersion: '1.0.0',
  );
}

HoldemEventCursor _initialCursor({String tableId = 'table_001'}) {
  return HoldemEventCursor(
    protocolVersion: '1.0.0',
    tableId: tableId,
    sessionId: 'session_001',
    nextEventSeq: 1,
    previousEventHash: genesisEventHash,
    actorRef: 'peer_local',
    eventIdFactory: (eventType, eventSeq) => 'evt_${eventType}_$eventSeq',
    emittedAtFactory: () => '2026-08-10T00:00:00Z',
  );
}

HoldemHandState _initialHandState() {
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

AppRecoverySessionCloseEventAdapter _closeAdapter(TableState state) {
  return AppRecoverySessionCloseEventAdapter(
    sessionCloseCoordinator: AppRecoverySessionCloseCoordinator(
      retentionCoordinator: AppRecoveryRetentionCoordinator(
        store: InMemoryRecoveryPersistenceStore(),
      ),
      scope: RecoveryPersistenceScope(
        tableId: state.tableId,
        sessionId: state.sessionId,
        protocolVersion: state.protocolVersion,
      ),
      policy: _policy,
    ),
  );
}

const _policy = RetentionPolicy(
  mode: RetentionMode.timedSandbox,
  wipeSchedule: WipeSchedule(
    mode: 'timed_sandbox',
    timedWipeSeconds: 0,
    durableExportAllowed: true,
    ephemeralExportOnly: false,
  ),
  manualWipeConfirmation: ManualWipeConfirmation(
    requiresSecondConfirmation: true,
    confirmationPhrase: 'WIPE RECEIPT',
  ),
  allowSessionRestore: true,
  allowUserRestore: false,
  disappearingPolicy: DisappearingPolicy(
    disappearingChatEnabled: false,
    disappearingSessionMode: false,
    messageRetentionPolicy: MessageRetentionPolicy.standard,
  ),
  metadataProfile: MetadataMinimizationProfile(
    minimizeMetadata: true,
    exportMinimalIdentity: true,
    allowPseudonymousAliases: true,
    allowDeviceIdentifiers: false,
    allowIpAddressCapture: false,
  ),
);
