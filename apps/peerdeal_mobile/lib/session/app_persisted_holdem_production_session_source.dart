import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';

import '../join_flow/join_flow_models.dart';
import '../recovery/app_recovery_session_close_event_adapter.dart';
import 'app_holdem_production_session_bootstrap.dart';
import 'native_local_peer_identity_provisioner.dart';

typedef AppHoldemProductionSessionInputFactory =
    AppHoldemProductionSessionInput Function(
      ResolvedInvite invite,
      HoldemStateSnapshot snapshot,
    );

typedef AppHoldemProductionSessionContextInputFactory =
    AppHoldemProductionSessionInput Function(
      JoinFlowSessionContext sessionContext,
      HoldemStateSnapshot snapshot,
    );

typedef AppHoldemProductionCloseEventAdapterFactory =
    AppRecoverySessionCloseEventAdapter Function(
      RecoveryPersistenceScope scope,
    );

class AppPersistedHoldemProductionSessionRoutePolicy {
  const AppPersistedHoldemProductionSessionRoutePolicy({
    required this.path,
    required this.navigationLabel,
    required this.remotePeerId,
    required this.localSeat,
    required this.closeEventAdapterFactory,
  });

  final String path;
  final String navigationLabel;
  final String remotePeerId;
  final int localSeat;
  final AppHoldemProductionCloseEventAdapterFactory closeEventAdapterFactory;

  AppHoldemProductionSessionInput buildInput({
    required HoldemStateSnapshot snapshot,
    required String localPeerId,
    String? remotePeerId,
    int? localSeat,
  }) {
    return AppHoldemProductionSessionInput(
      initialTableState: snapshot.tableState,
      initialHandState: snapshot.handState,
      initialCursor: snapshot.eventCursor,
      closeEventAdapter: closeEventAdapterFactory(
        RecoveryPersistenceScope(
          tableId: snapshot.tableState.tableId,
          sessionId: snapshot.tableState.sessionId,
          protocolVersion: snapshot.tableState.protocolVersion,
        ),
      ),
      path: path,
      navigationLabel: navigationLabel,
      peerId: remotePeerId ?? this.remotePeerId,
      localPeerId: localPeerId,
      localSeat: localSeat ?? this.localSeat,
    );
  }
}

