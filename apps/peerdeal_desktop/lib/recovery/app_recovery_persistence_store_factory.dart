import 'dart:io';

import 'package:peerdeal_sync/peerdeal_sync.dart';

typedef RecoveryPersistenceRootDirectoryFactory = Directory Function();

const peerDealRecoveryRootEnvironmentVariable = 'PEERDEAL_RECOVERY_ROOT';

class AppRecoveryPersistenceStoreLoadResult {
  const AppRecoveryPersistenceStoreLoadResult.available({
    required this.store,
    this.warnings = const <String>[],
  });

  const AppRecoveryPersistenceStoreLoadResult.unavailable({
    required this.warnings,
  }) : store = null;

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
                Platform.environment)[peerDealRecoveryRootEnvironmentVariable]
            ?.trim();
    if (rootPath == null || rootPath.isEmpty) {
      return null;
    }

    return AppRecoveryPersistenceStoreFactory(
      rootDirectoryFactory: () => Directory(rootPath),
    );
  }

  final RecoveryPersistenceRootDirectoryFactory _rootDirectoryFactory;

  AppRecoveryPersistenceStoreLoadResult create() {
    final Directory rootDirectory;
    try {
      rootDirectory = _rootDirectoryFactory();
    } on Object {
      return const AppRecoveryPersistenceStoreLoadResult.unavailable(
        warnings: <String>['Recovery persistence root is unavailable.'],
      );
    }

    if (rootDirectory.path.trim().isEmpty) {
      return const AppRecoveryPersistenceStoreLoadResult.unavailable(
        warnings: <String>['Recovery persistence root is invalid.'],
      );
    }

    return AppRecoveryPersistenceStoreLoadResult.available(
      store: JsonFileRecoveryPersistenceStore(rootDirectory: rootDirectory),
    );
  }
}
