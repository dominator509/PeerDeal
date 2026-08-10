import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:peerdeal_desktop/join_flow/join_flow_models.dart';
import 'package:peerdeal_desktop/recovery/app_recovery_retention_coordinator.dart';
import 'package:peerdeal_desktop/recovery/app_recovery_session_close_coordinator.dart';
import 'package:peerdeal_desktop/recovery/app_recovery_session_close_event_adapter.dart';
import 'package:peerdeal_desktop/session/app_holdem_production_session_bootstrap.dart';
import 'package:peerdeal_desktop/session/app_holdem_production_session_bootstrap_route.dart';
import 'package:peerdeal_privacy/peerdeal_privacy.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';

void main() {
  testWidgets('loads and mounts a production route from route arguments', (
    tester,
  ) async {
    final invite = _invite();
    final source = _Source(_input());
    final bootstrap = AppHoldemProductionSessionBootstrap(source: source);

    await tester.pumpWidget(
      _routeHost(
        bootstrap: bootstrap,
        settings: RouteSettings(name: '/holdem-live', arguments: invite),
      ),
    );
    await tester.pumpAndSettle();

    expect(source.loadedInvite, same(invite));
    expect(find.text("Hold'em table"), findsOneWidget);
  });

  testWidgets('rejects route settings without a resolved invite', (
    tester,
  ) async {
    final source = _Source(_input());
    final bootstrap = AppHoldemProductionSessionBootstrap(source: source);

    await tester.pumpWidget(
      _routeHost(
        bootstrap: bootstrap,
        settings: const RouteSettings(name: '/holdem-live'),
      ),
    );
    await tester.pumpAndSettle();

    expect(source.loadedInvite, isNull);
    expect(find.text('Route unavailable'), findsOneWidget);
  });

  testWidgets('fails closed when the product source fails', (tester) async {
    final source = _Source(_input(), fail: true);
    final bootstrap = AppHoldemProductionSessionBootstrap(source: source);

    await tester.pumpWidget(
      _routeHost(
        bootstrap: bootstrap,
        settings: RouteSettings(name: '/holdem-live', arguments: _invite()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Route unavailable'), findsOneWidget);
  });

  testWidgets('shows loading and then fails closed after a source timeout', (
    tester,
  ) async {
    final source = _Source(
      _input(),
      pending: Completer<AppHoldemProductionSessionInput>().future,
    );
    final bootstrap = AppHoldemProductionSessionBootstrap(
      source: source,
      sourceLoadTimeout: const Duration(milliseconds: 1),
    );

    await tester.pumpWidget(
      _routeHost(
        bootstrap: bootstrap,
        settings: RouteSettings(name: '/holdem-live', arguments: _invite()),
      ),
    );
    expect(find.text('Opening table'), findsOneWidget);
    expect(find.text('Route unavailable'), findsNothing);

    await tester.pump(const Duration(milliseconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Route unavailable'), findsOneWidget);
  });

  testWidgets('fails closed when the bootstrapped route path differs', (
    tester,
  ) async {
    final source = _Source(_input(path: '/other-route'));
    final bootstrap = AppHoldemProductionSessionBootstrap(source: source);

    await tester.pumpWidget(
      _routeHost(
        bootstrap: bootstrap,
        settings: RouteSettings(name: '/holdem-live', arguments: _invite()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Route unavailable'), findsOneWidget);
  });
}

Widget _routeHost({
  required AppHoldemProductionSessionBootstrap bootstrap,
  required RouteSettings settings,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Navigator(
      onGenerateRoute: (_) => PageRouteBuilder<void>(
        settings: settings,
        pageBuilder: (context, animation, secondaryAnimation) =>
            AppHoldemProductionSessionBootstrapRoute.fromRouteSettings(
              bootstrap: bootstrap,
            )(context),
      ),
    ),
  );
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
  _Source(this.input, {this.fail = false, this.pending});

  final AppHoldemProductionSessionInput input;
  final bool fail;
  final Future<AppHoldemProductionSessionInput>? pending;
  ResolvedInvite? loadedInvite;

  @override
  Future<AppHoldemProductionSessionInput> load(ResolvedInvite invite) async {
    loadedInvite = invite;
    if (fail) throw StateError('product source failed');
    final pending = this.pending;
    if (pending != null) return pending;
    return input;
  }
}

AppHoldemProductionSessionInput _input({String path = '/holdem-live'}) {
  final tableState = TableState.initial(
    tableId: 'table_001',
    sessionId: 'session_001',
    protocolVersion: '1.0.0',
  );
  return AppHoldemProductionSessionInput(
    initialTableState: tableState,
    initialHandState: const HoldemHandState(
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
      tableId: 'table_001',
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
    path: path,
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
