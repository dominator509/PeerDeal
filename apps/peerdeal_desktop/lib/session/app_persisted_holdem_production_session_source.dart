import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:peerdeal_variants/peerdeal_variants.dart';

import '../join_flow/join_flow_models.dart';
import 'app_holdem_production_session_bootstrap.dart';

typedef AppHoldemProductionSessionInputFactory =
    AppHoldemProductionSessionInput Function(
      ResolvedInvite invite,
      HoldemStateSnapshot snapshot,
    );

/// Loads a typed Hold'em production state from the existing recovery store.
///
/// The adapter owns snapshot decoding, persistence-scope checks, and
/// deterministic recovery-suffix replay. The input factory remains responsible
/// for local identity, route metadata, close policy, and platform dependencies.
class AppPersistedHoldemProductionSessionSource
    implements AppHoldemProductionSessionSource {
  const AppPersistedHoldemProductionSessionSource({
    required RecoveryPersistenceStore store,
    required AppHoldemProductionSessionInputFactory inputFactory,
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
       _eventIdFactory = eventIdFactory,
       _emittedAtFactory = emittedAtFactory,
       _eventHashFactory = eventHashFactory,
       _replayAdapter = replayAdapter,
       _eventReducer = eventReducer;

  final RecoveryPersistenceStore _store;
  final AppHoldemProductionSessionInputFactory _inputFactory;
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
    return Future<AppHoldemProductionSessionInput>.sync(() => _load(invite));
  }

  AppHoldemProductionSessionInput _load(ResolvedInvite invite) {
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
      return _inputFactory(invite, state);
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

    return _inputFactory(
      invite,
      HoldemStateSnapshot(
        tableState: replay.coreState,
        handState: replay.handState,
        eventCursor: replay.cursor,
      ),
    );
  }
}
