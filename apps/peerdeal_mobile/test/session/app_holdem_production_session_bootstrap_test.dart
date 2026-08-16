import 'dart:async';

import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_mobile/join_flow/join_flow_models.dart';
import 'package:peerdeal_mobile/recovery/app_recovery_retention_coordinator.dart';
import 'package:peerdeal_mobile/recovery/app_recovery_session_close_coordinator.dart';
import 'package:peerdeal_mobile/recovery/app_recovery_session_close_event_adapter.dart';
import 'package:peerdeal_mobile/session/app_holdem_production_session_bootstrap.dart';
import 'package:peerdeal_privacy/peerdeal_privacy.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';
import 'package:test/test.dart';

void main() {
  test(
    'loads resolved product state and composes the production route',
    () async {
      final invite = _invite();
      final source = _Source(_input());

      final composition = await AppHoldemProductionSessionBootstrap(
        source: source,
      ).createForInvite(invite);

      expect(source.loadedInvite, same(invite));
      expect(composition.sessionRuntime.state.tableId, invite.tableId);
      expect(composition.sessionRuntime.state.sessionId, invite.sessionId);
      expect(
        composition.holdemRuntime.cursor.protocolVersion,
        invite.protocolVersion,
      );
      expect(composition.route.path, '/holdem-live');
    },
  );

  test('loads context-aware source with verified peer and seat', () async {
    final sessionContext = JoinFlowSessionContext(
      invite: _invite(),
      remotePeerId: 'peer_selected',
      localSeat: 3,
    );
    final source = _ContextSource(_input());

    final composition = await AppHoldemProductionSessionBootstrap(
      source: source,
      contextSource: source,
    ).createForSessionContext(sessionContext);

    expect(source.loadedContext, same(sessionContext));
    expect(composition.route.path, '/holdem-live');
  });

  test(
    'rejects hydrated state that does not match the resolved invite',
    () async {
      final source = _Source(_input(tableId: 'table_other'));

      await expectLater(
        AppHoldemProductionSessionBootstrap(
          source: source,
        ).createForInvite(_invite()),
        throwsStateError,
      );
    },
  );

  test('rejects malformed invite before loading product state', () async {
    final source = _Source(_input());

    await expectLater(
      AppHoldemProductionSessionBootstrap(source: source).createForInvite(
        const ResolvedInvite(
          inviteId: ' inv_001',
          tableId: 'table_001',
          sessionId: 'session_001',
          modeType: 'open_table',
          protocolVersion: '1.0.0',
          requiresReceiptAck: true,
          requiresRetentionAck: true,
          requiresCaptureAck: true,
        ),
      ),
      throwsArgumentError,
    );
    expect(source.loadedInvite, isNull);
  });

  test(
    'rejects C1 control-bearing invite identity before source load',
    () async {
      final source = _Source(_input());

      await expectLater(
        AppHoldemProductionSessionBootstrap(source: source).createForInvite(
          const ResolvedInvite(
            inviteId: 'inv_\u0085_001',
            tableId: 'table_001',
            sessionId: 'session_001',
            modeType: 'open_table',
            protocolVersion: '1.0.0',
            requiresReceiptAck: true,
            requiresRetentionAck: true,
            requiresCaptureAck: true,
          ),
        ),
        throwsArgumentError,
      );
      expect(source.loadedInvite, isNull);
    },
  );

  test('bounds product source loading', () async {
    final source = _Source(
      _input(),
      loadFuture: Completer<AppHoldemProductionSessionInput>().future,
    );

    await expectLater(
      AppHoldemProductionSessionBootstrap(
        source: source,
        sourceLoadTimeout: const Duration(milliseconds: 1),
      ).createForInvite(_invite()),
      throwsA(isA<TimeoutException>()),
    );
    expect(source.loadedCancellation, isNotNull);
    await expectLater(source.loadedCancellation!, completes);
  });

  test(
    'forwards cancellation and stops waiting for product source loading',
    () async {
      final cancellation = Completer<void>();
      final source = _Source(
        _input(),
        loadFuture: Completer<AppHoldemProductionSessionInput>().future,
      );
      final loading = AppHoldemProductionSessionBootstrap(
        source: source,
        sourceLoadTimeout: const Duration(seconds: 5),
      ).createForInvite(_invite(), cancellation: cancellation.future);

      cancellation.complete();

      await expectLater(loading, throwsStateError);
      expect(source.loadedCancellation, isNot(same(cancellation.future)));
      expect(source.loadedCancellation, isNotNull);
      await expectLater(source.loadedCancellation!, completes);
    },
  );

  test('rejects a non-positive product source timeout', () async {
    await expectLater(
      AppHoldemProductionSessionBootstrap(
        source: _Source(_input()),
        sourceLoadTimeout: Duration.zero,
      ).createForInvite(_invite()),
      throwsArgumentError,
    );
  });

  test('rejects a non-positive recovery event limit before loading', () {
    expect(
      () => AppHoldemProductionSessionBootstrap(
        source: _Source(_input()),
        maxRecoveryEvents: 0,
      ),
      throwsArgumentError,
    );
  });
}