/// Loads a typed Hold'em production state from the existing recovery store.
///
/// The adapter owns snapshot decoding, persistence-scope checks, and
/// deterministic recovery-suffix replay. The input factory remains responsible
/// for local identity, route metadata, close policy, and platform dependencies.
class AppPersistedHoldemProductionSessionSource
    implements
        AppHoldemProductionSessionSource,
        AppHoldemProductionSessionContextSource {
  static Future<AppPersistedHoldemProductionSessionSource>
  fromProvisionedLocalIdentity({
    required RecoveryPersistenceStore store,
    required NativeLocalPeerIdentityProvisioner identityProvisioner,
    required AppPersistedHoldemProductionSessionRoutePolicy routePolicy,
    required HoldemEventIdFactory eventIdFactory,
    required HoldemEventTimestampFactory emittedAtFactory,
    required HoldemEventHashFactory eventHashFactory,
    HoldemCoreProjectionAdapter replayAdapter =
        const HoldemCoreProjectionAdapter(),
    HoldemEventReducer eventReducer = const HoldemEventReducer(),
    String snapshotType = 'HoldemStateSnapshot',
    String snapshotVersion = '1.0',
  }) async {
    final provisioned = await identityProvisioner.ensureIdentity();
    final identity = provisioned.identity;
    if (!provisioned.isSuccess || identity == null) {
      throw StateError('Local peer identity is unavailable.');
    }

    return AppPersistedHoldemProductionSessionSource(
      store: store,
      inputFactory: (_, snapshot) => routePolicy.buildInput(
        snapshot: snapshot,
        localPeerId: identity.peerId,
      ),
      contextInputFactory: (sessionContext, snapshot) => routePolicy.buildInput(
        snapshot: snapshot,
        localPeerId: identity.peerId,
        remotePeerId: sessionContext.remotePeerId,
        localSeat: sessionContext.localSeat,
      ),
      eventIdFactory: eventIdFactory,
      emittedAtFactory: emittedAtFactory,
      eventHashFactory: eventHashFactory,
      replayAdapter: replayAdapter,
      eventReducer: eventReducer,
      snapshotType: snapshotType,
      snapshotVersion: snapshotVersion,
    );
  }

  const AppPersistedHoldemProductionSessionSource({
    required RecoveryPersistenceStore store,
    required AppHoldemProductionSessionInputFactory inputFactory,
    AppHoldemProductionSessionContextInputFactory? contextInputFactory,
    required HoldemEventIdFactory eventIdFactory,
    required HoldemEventTimestampFactory emittedAtFactory,
    required HoldemEventHashFactory eventHashFactory,
    HoldemCoreProjectionAdapter replayAdapter =
        const HoldemCoreProjectionAdapter(),
    HoldemEventReducer eventReducer = const HoldemEventReducer(),
    this.snapshotType = 'HoldemStateSnapshot',
    this.snapshotVersion = '1.0',
  }) : _store = store,
       _inputFactory = inputFactory,
       _contextInputFactory = contextInputFactory,
       _eventIdFactory = eventIdFactory,
       _emittedAtFactory = emittedAtFactory,
       _eventHashFactory = eventHashFactory,
       _replayAdapter = replayAdapter,
       _eventReducer = eventReducer;

  final RecoveryPersistenceStore _store;
  final AppHoldemProductionSessionInputFactory _inputFactory;
  final AppHoldemProductionSessionContextInputFactory? _contextInputFactory;
  final HoldemEventIdFactory _eventIdFactory;
  final HoldemEventTimestampFactory _emittedAtFactory;
  final HoldemEventHashFactory _eventHashFactory;
  final HoldemCoreProjectionAdapter _replayAdapter;
  final HoldemEventReducer _eventReducer;
  final String snapshotType;
  final String snapshotVersion;

  @override
  Future<AppHoldemProductionSessionInput> load(
    ResolvedInvite invite, {
    Future<void>? cancellation,
  }) {
    return Future<AppHoldemProductionSessionInput>.sync(
      () => _load(invite: invite),
    );
  }

  @override
  Future<AppHoldemProductionSessionInput> loadForSessionContext(
    JoinFlowSessionContext sessionContext, {
    Future<void>? cancellation,
  }) {
    if (_contextInputFactory == null) {
      return Future<AppHoldemProductionSessionInput>.error(
        StateError('Persisted session context loading is unavailable.'),
      );
    }
    return Future<AppHoldemProductionSessionInput>.sync(
      () =>
          _load(invite: sessionContext.invite, sessionContext: sessionContext),
    );
  }

  AppHoldemProductionSessionInput _load({
    required ResolvedInvite invite,
    JoinFlowSessionContext? sessionContext,
  }) {
    AppHoldemProductionSessionInput buildInput(HoldemStateSnapshot snapshot) {
      final contextInputFactory = _contextInputFactory;
      if (sessionContext != null && contextInputFactory != null) {
        return contextInputFactory(sessionContext, snapshot);
      }
      if (sessionContext != null) {
        throw StateError('Persisted session context loading is unavailable.');
      }
      return _inputFactory(invite, snapshot);
    }

    final scope = RecoveryPersistenceScope(
      tableId: invite.tableId,
      sessionId: invite.sessionId,
      protocolVersion: invite.protocolVersion,
    );
    if (!scope.hasValidStorageIdentity) {
      throw StateError('Resolved invite persistence scope is invalid.');
    }

    final PersistedRecoveryWindow window;
    try {
      window = _store.loadWindow(scope);
    } on Object {
      throw StateError('Resolved invite persistence window is unavailable.');
    }

    final envelope = window.snapshot;
    if (envelope == null) {
      throw StateError('No typed Holdem state snapshot is persisted.');
    }
    if (envelope.snapshotType != snapshotType ||
        envelope.snapshotVersion != snapshotVersion) {
      throw StateError(
        'Persisted Holdem state snapshot version is unsupported.',
      );
    }
    if (envelope.tableId != invite.tableId ||
        envelope.sessionId != invite.sessionId ||
        envelope.protocolVersion != invite.protocolVersion) {
      throw StateError(
        'Persisted Holdem state snapshot scope mismatches invite.',
      );
    }
    final state = HoldemStateSnapshot.fromJson(
      envelope.payload,
      eventIdFactory: _eventIdFactory,
      emittedAtFactory: _emittedAtFactory,
      eventHashFactory: _eventHashFactory,
    );
    if (state.tableState.tableId != invite.tableId ||
        state.tableState.sessionId != invite.sessionId ||
        state.tableState.protocolVersion != invite.protocolVersion ||
        state.tableState.eventSequence != envelope.snapshotBaseEventSeq ||
        state.eventCursor.nextEventSeq != envelope.snapshotBaseEventSeq + 1) {
      throw StateError('Persisted Holdem state does not match snapshot scope.');
    }

    final suffix = window.events
        .where((event) => event.eventSeq > envelope.snapshotBaseEventSeq)
        .toList(growable: false);
    if (suffix.isEmpty) {
      return buildInput(state);
    }

    final replay = _replayAdapter.replay(
      coreState: state.tableState,
      handState: state.handState,
      cursor: state.eventCursor,
      events: suffix,
      eventReducer: _eventReducer,
    );
    if (replay.isRejected) {
      throw StateError('Persisted Holdem recovery replay was rejected.');
    }

    return buildInput(
      HoldemStateSnapshot(
        tableState: replay.coreState,
        handState: replay.handState,
        eventCursor: replay.cursor,
      ),
    );
  }
}
