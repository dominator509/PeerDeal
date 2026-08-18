import 'dart:convert';
import 'dart:io';

import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import '../contracts/recovery_persistence_store.dart';
import '../models/persisted_recovery_window.dart';
import '../models/recovery_persistence_load_result.dart';
import '../models/recovery_persistence_result.dart';
import '../models/recovery_persistence_scope.dart';
import '../models/recovery_event_window_limits.dart';
import '../models/sync_conflict.dart';
import '../models/sync_conflict_severity.dart';
import 'in_memory_recovery_persistence_store.dart';

class JsonFileRecoveryPersistenceStore
    implements RecoveryPersistenceStore, RecoveryPersistenceLoadResultStore {
  JsonFileRecoveryPersistenceStore({
    required Directory rootDirectory,
    int maxFileBytes = defaultMaxFileBytes,
    int maxEvents = InMemoryRecoveryPersistenceStore.defaultMaxEvents,
    int maxEventBytes = InMemoryRecoveryPersistenceStore.defaultMaxEventBytes,
  }) : _rootDirectory = rootDirectory,
       _maxFileBytes = maxFileBytes,
       _maxEvents = maxEvents,
       _maxEventBytes = maxEventBytes {
    if (maxFileBytes <= 0) {
      throw ArgumentError.value(
        maxFileBytes,
        'maxFileBytes',
        'Recovery persistence file limit must be positive.',
      );
    }
    if (maxEvents <= 0) {
      throw ArgumentError.value(
        maxEvents,
        'maxEvents',
        'Recovery persistence event limit must be positive.',
      );
    }
    if (maxEventBytes <= 0) {
      throw ArgumentError.value(
        maxEventBytes,
        'maxEventBytes',
        'Recovery persistence event byte limit must be positive.',
      );
    }
  }

  static const defaultMaxFileBytes =
      RecoveryEventWindowLimits.defaultMaxSnapshotBytes;

  final Directory _rootDirectory;
  final int _maxFileBytes;
  final int _maxEvents;
  final int _maxEventBytes;

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
    } on _RecoveryPersistenceTemporaryFileCleanupException {
      return _temporaryFileCleanupFailure();
    } on Object {
      return _writeFailureResult();
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
    } on _RecoveryPersistenceTemporaryFileCleanupException {
      return _temporaryFileCleanupFailure();
    } on Object {
      return _writeFailureResult();
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
        return RecoveryPersistenceResult.success();
      });
    } on _RecoveryPersistenceTemporaryFileCleanupException {
      return _temporaryFileCleanupFailure();
    } on Object {
      return RecoveryPersistenceResult(
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
    return loadWindowResult(scope).window;
  }

  @override
  RecoveryPersistenceLoadResult loadWindowResult(
    RecoveryPersistenceScope scope,
  ) {
    if (!scope.hasValidStorageIdentity) {
      final result = _validateScopeIdentity(scope);
      return RecoveryPersistenceLoadResult.failure(
        conflicts: result.conflicts,
        warnings: result.warnings,
      );
    }

    try {
      return _withScopeLock(scope, () {
        final hydrate = _hydrate(scope);
        if (!hydrate.result.isSuccess) {
          return RecoveryPersistenceLoadResult.failure(
            conflicts: hydrate.result.conflicts,
            warnings: hydrate.result.warnings,
          );
        }
        return RecoveryPersistenceLoadResult.success(
          hydrate.store.loadWindow(scope),
          warnings: hydrate.result.warnings,
        );
      }, createRoot: false);
    } on _RecoveryPersistenceLockException {
      final result = _lockFailure();
      return RecoveryPersistenceLoadResult.failure(
        conflicts: result.conflicts,
        warnings: result.warnings,
      );
    } on _RecoveryPersistenceTemporaryFileCleanupException {
      final result = _temporaryFileCleanupFailure();
      return RecoveryPersistenceLoadResult.failure(
        conflicts: result.conflicts,
        warnings: result.warnings,
      );
    } on Object {
      return RecoveryPersistenceLoadResult.failure(
        conflicts: <SyncConflict>[
          SyncConflict(
            code: 'ERR_RECOVERY_PERSISTENCE_LOAD_FAILED',
            message: 'Recovery persistence file could not be loaded.',
            severity: SyncConflictSeverity.fatal,
          ),
        ],
      );
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
      _cleanupTemporaryFiles(scope);
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
    final store = InMemoryRecoveryPersistenceStore(
      maxEvents: _maxEvents,
      maxEventBytes: _maxEventBytes,
    );
    final file = _fileFor(scope);
    if (!file.existsSync()) {
      return _HydratedRecoveryStore(
        store: store,
        result: RecoveryPersistenceResult.success(),
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
    } on _RecoveryPersistenceEventCountException {
      return _eventCountTooLarge(store);
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
      result: RecoveryPersistenceResult.success(),
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
      return RecoveryPersistenceResult.success();
    } on Object {
      try {
        if (tempFile != null && tempFile.existsSync()) {
          tempFile.deleteSync();
        }
      } on Object {
        // Best-effort cleanup; the failed persistence result is authoritative.
      }
      return _writeFailureResult();
    }
  }

  RecoveryPersistenceResult _writeFailureResult() {
    return RecoveryPersistenceResult(
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

  RecoveryPersistenceResult _validateScopeIdentity(
    RecoveryPersistenceScope scope,
  ) {
    if (scope.hasValidStorageIdentity) {
      return RecoveryPersistenceResult.success();
    }
    return RecoveryPersistenceResult(
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
    return RecoveryPersistenceResult(
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

  RecoveryPersistenceResult _temporaryFileCleanupFailure() {
    return RecoveryPersistenceResult(
      isSuccess: false,
      conflicts: <SyncConflict>[
        SyncConflict(
          code: 'ERR_RECOVERY_PERSISTENCE_TEMPORARY_FILE_CLEANUP_FAILED',
          message:
              'Recovery persistence temporary files could not be cleaned up.',
          severity: SyncConflictSeverity.fatal,
        ),
      ],
    );
  }

  void _cleanupTemporaryFiles(RecoveryPersistenceScope scope) {
    try {
      final file = _fileFor(scope);
      for (final candidate in _temporaryFilesFor(file)) {
        candidate.deleteSync();
      }
    } on Object {
      throw const _RecoveryPersistenceTemporaryFileCleanupException();
    }
  }

  _HydratedRecoveryStore _corruptStore(InMemoryRecoveryPersistenceStore store) {
    return _HydratedRecoveryStore(
      store: store,
      result: RecoveryPersistenceResult(
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

  _HydratedRecoveryStore _eventCountTooLarge(
    InMemoryRecoveryPersistenceStore store,
  ) {
    return _HydratedRecoveryStore(
      store: store,
      result: _eventCountTooLargeResult(),
    );
  }

  RecoveryPersistenceResult _fileTooLargeResult() {
    return RecoveryPersistenceResult(
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

  RecoveryPersistenceResult _eventCountTooLargeResult() {
    return RecoveryPersistenceResult(
      isSuccess: false,
      conflicts: <SyncConflict>[
        SyncConflict(
          code: 'ERR_RECOVERY_PERSISTENCE_EVENT_COUNT_TOO_LARGE',
          message:
              'Recovery persistence event window exceeds the configured limit.',
          severity: SyncConflictSeverity.fatal,
          expected: '$_maxEvents',
        ),
      ],
    );
  }

  PersistedRecoveryWindow _decodeWindow(Map<String, Object?> json) {
    final events = json['events'];
    if (events is! List<Object?>) {
      throw const FormatException('Expected recovery events list.');
    }
    if (events.length > _maxEvents) {
      throw const _RecoveryPersistenceEventCountException();
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

class _RecoveryPersistenceEventCountException implements Exception {
  const _RecoveryPersistenceEventCountException();
}

class _RecoveryPersistenceTemporaryFileCleanupException implements Exception {
  const _RecoveryPersistenceTemporaryFileCleanupException();
}
