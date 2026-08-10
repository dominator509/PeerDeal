import 'app_storage_directory_bridge_models.dart';

class AppStorageDirectoryChannelContract {
  const AppStorageDirectoryChannelContract._();

  static const channelName = 'peerdeal/native_bridges/app_storage';
  static const getAppSupportDirectoryMethod = 'getAppSupportDirectory';

  static AppStorageDirectorySnapshot decodeAppSupportDirectory(
    Map<String, Object?>? payload,
  ) {
    if (payload == null) {
      return const AppStorageDirectorySnapshot.unavailable(
        warning: 'Native app storage directory is unavailable.',
      );
    }

    final available = payload['available'];
    final directoryPath = payload['directoryPath'];
    if (available is! bool ||
        !available ||
        directoryPath is! String ||
        !_isValidPath(directoryPath)) {
      return AppStorageDirectorySnapshot.unavailable(
        warning:
            _stringValue(payload['warning']) ??
            'Native app storage directory is unavailable.',
      );
    }

    return AppStorageDirectorySnapshot(
      available: true,
      directoryPath: directoryPath,
      warning: _stringValue(payload['warning']),
    );
  }

  static bool _isValidPath(String value) {
    return value.trim().isNotEmpty &&
        value.trim() == value &&
        !value.codeUnits.any((unit) => unit < 0x20 || unit == 0x7f);
  }

  static String? _stringValue(Object? value) =>
      value is String && value.trim().isNotEmpty ? value : null;
}
