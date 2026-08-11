import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_mobile/join_flow/join_flow_models.dart';
import 'package:peerdeal_mobile/recovery/app_recovery_retention_coordinator.dart';
import 'package:peerdeal_mobile/recovery/app_recovery_session_close_coordinator.dart';
import 'package:peerdeal_mobile/recovery/app_recovery_session_close_event_adapter.dart';
import 'package:peerdeal_mobile/session/app_holdem_production_session_bootstrap.dart';
import 'package:peerdeal_mobile/session/app_persisted_holdem_production_session_source.dart';
import 'package:peerdeal_privacy/peerdeal_privacy.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';
import 'package:test/test.dart';

void main() {
  test(
    'loads typed persisted state into the production source boundary',
    () async {
      final store = InMemoryRecoveryPersistenceStore();
      final persisted = _typedSnapshot();
      _persist(store, persisted);

      HoldemStateSnapshot? captured;
      final source = _source(
        store,
        inputFactory: (invite, snapshot) {
          captured = snapshot;
          return AppHoldemProductionSessionInput(
            initialTableState: snapshot.tableState,
            initialHandState: snapshot.handState,
            initialCursor: snapshot.eventCursor,
            closeEventAdapter: _closeAdapter(snapshot.tableState),
            path: '/holdem-live',
            navigationLabel: 'Live Holdem',
            peerId: 'peer_remote',
            localPeerId: 'peer_local',
            localSeat: 1,
          );
        },
      );

      final input = await source.load(_invite());

      expect(captured?.toJson(), persisted.toJson());
      expect(input.initialTableState.toJson(), persisted.tableState.toJson());
      expect(input.initialHandState.toJson(), persisted.handState.toJson());
      expect(input.initialCursor.toJson(), persisted.eventCursor.toJson());
    },
  );

  test('fails closed when no typed snapshot is persisted', () {
    final source = _source(InMemoryRecoveryPersistenceStore());

    expect(() => source.load(_invite()), throwsA(isA<StateError>()));
  });

  test('fails closed on unsupported snapshot versions', () {
    final store = InMemoryRecoveryPersistenceStore();
    final persisted = _typedSnapshot();
    final scope = _scope();
    final result = store.saveSnapshot(
      scope: scope,
      snapshot: SnapshotEnvelope(
        snapshotId: 'snapshot_001',
        snapshotType: 'OtherSnapshot',
        snapshotVersion: '1.0',
        protocolVersion: scope.protocolVersion,
        tableId: scope.tableId,
        sessionId: scope.sessionId,
        snapshotBaseEventSeq: 0,
        snapshotHash: 'hash_001',
        payload: persisted.toJson(),
      ),
    );
    expect(result.isSuccess, isTrue);

    expect(() => _source(store).load(_invite()), throwsA(isA<StateError>()));
  });

  test('fails closed when recovery suffix requires product replay', () {
    final store = InMemoryRecoveryPersistenceStore();
    _persist(store, _typedSnapshot());
    final append = store.appendEvents(
      scope: _scope(),
      events: <EventEnvelope>[
        EventEnvelope(
          eventId: 'evt_suffix_1',
          eventType: 'RecoveryEventPersisted',
          eventVersion: '1.0',
          protocolVersion: '1.0.0',
          eventSeq: 1,
          tableId: 'table_001',
          sessionId: 'session_001',
          handId: null,
          emittedAt: '2026-08-10T00:00:00Z',
          actorRef: 'system',
          payload: const <String, Object?>{},
          prevEventHash: genesisEventHash,
          eventHash: 'hash_suffix_1',
        ),
      ],
    );
    expect(append.isSuccess, isTrue);

    expect(() => _source(store).load(_invite()), throwsA(isA<StateError>()));
  });
}

AppPersistedHoldemProductionSessionSource _source(
  RecoveryPersistenceStore store, {
  AppHoldemProductionSessionInputFactory? inputFactory,
}) {
  return AppPersistedHoldemProductionSessionSource(
    store: store,
    inputFactory:
        inputFactory ??
        (invite, snapshot) => AppHoldemProductionSessionInput(
          initialTableState: snapshot.tableState,
          initialHandState: snapshot.handState,
          initialCursor: snapshot.eventCursor,
          closeEventAdapter: _closeAdapter(snapshot.tableState),
          path: '/holdem-live',
          navigationLabel: 'Live Holdem',
          peerId: 'peer_remote',
          localPeerId: 'peer_local',
          localSeat: 1,
        ),
    eventIdFactory: (eventType, eventSeq) => 'evt_${eventType}_$eventSeq',
    emittedAtFactory: () => '2026-08-10T00:00:00Z',
    eventHashFactory: computeCanonicalHash,
  );
}

void _persist(RecoveryPersistenceStore store, HoldemStateSnapshot state) {
  final scope = _scope();
  final result = store.saveSnapshot(
    scope: scope,
    snapshot: SnapshotEnvelope(
      snapshotId: 'snapshot_001',
      snapshotType: 'HoldemStateSnapshot',
      snapshotVersion: '1.0',
      protocolVersion: scope.protocolVersion,
      tableId: scope.tableId,
      sessionId: scope.sessionId,
      snapshotBaseEventSeq: state.tableState.eventSequence,
      snapshotHash: 'hash_001',
      payload: state.toJson(),
    ),
  );
  expect(result.isSuccess, isTrue);
}

HoldemStateSnapshot _typedSnapshot() {
  return HoldemStateSnapshot(
    tableState: TableState.initial(
      tableId: 'table_001',
      sessionId: 'session_001',
      protocolVersion: '1.0.0',
    ),
    handState: const HoldemHandState(
      handId: 'hand_001',
      phase: HoldemHandPhase.handIdle,
      bettingRound: HoldemBettingRound.none,
      seats: <HoldemSeatState>[],
      currentActorSeat: 0,
      buttonSeat: 0,
      smallBlindSeat: 0,
      bigBlindSeat: 1,
      currentBetToCall: 0,
      minimumRaiseAmount: 1,
    ),
    eventCursor: HoldemEventCursor(
      protocolVersion: '1.0.0',
      tableId: 'table_001',
      sessionId: 'session_001',
      nextEventSeq: 1,
      previousEventHash: genesisEventHash,
      actorRef: 'peer_local',
      eventIdFactory: _eventId,
      emittedAtFactory: _eventTimestamp,
    ),
  );
}

String _eventId(String eventType, int eventSeq) => 'evt_${eventType}_$eventSeq';

String _eventTimestamp() => '2026-08-10T00:00:00Z';

ResolvedInvite _invite() => const ResolvedInvite(
  inviteId: 'invite_001',
  tableId: 'table_001',
  sessionId: 'session_001',
  modeType: 'open_table',
  protocolVersion: '1.0.0',
  requiresReceiptAck: false,
  requiresRetentionAck: false,
  requiresCaptureAck: false,
);

RecoveryPersistenceScope _scope() => const RecoveryPersistenceScope(
  tableId: 'table_001',
  sessionId: 'session_001',
  protocolVersion: '1.0.0',
);

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
