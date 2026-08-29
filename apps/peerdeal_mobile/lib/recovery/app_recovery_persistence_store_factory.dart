import 'dart:async';
import 'dart:io';

import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';

typedef RecoveryPersistenceRootDirectoryFactory = Directory Function();

const peerDealRecoveryRootEnvironmentVariable = 'PEERDEAL_RECOVERY_ROOT';

const _maximumRecoveryWarningCount = 4;
const _maximumRecoveryWarningLength = 160;

List<String> _safeRecoveryWarnings(Iterable<String> warnings) {
  final truncated = warnings.length > _maximumRecoveryWarningCount;
  final valueLimit = truncated
      ? _maximumRecoveryWarningCount - 1
      : _maximumRecoveryWarningCount;
  final safe = <String>[];
  for (final warning in warnings) {
    if (safe.length == valueLimit) break;
    final trimmed = warning.trim();
    safe.add(
      trimmed.isEmpty ||
              trimmed != warning ||
              warning.length > _maximumRecoveryWarningLength ||
              warning.codeUnits.any(
                (unit) => unit < 0x20 || (unit >= 0x7f && unit <= 0x9f),
              )
          ? 'Recovery persistence warning unavailable.'
          : warning,
    );
  }
  if (truncated) {
    safe.add('Recovery persistence warnings truncated.');
  }
  return List<String>.unmodifiable(safe);
}

class AppRecoveryPersistenceStoreLoadResult {
  AppRecoveryPersistenceStoreLoadResult.available({
    required this.store,
    List<String> warnings = const <String>[],
  }) : warnings = _safeRecoveryWarnings(warnings);

  AppRecoveryPersistenceStoreLoadResult.unavailable({
    required List<String> warnings,
  }) : store = null,
       warnings = _safeRecoveryWarnings(warnings);

  final RecoveryPersistenceStore? store;
  final List<String> warnings;

  bool get isAvailable => store != null;
}

class AppRecoveryPersistenceStoreFactory {
  const AppRecoveryPersistenceStoreFactory({
    required RecoveryPersistenceRootDirectoryFactory rootDirectoryFactory,
  }) : _rootDirectoryFactory = rootDirectoryFactory;

  static AppRecoveryPersistenceStoreFactory? fromEnvironment({
    Map<String, String>? environment,
  }) {
    final rootPath =
        (environment ??
        Platform.environment)[peerDealRecoveryRootEnvironmentVariable];
    if (rootPath == null || rootPath.trim().isEmpty) {
      return null;
    }

    return AppRecoveryPersistenceStoreFactory(
      rootDirectoryFactory: () => Directory(rootPath),
    );
  }

  static Future<AppRecoveryPersistenceStoreFactory?> fromNativeAppSupport({
    AppStorageDirectoryBridge? bridge,
    Future<void>? cancellation,
  }) async {
    if (await _isCancellationRequested(cancellation)) return null;

    final AppStorageDirectorySnapshot snapshot;
    try {
      final directoryBridge =
          bridge ?? MethodChannelAppStorageDirectoryBridge();
      if (directoryBridge is CancellableAppStorageDirectoryBridge) {
        snapshot =
            await (directoryBridge as CancellableAppStorageDirectoryBridge)
                .getAppSupportDirectory(cancellation: cancellation);
      } else {
        snapshot = await directoryBridge.getAppSupportDirectory();
      }
    } on Object {
      return null;
    }

    if (await _isCancellationRequested(cancellation)) return null;

    final appSupportPath = snapshot.directoryPath;
    if (!snapshot.available ||
        appSupportPath == null ||
        !_isValidNativeAppSupportPath(appSupportPath)) {
      return null;
    }

    return AppRecoveryPersistenceStoreFactory(
      rootDirectoryFactory: () => Directory(
        '$appSupportPath${Platform.pathSeparator}PeerDeal${Platform.pathSeparator}recovery',
      ),
    );
  }

  final RecoveryPersistenceRootDirectoryFactory _rootDirectoryFactory;

  AppRecoveryPersistenceStoreLoadResult create() {
    final Directory rootDirectory;
    try {
      rootDirectory = _rootDirectoryFactory();
    } on Object {
      return AppRecoveryPersistenceStoreLoadResult.unavailable(
        warnings: <String>['Recovery persistence root is unavailable.'],
      );
    }

    if (!_isValidRootPath(rootDirectory.path)) {
      return AppRecoveryPersistenceStoreLoadResult.unavailable(
        warnings: <String>['Recovery persistence root is invalid.'],
      );
    }

    return AppRecoveryPersistenceStoreLoadResult.available(
      store: JsonFileRecoveryPersistenceStore(rootDirectory: rootDirectory),
    );
  }

  static bool _isValidRootPath(String path) {
    final normalized = path.trim();
    return normalized.isNotEmpty &&
        normalized == path &&
        !RegExp(r'[\x00-\x1F\x7F-\x9F]').hasMatch(normalized);
  }

  static bool _isValidNativeAppSupportPath(String path) {
    return _isValidRootPath(path) &&
        NativeBridgePayloadLimits.isWithinUtf8Limit(
          path,
          NativeBridgePayloadLimits.maxAppStoragePathBytes,
        );
  }
}

Future<bool> _isCancellationRequested(Future<void>? cancellation) async {
  if (cancellation == null) return false;
  var requested = false;
  cancellation.then<void>(
    (_) => requested = true,
    onError: (Object _, StackTrace _) => requested = true,
  );
  await Future<void>.value();
  return requested;
}
