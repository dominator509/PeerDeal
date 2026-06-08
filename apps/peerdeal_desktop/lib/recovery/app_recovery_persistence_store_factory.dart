import 'dart:io';

import 'package:peerdeal_sync/peerdeal_sync.dart';

typedef RecoveryPersistenceRootDirectoryFactory = Directory Function();

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
