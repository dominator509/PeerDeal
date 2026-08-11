import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';

import '../join_flow/join_flow_models.dart';
import '../recovery/app_recovery_session_close_event_adapter.dart';
import 'app_holdem_production_session_bootstrap.dart';
import 'native_local_peer_identity_loader.dart';
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

  /// Rejects route policy that cannot produce a valid production composition.
  ///
  /// This is intentionally checked before native local-identity provisioning;
  /// malformed app policy must not cause a secure-storage mutation first.
  void validate() {
    if (path.trim().isEmpty ||
        path != path.trim() ||
        !path.startsWith('/') ||
        path == '/' ||
        path.endsWith('/') ||
        path.contains('?') ||
        path.contains('#') ||
        path.contains('//') ||
        path.contains(r'\') ||
        _containsControlCharacter(path)) {
      throw ArgumentError.value(
        path,
        'path',
        'Production route path is not safe.',
      );
    }
    if (navigationLabel.trim().isEmpty ||
        navigationLabel != navigationLabel.trim() ||
        _containsLabelControlCharacter(navigationLabel)) {
      throw ArgumentError.value(
        navigationLabel,
        'navigationLabel',
        'Production navigation label is not safe.',
      );
    }
    _validatePeerId(remotePeerId, 'remotePeerId');
    _validateLocalSeat(localSeat, 'localSeat');
  }

  AppHoldemProductionSessionInput buildInput({
    required HoldemStateSnapshot snapshot,
    required String localPeerId,
    String? remotePeerId,
    int? localSeat,
  }) {
    final selectedRemotePeerId = remotePeerId ?? this.remotePeerId;
    final selectedLocalSeat = localSeat ?? this.localSeat;
    _validatePeerId(selectedRemotePeerId, 'remotePeerId');
    _validateLocalSeat(selectedLocalSeat, 'localSeat');

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
      peerId: selectedRemotePeerId,
      localPeerId: localPeerId,
      localSeat: selectedLocalSeat,
    );
  }

  static void _validatePeerId(String peerId, String fieldName) {
    if (peerId.trim().isEmpty ||
        peerId != peerId.trim() ||
        _containsControlCharacter(peerId)) {
      throw ArgumentError.value(
        peerId,
        fieldName,
        'Peer identity must be non-empty, unpadded, and control-free.',
      );
    }
  }

  static void _validateLocalSeat(int localSeat, String fieldName) {
    if (localSeat < 1) {
      throw ArgumentError.value(
        localSeat,
        fieldName,
        'Local seat must be positive.',
      );
    }
  }

  static bool _containsControlCharacter(String value) =>
      value.codeUnits.any((codeUnit) => codeUnit <= 0x20 || codeUnit == 0x7F);

  static bool _containsLabelControlCharacter(String value) =>
      value.codeUnits.any((codeUnit) => codeUnit < 0x20 || codeUnit == 0x7F);
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
    int maxRecoveryEvents = RecoveryEventWindowLimits.defaultMaxEvents,
  }) async {
    routePolicy.validate();
    _validateMaxRecoveryEvents(maxRecoveryEvents);
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
      maxRecoveryEvents: maxRecoveryEvents,
    );
  }

  /// Composes identity provisioning at the persisted-load boundary.
  ///
  /// The recovery window is validated and replayed before the provisioner is
  /// invoked, so an invite with no usable persisted state does not mutate
  /// native secure storage.
  static Future<AppPersistedHoldemProductionSessionSource>
  fromLocalIdentityProvisioner({
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
    int maxRecoveryEvents = RecoveryEventWindowLimits.defaultMaxEvents,
  }) async {
    routePolicy.validate();
    _validateMaxRecoveryEvents(maxRecoveryEvents);
    AppLocalPeerIdentity? localIdentity;

    Future<void> ensureIdentity({Future<void>? cancellation}) async {
      if (localIdentity != null) return;
      final provisioned = await identityProvisioner.ensureIdentity(
        cancellation: cancellation,
      );
      final identity = provisioned.identity;
      if (!provisioned.isSuccess || identity == null) {
        throw StateError('Local peer identity is unavailable.');
      }
      localIdentity = identity;
    }

    AppLocalPeerIdentity requireIdentity() {
      final identity = localIdentity;
      if (identity == null) {
        throw StateError('Local peer identity is unavailable.');
      }
      return identity;
    }

    return AppPersistedHoldemProductionSessionSource(
      store: store,
      identityLoader: ensureIdentity,
      inputFactory: (_, snapshot) => routePolicy.buildInput(
        snapshot: snapshot,
        localPeerId: requireIdentity().peerId,
      ),
      contextInputFactory: (sessionContext, snapshot) => routePolicy.buildInput(
        snapshot: snapshot,
        localPeerId: requireIdentity().peerId,
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
      maxRecoveryEvents: maxRecoveryEvents,
    );
  }

  AppPersistedHoldemProductionSessionSource({
    required RecoveryPersistenceStore store,
    required AppHoldemProductionSessionInputFactory inputFactory,
    AppHoldemProductionSessionContextInputFactory? contextInputFactory,
    Future<void> Function({Future<void>? cancellation})? identityLoader,
    required HoldemEventIdFactory eventIdFactory,
    required HoldemEventTimestampFactory emittedAtFactory,
    required HoldemEventHashFactory eventHashFactory,
    HoldemCoreProjectionAdapter replayAdapter =
        const HoldemCoreProjectionAdapter(),
    HoldemEventReducer eventReducer = const HoldemEventReducer(),
    this.snapshotType = 'HoldemStateSnapshot',
    this.snapshotVersion = '1.0',
    int maxRecoveryEvents = RecoveryEventWindowLimits.defaultMaxEvents,
  }) : maxRecoveryEvents = _validateMaxRecoveryEvents(maxRecoveryEvents),
       _store = store,
       _inputFactory = inputFactory,
       _contextInputFactory = contextInputFactory,
       _identityLoader = identityLoader,
       _eventIdFactory = eventIdFactory,
       _emittedAtFactory = emittedAtFactory,
       _eventHashFactory = eventHashFactory,
       _replayAdapter = replayAdapter,
       _eventReducer = eventReducer;

  final RecoveryPersistenceStore _store;
  final AppHoldemProductionSessionInputFactory _inputFactory;
  final AppHoldemProductionSessionContextInputFactory? _contextInputFactory;
  final Future<void> Function({Future<void>? cancellation})? _identityLoader;
  final HoldemEventIdFactory _eventIdFactory;
  final HoldemEventTimestampFactory _emittedAtFactory;
  final HoldemEventHashFactory _eventHashFactory;
  final HoldemCoreProjectionAdapter _replayAdapter;
  final HoldemEventReducer _eventReducer;
  final String snapshotType;
  final String snapshotVersion;
  final int maxRecoveryEvents;

  @override
  Future<AppHoldemProductionSessionInput> load(
    ResolvedInvite invite, {
    Future<void>? cancellation,
  }) {
    return _load(invite: invite, cancellation: cancellation);
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
    return _load(
      invite: sessionContext.invite,
      sessionContext: sessionContext,
      cancellation: cancellation,
    );
  }

  Future<AppHoldemProductionSessionInput> _load({
    required ResolvedInvite invite,
    JoinFlowSessionContext? sessionContext,
    Future<void>? cancellation,
  }) async {
    await _throwIfCancelled(cancellation);
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
    if (window.events.length > maxRecoveryEvents) {
      throw StateError(
        'Persisted Holdem recovery event window exceeds the configured limit.',
      );
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
      await _throwIfCancelled(cancellation);
      await _ensureIdentity(cancellation: cancellation);
      await _throwIfCancelled(cancellation);
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

    await _throwIfCancelled(cancellation);
    await _ensureIdentity(cancellation: cancellation);
    await _throwIfCancelled(cancellation);
    return buildInput(
      HoldemStateSnapshot(
        tableState: replay.coreState,
        handState: replay.handState,
        eventCursor: replay.cursor,
      ),
    );
  }

  Future<void> _ensureIdentity({Future<void>? cancellation}) async {
    final identityLoader = _identityLoader;
    if (identityLoader != null) {
      await identityLoader(cancellation: cancellation);
    }
  }

  Future<void> _throwIfCancelled(Future<void>? cancellation) async {
    if (cancellation == null) return;
    var cancelled = false;
    cancellation.then<void>(
      (_) => cancelled = true,
      onError: (Object _, StackTrace _) => cancelled = true,
    );
    await Future<void>.value();
    if (cancelled) {
      throw StateError('Persisted session load cancelled.');
    }
  }
}

int _validateMaxRecoveryEvents(int value) {
  if (value <= 0) {
    throw ArgumentError.value(
      value,
      'maxRecoveryEvents',
      'Recovery event limit must be positive.',
    );
  }
  return value;
}
