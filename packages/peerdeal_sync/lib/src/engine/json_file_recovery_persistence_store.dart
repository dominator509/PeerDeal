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
  JsonFileRecoveryPersistenceStore({
    required Directory rootDirectory,
    int maxFileBytes = defaultMaxFileBytes,
  }) : _rootDirectory = rootDirectory,
       _maxFileBytes = maxFileBytes {
    if (maxFileBytes <= 0) {
      throw ArgumentError.value(
        maxFileBytes,
        'maxFileBytes',
        'Recovery persistence file limit must be positive.',
      );
    }
  }

  static const defaultMaxFileBytes = 4 * 1024 * 1024;

  final Directory _rootDirectory;
  final int _maxFileBytes;

  @override
  RecoveryPersistenceResult saveSnapshot({
    required RecoveryPersistenceScope scope,
    required SnapshotEnvelope snapshot,
  }) {
    final scopeResult = _validateScopeIdentity(scope);
    if (!scopeResult.isSuccess) return scopeResult;

    try {
      return _withScopeLock(scope, () {
        final hydrate = _hydrate(scope);
        if (!hydrate.result.isSuccess) return hydrate.result;

        final result = hydrate.store.saveSnapshot(
          scope: scope,
          snapshot: snapshot,
        );
        if (!result.isSuccess) return result;

        return _write(scope, hydrate.store.loadWindow(scope));
      });
    } on _RecoveryPersistenceLockException {
      return _lockFailure();
    }
  }

  @override
  RecoveryPersistenceResult appendEvents({
    required RecoveryPersistenceScope scope,
    required List<EventEnvelope> events,
  }) {
    final scopeResult = _validateScopeIdentity(scope);
    if (!scopeResult.isSuccess) return scopeResult;

    try {
      return _withScopeLock(scope, () {
        final hydrate = _hydrate(scope);
        if (!hydrate.result.isSuccess) return hydrate.result;

        final result = hydrate.store.appendEvents(scope: scope, events: events);
        if (!result.isSuccess) return result;

        return _write(scope, hydrate.store.loadWindow(scope));
      });
    } on _RecoveryPersistenceLockException {
      return _lockFailure();
    }
  }

  @override
  RecoveryPersistenceResult wipe({required RecoveryPersistenceScope scope}) {
    final scopeResult = _validateScopeIdentity(scope);
    if (!scopeResult.isSuccess) return scopeResult;

    try {
      return _withScopeLock(scope, () {
        final file = _fileFor(scope);
        final files = <File>[
          if (file.existsSync()) file,
          ..._temporaryFilesFor(file),
        ];
        for (final candidate in files) {
          if (candidate.existsSync()) {
            candidate.deleteSync();
          }
        }
        return const RecoveryPersistenceResult.success();
      });
    } on Object {
      return const RecoveryPersistenceResult(
        isSuccess: false,
        conflicts: <SyncConflict>[
          SyncConflict(
            code: 'ERR_RECOVERY_PERSISTENCE_WIPE_FAILED',
            message: 'Recovery persistence data could not be wiped.',
            severity: SyncConflictSeverity.fatal,
          ),
        ],
      );
    }
  }

  @override
  PersistedRecoveryWindow loadWindow(RecoveryPersistenceScope scope) {
    if (!scope.hasValidStorageIdentity) {
      return const PersistedRecoveryWindow(events: <EventEnvelope>[]);
    }

    try {
      return _withScopeLock(scope, () {
        final hydrate = _hydrate(scope);
        if (!hydrate.result.isSuccess) {
          return const PersistedRecoveryWindow(events: <EventEnvelope>[]);
        }
        return hydrate.store.loadWindow(scope);
      }, createRoot: false);
    } on Object {
      return const PersistedRecoveryWindow(events: <EventEnvelope>[]);
    }
  }

  /// Serializes the complete hydrate-modify-write transaction per scope.
  ///
  /// The operating system releases this advisory lock when the owning process
  /// exits, including an abnormal exit, so interrupted writers do not leave a
  /// permanent application-level lock record.
  T _withScopeLock<T>(
    RecoveryPersistenceScope scope,
    T Function() operation, {
    bool createRoot = true,
  }) {
    if (!_rootDirectory.existsSync()) {
      if (!createRoot) return operation();
      _rootDirectory.createSync(recursive: true);
    }

    final lockFile = _lockFileFor(scope);
    RandomAccessFile? handle;
    try {
      handle = lockFile.openSync(mode: FileMode.append);
      handle.lockSync(FileLock.exclusive);
    } on Object {
      try {
        handle?.closeSync();
      } on Object {
        // Preserve the lock failure as the authoritative result.
      }
      throw const _RecoveryPersistenceLockException();
    }

    var locked = false;
    try {
      locked = true;
      return operation();
    } finally {
      if (locked) {
        try {
          handle.unlockSync();
        } on Object {
          // Closing the handle still releases the OS lock on supported hosts.
        }
      }
      handle.closeSync();
    }
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
      if (file.lengthSync() > _maxFileBytes) {
        return _fileTooLarge(store);
      }
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
      final encodedWindow = canonicalJsonEncode(_encodeWindow(window));
      if (utf8.encode(encodedWindow).length > _maxFileBytes) {
        return _fileTooLargeResult();
      }
      tempFile.writeAsStringSync(encodedWindow, flush: true);
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

  RecoveryPersistenceResult _validateScopeIdentity(
    RecoveryPersistenceScope scope,
  ) {
    if (scope.hasValidStorageIdentity) {
      return const RecoveryPersistenceResult.success();
    }
    return const RecoveryPersistenceResult(
      isSuccess: false,
      conflicts: <SyncConflict>[
        SyncConflict(
          code: 'ERR_RECOVERY_PERSISTENCE_SCOPE_INVALID',
          message: 'Recovery persistence scope identity is invalid.',
          severity: SyncConflictSeverity.fatal,
        ),
      ],
    );
  }

  RecoveryPersistenceResult _lockFailure() {
    return const RecoveryPersistenceResult(
      isSuccess: false,
      conflicts: <SyncConflict>[
        SyncConflict(
          code: 'ERR_RECOVERY_PERSISTENCE_LOCK_FAILED',
          message: 'Recovery persistence scope could not be locked.',
          severity: SyncConflictSeverity.fatal,
        ),
      ],
    );
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

  _HydratedRecoveryStore _fileTooLarge(InMemoryRecoveryPersistenceStore store) {
    return _HydratedRecoveryStore(store: store, result: _fileTooLargeResult());
  }

  RecoveryPersistenceResult _fileTooLargeResult() {
    return const RecoveryPersistenceResult(
      isSuccess: false,
      conflicts: <SyncConflict>[
        SyncConflict(
          code: 'ERR_RECOVERY_PERSISTENCE_FILE_TOO_LARGE',
          message: 'Recovery persistence file exceeds the configured limit.',
          severity: SyncConflictSeverity.fatal,
        ),
      ],
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
    final fileName = _encodedScopeKey(scope);
    return File(
      '${_rootDirectory.path}${Platform.pathSeparator}$fileName.json',
    );
  }

  File _lockFileFor(RecoveryPersistenceScope scope) {
    final fileName = _encodedScopeKey(scope);
    return File(
      '${_rootDirectory.path}${Platform.pathSeparator}$fileName.lock',
    );
  }

  String _encodedScopeKey(RecoveryPersistenceScope scope) =>
      base64Url.encode(utf8.encode(scope.storageKey));

  List<File> _temporaryFilesFor(File file) {
    if (!_rootDirectory.existsSync()) return <File>[];
    final prefix = '${file.path}.tmp.';
    return _rootDirectory
        .listSync(followLinks: false)
        .whereType<File>()
        .where((candidate) => candidate.path.startsWith(prefix))
        .toList(growable: false);
  }
}

class _HydratedRecoveryStore {
  const _HydratedRecoveryStore({required this.store, required this.result});

  final InMemoryRecoveryPersistenceStore store;
  final RecoveryPersistenceResult result;
}

class _RecoveryPersistenceLockException implements Exception {
  const _RecoveryPersistenceLockException();
}
