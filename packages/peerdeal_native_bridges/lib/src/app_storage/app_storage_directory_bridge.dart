import 'app_storage_directory_bridge_models.dart';

abstract interface class AppStorageDirectoryBridge {
  Future<AppStorageDirectorySnapshot> getAppSupportDirectory();
}
