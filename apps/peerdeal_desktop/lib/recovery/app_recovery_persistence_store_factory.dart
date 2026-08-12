import 'dart:io';

import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_sync/peerdeal_sync.dart';

typedef RecoveryPersistenceRootDirectoryFactory = Directory Function();

const peerDealRecoveryRootEnvironmentVariable = 'PEERDEAL_RECOVERY_ROOT';

class AppRecoveryPersistenceStoreLoadResult {
  AppRecoveryPersistenceStoreLoadResult.available({
    required this.store,
    List<String> warnings = const <String>[],
  }) : warnings = List<String>.unmodifiable(warnings);

  AppRecoveryPersistenceStoreLoadResult.unavailable({
    required List<String> warnings,
  }) : store = null,
       warnings = List<String>.unmodifiable(warnings);

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

    final appSupportPath = snapshot.directoryPath;
    if (!snapshot.available ||
        appSupportPath == null ||
        !_isValidRootPath(appSupportPath)) {
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
        !RegExp(r'[\x00-\x1F\x7F]').hasMatch(normalized);
  }
}
