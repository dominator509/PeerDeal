import 'dart:convert';
import 'dart:io';

import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import '../contracts/recovery_persistence_store.dart';
import '../models/persisted_recovery_window.dart';
import '../models/recovery_persistence_result.dart';
import '../models/recovery_persistence_scope.dart';
import '../models/sync_conflict.dart';
import '../models/sync_conflict_severity.dart';
import 'in_memory_recovery_persistence_store.dart';

class JsonFileRecoveryPersistenceStore implements RecoveryPersistenceStore {
  JsonFileRecoveryPersistenceStore({required Directory rootDirectory})
    : _rootDirectory = rootDirectory;

  final Directory _rootDirectory;

  @override
  RecoveryPersistenceResult saveSnapshot({
    required RecoveryPersistenceScope scope,
    required SnapshotEnvelope snapshot,
  }) {
    final hydrate = _hydrate(scope);
    if (!hydrate.result.isSuccess) return hydrate.result;

    final result = hydrate.store.saveSnapshot(scope: scope, snapshot: snapshot);
    if (!result.isSuccess) return result;

    return _write(scope, hydrate.store.loadWindow(scope));
  }

  @override
  RecoveryPersistenceResult appendEvents({
    required RecoveryPersistenceScope scope,
    required List<EventEnvelope> events,
  }) {
    final hydrate = _hydrate(scope);
    if (!hydrate.result.isSuccess) return hydrate.result;

    final result = hydrate.store.appendEvents(scope: scope, events: events);
    if (!result.isSuccess) return result;

    return _write(scope, hydrate.store.loadWindow(scope));
  }

  @override
  PersistedRecoveryWindow loadWindow(RecoveryPersistenceScope scope) {
    final hydrate = _hydrate(scope);
    if (!hydrate.result.isSuccess) {
      return const PersistedRecoveryWindow(events: <EventEnvelope>[]);
    }
    return hydrate.store.loadWindow(scope);
  }

  _HydratedRecoveryStore _hydrate(RecoveryPersistenceScope scope) {
    final store = InMemoryRecoveryPersistenceStore();
    final file = _fileFor(scope);
    if (!file.existsSync()) {
      return _HydratedRecoveryStore(
        store: store,
        result: const RecoveryPersistenceResult.success(),
      );
    }

    final PersistedRecoveryWindow window;
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, Object?>) {
        return _corruptStore(store);
      }
      window = _decodeWindow(decoded);
    } on Object {
      return _corruptStore(store);
    }

    final append = store.appendEvents(scope: scope, events: window.events);
    if (!append.isSuccess) {
      return _HydratedRecoveryStore(store: store, result: append);
    }

    final snapshot = window.snapshot;
    if (snapshot != null) {
      final save = store.saveSnapshot(scope: scope, snapshot: snapshot);
      if (!save.isSuccess) {
        return _HydratedRecoveryStore(store: store, result: save);
      }
    }

    return _HydratedRecoveryStore(
      store: store,
      result: const RecoveryPersistenceResult.success(),
    );
  }

  RecoveryPersistenceResult _write(
    RecoveryPersistenceScope scope,
    PersistedRecoveryWindow window,
  ) {
    File? tempFile;
    try {
      if (!_rootDirectory.existsSync()) {
        _rootDirectory.createSync(recursive: true);
      }
      final file = _fileFor(scope);
      tempFile = File(
        '${file.path}.tmp.${DateTime.now().microsecondsSinceEpoch}',
      );
      tempFile.writeAsStringSync(
        canonicalJsonEncode(_encodeWindow(window)),
        flush: true,
      );
      tempFile.renameSync(file.path);
      return const RecoveryPersistenceResult.success();
    } on Object {
      if (tempFile != null && tempFile.existsSync()) {
        try {
          tempFile.deleteSync();
        } on Object {
          // Best-effort cleanup; the failed persistence result is authoritative.
        }
      }
      return const RecoveryPersistenceResult(
        isSuccess: false,
        conflicts: <SyncConflict>[
          SyncConflict(
            code: 'ERR_RECOVERY_PERSISTENCE_WRITE_FAILED',
            message: 'Recovery persistence file could not be written.',
            severity: SyncConflictSeverity.fatal,
          ),
        ],
      );
    }
  }

  _HydratedRecoveryStore _corruptStore(InMemoryRecoveryPersistenceStore store) {
    return _HydratedRecoveryStore(
      store: store,
      result: const RecoveryPersistenceResult(
        isSuccess: false,
        conflicts: <SyncConflict>[
          SyncConflict(
            code: 'ERR_RECOVERY_PERSISTENCE_FILE_CORRUPT',
            message: 'Recovery persistence file could not be decoded.',
            severity: SyncConflictSeverity.fatal,
          ),
        ],
      ),
    );
  }

  PersistedRecoveryWindow _decodeWindow(Map<String, Object?> json) {
    final events = json['events'];
    if (events is! List<Object?>) {
      throw const FormatException('Expected recovery events list.');
    }

    final snapshot = json['snapshot'];
    return PersistedRecoveryWindow(
      snapshot: snapshot == null
          ? null
          : SnapshotEnvelope.fromJson(_object(snapshot)),
      events: events
          .map((event) => EventEnvelope.fromJson(_object(event)))
          .toList(growable: false),
    );
  }

  Map<String, Object?> _encodeWindow(PersistedRecoveryWindow window) {
    return <String, Object?>{
      'snapshot': window.snapshot?.toJson(),
      'events': window.events
          .map((event) => event.toJson())
          .toList(growable: false),
    };
  }

  Map<String, Object?> _object(Object? value) {
    if (value is Map<String, Object?>) return value;
    throw const FormatException('Expected recovery object.');
  }

  File _fileFor(RecoveryPersistenceScope scope) {
    final fileName = base64Url.encode(utf8.encode(scope.storageKey));
    return File(
      '${_rootDirectory.path}${Platform.pathSeparator}$fileName.json',
    );
  }
}

class _HydratedRecoveryStore {
  const _HydratedRecoveryStore({required this.store, required this.result});

  final InMemoryRecoveryPersistenceStore store;
  final RecoveryPersistenceResult result;
}
