import 'app_storage_directory_bridge_models.dart';

abstract interface class AppStorageDirectoryBridge {
  Future<AppStorageDirectorySnapshot> getAppSupportDirectory();
}

/// Optional cancellation capability for callers that own startup or route
/// lifecycle.
///
/// The base bridge remains unchanged for existing integrations; callers can
/// detect this capability before passing cancellation through.
abstract interface class CancellableAppStorageDirectoryBridge {
  Future<AppStorageDirectorySnapshot> getAppSupportDirectory({
    Future<void>? cancellation,
  });
}