ResolvedInvite _invite() {
  return const ResolvedInvite(
    inviteId: 'inv_001',
    tableId: 'table_001',
    sessionId: 'session_001',
    modeType: 'open_table',
    protocolVersion: '1.0.0',
    requiresReceiptAck: true,
    requiresRetentionAck: true,
    requiresCaptureAck: true,
  );
}

class _Source implements AppHoldemProductionSessionSource {
  _Source(this.input, {this.loadFuture});

  final AppHoldemProductionSessionInput input;
  final Future<AppHoldemProductionSessionInput>? loadFuture;
  ResolvedInvite? loadedInvite;

  @override
  Future<AppHoldemProductionSessionInput> load(
    ResolvedInvite invite, {
    Future<void>? cancellation,
  }) async {
    loadedInvite = invite;
    loadedCancellation = cancellation;
    final pending = loadFuture;
    if (pending != null) return pending;
    return input;
  }

  Future<void>? loadedCancellation;
}

class _ContextSource extends _Source
    implements AppHoldemProductionSessionContextSource {
  _ContextSource(super.input);

  JoinFlowSessionContext? loadedContext;

  @override
  Future<AppHoldemProductionSessionInput> loadForSessionContext(
    JoinFlowSessionContext sessionContext, {
    Future<void>? cancellation,
  }) async {
    loadedContext = sessionContext;
    return input;
  }
}

AppHoldemProductionSessionInput _input({String tableId = 'table_001'}) {
  final tableState = TableState.initial(
    tableId: tableId,
    sessionId: 'session_001',
    protocolVersion: '1.0.0',
  );
  return AppHoldemProductionSessionInput(
    initialTableState: tableState,
    initialHandState: HoldemHandState(
      handId: 'hand_001',
      phase: HoldemHandPhase.bettingPreflop,
      bettingRound: HoldemBettingRound.preflop,
      currentActorSeat: 1,
      buttonSeat: 1,
      smallBlindSeat: 2,
      bigBlindSeat: 3,
      currentBetToCall: 100,
      minimumRaiseAmount: 100,
      seats: <HoldemSeatState>[
        HoldemSeatState(
          seat: 1,
          stack: 1000,
          inHand: true,
          folded: false,
          allIn: false,
        ),
      ],
    ),
    initialCursor: HoldemEventCursor(
      protocolVersion: '1.0.0',
      tableId: tableId,
      sessionId: 'session_001',
      nextEventSeq: 1,
      previousEventHash: genesisEventHash,
      actorRef: 'peer_local',
      eventIdFactory: (eventType, eventSeq) => 'evt_${eventType}_$eventSeq',
      emittedAtFactory: () => '2026-08-10T00:00:00Z',
    ),
    closeEventAdapter: AppRecoverySessionCloseEventAdapter(
      sessionCloseCoordinator: AppRecoverySessionCloseCoordinator(
        retentionCoordinator: AppRecoveryRetentionCoordinator(
          store: InMemoryRecoveryPersistenceStore(),
        ),
        scope: RecoveryPersistenceScope(
          tableId: tableState.tableId,
          sessionId: tableState.sessionId,
          protocolVersion: tableState.protocolVersion,
        ),
        policy: _policy,
      ),
    ),
    path: '/holdem-live',
    navigationLabel: 'Live Holdem',
    peerId: 'peer_remote',
    localPeerId: 'peer_local',
    localSeat: 1,
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
